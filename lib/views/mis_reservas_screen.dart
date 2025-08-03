import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/reservacion_controller.dart';
import 'package:parqueadero/models/reservacion_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MisReservasScreen extends StatefulWidget {
  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final ReservacionController _reservacionController = ReservacionController();
  late Future<List<Reservacion>> _reservacionesFuture;
  Map<String, dynamic> _informacionAdicional = {};

  @override
  void initState() {
    super.initState();
    _reservacionesFuture =
        _reservacionController.obtenerReservacionesUsuarioPeriodoActivo();
  }

  Future<void> _obtenerInformacionAdicional(String reservacionId) async {
    try {
      final info = await _reservacionController
          .obtenerEspacioYPeriodoDeReservacion(reservacionId);
      setState(() {
        _informacionAdicional[reservacionId] = info;
      });
    } catch (e) {
      debugPrint('Error al obtener info adicional: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de espacio/periodo')),
      );
    }
  }

  void _cambiarEstado(String reservaId, String nuevoEstado) async {
    try {
      await _reservacionController.actualizarEstado(reservaId, nuevoEstado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ha confirmado su reservación')),
      );
      setState(() {
        _reservacionesFuture =
            _reservacionController.obtenerReservacionesUsuarioPeriodoActivo();
      });
    } catch (e) {
      debugPrint('Error al cambiar estado: \$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado')),
      );
    }
  }

  Future<void> _cancelarReserva(String reservaId) async {
    try {
      await _reservacionController
          .cancelarReservacionYActualizarEspacio(reservaId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserva cancelada correctamente')),
      );
      setState(() {
        _reservacionesFuture =
            _reservacionController.obtenerReservacionesUsuarioPeriodoActivo();
      });
    } catch (e, st) {
      debugPrint('Error al cancelar reserva: \$e\n\$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar reserva')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis reservas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Reservacion>>(
          future: _reservacionesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar las reservaciones.'));
            }
            final reservaciones = snapshot.data ?? [];
            if (reservaciones.isEmpty) {
              return Center(
                  child: Text('No tienes reservas en el periodo activo.'));
            }

            reservaciones
                .sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

            final pendientes =
                reservaciones.where((r) => r.estado == 'pendiente').toList();
            final confirmadas =
                reservaciones.where((r) => r.estado == 'confirmado').toList();
            final canceladas =
                reservaciones.where((r) => r.estado == 'cancelado').toList();
            final finalizadas =
                reservaciones.where((r) => r.estado == 'finalizado').toList();

            return ListView(
              children: [
                if (pendientes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Pendientes', style: headerStyle),
                  ),
                  for (var reserva in pendientes) _buildReservaCard(reserva),
                ],
                if (confirmadas.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Confirmadas', style: headerStyle),
                  ),
                  for (var reserva in confirmadas) _buildReservaCard(reserva),
                ],
                if (canceladas.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Canceladas', style: headerStyle),
                  ),
                  for (var reserva in canceladas) _buildReservaCard(reserva),
                ],
                if (finalizadas.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Finalizadas', style: headerStyle),
                  ),
                  for (var reserva in finalizadas) _buildReservaCard(reserva),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReservaCard(Reservacion reserva) {
    if (!_informacionAdicional.containsKey(reserva.id)) {
      _obtenerInformacionAdicional(reserva.id);
    }

    final acciones = <Widget>[];
    if (reserva.estado == 'pendiente') {
      acciones.addAll([
        IconButton(
          icon: Icon(Icons.check_circle, color: Colors.green),
          onPressed: () => _cambiarEstado(reserva.id, 'confirmado'),
          tooltip: 'Confirmar reserva',
        ),
        IconButton(
          icon: Icon(Icons.cancel, color: Colors.red),
          onPressed: () => _cancelarReserva(reserva.id),
          tooltip: 'Cancelar reserva',
        ),
      ]);
    } else if (reserva.estado == 'confirmado') {
      acciones.add(
        IconButton(
          icon: Icon(Icons.cancel, color: Colors.red),
          onPressed: () => _cancelarReserva(reserva.id),
          tooltip: 'Cancelar reserva',
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.directions_car),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Inicio: ${DateFormat('yyyy-MM-dd').format(reserva.fechaInicio.toLocal())}'),
            Text(
                'Fin: ${DateFormat('yyyy-MM-dd').format(reserva.fechaFin.toLocal())}'),
            Text('Horario: ${reserva.horaInicio} - ${reserva.horaFin}'),
            Text('Estado: ${reserva.estado}'),
            if (_informacionAdicional.containsKey(reserva.id)) ...[
              SizedBox(height: 4),
              Text(
                  'Espacio: ${_informacionAdicional[reserva.id]['espacio'].numero} (${_informacionAdicional[reserva.id]['espacio'].seccion})'),
              Text(
                  'Periodo: ${_informacionAdicional[reserva.id]['periodo'].nombre}'),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: acciones,
        ),
      ),
    );
  }
}
