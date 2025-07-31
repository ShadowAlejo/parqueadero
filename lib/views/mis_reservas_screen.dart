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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<List<Reservacion>> _reservacionesStream;
  Map<String, dynamic> _informacionAdicional = {};

  @override
  void initState() {
    super.initState();
    _reservacionesStream = _reservacionController.getReservacionesStream();
  }

  Future<void> _obtenerInformacionAdicional(String reservacionId) async {
    try {
      final informacion = await _reservacionController
          .obtenerEspacioYPeriodoDeReservacion(reservacionId);
      setState(() {
        _informacionAdicional[reservacionId] = informacion;
      });
    } catch (e) {
      print('Error al obtener la información adicional: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al obtener la información del espacio y periodo'),
      ));
    }
  }

  void _cambiarEstado(String reservaId, String nuevoEstado) async {
    try {
      await _reservacionController.actualizarEstado(reservaId, nuevoEstado);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Estado actualizado a: $nuevoEstado'),
      ));
    } catch (e) {
      print('Error al actualizar el estado: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al actualizar el estado'),
      ));
    }
  }

  Future<void> _cancelarReserva(String reservaId) async {
    try {
      // Llamamos a la función mejorada en el controlador
      await _reservacionController
          .cancelarReservacionYActualizarEspacio(reservaId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserva cancelada correctamente 🎉')),
      );

      // Si estás usando StreamBuilder, bastará con que el stream emita de nuevo.
      // Si no, aquí podrías forzar un setState para recargar la lista:
      // setState(() {});
    } catch (e, stack) {
      // Obtenemos un mensaje legible para el usuario
      final mensaje = e is Exception ? e.toString() : 'Error inesperado';
      // Lo imprimimos completo en consola para investigar
      debugPrint('Error al cancelar reserva: $e\n$stack');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar: $mensaje')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis reservas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Reservacion>>(
          stream: _reservacionesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar las reservaciones.'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No tienes reservas.'));
            }

            // Obtener las reservaciones y ordenarlas por fechaInicio
            final reservaciones = snapshot.data!;
            reservaciones.sort((a, b) => a.fechaInicio
                .compareTo(b.fechaInicio)); // Ordenar por fechaInicio

            return ListView.builder(
              itemCount: reservaciones.length,
              itemBuilder: (context, index) {
                final reserva = reservaciones[index];

                // Verificar si ya hemos obtenido la información adicional para esta reservación
                if (!_informacionAdicional.containsKey(reserva.id)) {
                  _obtenerInformacionAdicional(reserva.id);
                }

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.directions_car),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mostrar datos de la reservación
                        Text(
                          'Fecha de inicio: ${DateFormat('yyyy-MM-dd').format(reserva.fechaInicio.toLocal())}',
                        ),
                        Text(
                          'Fecha de fin: ${DateFormat('yyyy-MM-dd').format(reserva.fechaFin.toLocal())}',
                        ),
                        Text(
                            'Horario: ${reserva.horaInicio} - ${reserva.horaFin}'),
                        Text('Estado: ${reserva.estado}'),

                        // Mostrar la información adicional si está disponible
                        if (_informacionAdicional.containsKey(reserva.id)) ...[
                          Text(
                              'Número de espacio: ${_informacionAdicional[reserva.id]?['espacio'].numero}'),
                          Text(
                              'Sección de espacio: ${_informacionAdicional[reserva.id]?['espacio'].seccion}'),
                          Text(
                              'Nombre del periodo: ${_informacionAdicional[reserva.id]?['periodo'].nombre}'),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (reserva.estado != 'disponible')
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.orange),
                            onPressed: () =>
                                _cambiarEstado(reserva.id, 'pendiente'),
                            tooltip: 'Marcar como pendiente',
                          ),
                        if (reserva.estado != 'confirmado')
                          IconButton(
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () =>
                                _cambiarEstado(reserva.id, 'confirmado'),
                            tooltip: 'Confirmar reserva',
                          ),
                        if (reserva.estado != 'disponible')
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _cancelarReserva(reserva.id),
                            tooltip: 'Cancelar reserva',
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
