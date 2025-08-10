import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/controllers/periodo_controller.dart';
import 'package:parqueadero/controllers/reservacion_controller.dart';
import 'package:parqueadero/models/espacio_model.dart';
import 'package:parqueadero/models/reservacion_model.dart';

class MapaParqueaderoScreen extends StatefulWidget {
  @override
  State<MapaParqueaderoScreen> createState() => _MapaParqueaderoScreenState();
}

class _MapaParqueaderoScreenState extends State<MapaParqueaderoScreen> {
  final EspacioController _espacioController = EspacioController();
  final PeriodoController _periodoController = PeriodoController();
  final ReservacionController _reservController = ReservacionController();

  String? _zonaSeleccionada;
  String? _rangoSeleccionado;
  String? _espacioSeleccionadoId;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  bool _reservando = false;

  @override
  Widget build(BuildContext context) {
    final imagenMapa = _zonaSeleccionada != null
        ? 'assets/images/zona${_zonaSeleccionada!}.png'
        : 'assets/images/mapa.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad & Reservas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildMapa(imagenMapa),
          const SizedBox(height: 24),
          _buildZonaButtons(),
          if (_zonaSeleccionada != null) ...[
            const SizedBox(height: 24),
            _buildRangoDropdown(),
            const SizedBox(height: 16),
            _buildEspaciosList(),
          ],
          _buildReservaButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 6),
        Text(
          'ESPE - Belisario Quevedo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMapa(String imagenMapa) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(imagenMapa, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildZonaButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['A', 'B', 'C', 'D'].map((z) {
          final sel = _zonaSeleccionada == z;
          return ElevatedButton(
            onPressed: () => setState(() {
              _zonaSeleccionada = sel ? null : z;
              _rangoSeleccionado = null;
              _espacioSeleccionadoId = null;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: sel
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: sel ? 8 : 4,
            ),
            child: Text(
              z,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRangoDropdown() {
    return StreamBuilder<int>(
      stream: _espacioController
          .obtenerTotalDeEspaciosPorSeccionEnTiempoReal(_zonaSeleccionada!),
      builder: (ctx, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final total = snap.data!;
        if (total == 0)
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('No hay espacios registrados en ${_zonaSeleccionada!}'),
          );
        final rangos = List.generate(
            (total / 10).ceil(),
            (i) =>
                '${i * 10 + 1}-${(i + 1) * 10 <= total ? (i + 1) * 10 : total}');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DropdownButton<String>(
            isExpanded: true,
            value: _rangoSeleccionado,
            hint: const Text('Filtrar por rango'),
            items: rangos
                .map((r) =>
                    DropdownMenuItem(value: r, child: Text('Espacios $r')))
                .toList(),
            onChanged: (v) => setState(() => _rangoSeleccionado = v),
          ),
        );
      },
    );
  }

  Widget _buildEspaciosList() {
    return Expanded(
      child: StreamBuilder<Map<String, List<Espacio>>>(
        stream: _espacioController
            .obtenerEspaciosDisponiblesPorSeccion(_zonaSeleccionada!),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          var lista = snap.data?[_zonaSeleccionada!] ?? [];
          if (lista.isEmpty)
            return const Center(child: Text('No hay espacios disponibles'));

          lista.sort(
              (a, b) => int.parse(a.numero).compareTo(int.parse(b.numero)));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: lista.length,
            itemBuilder: (_, i) {
              final esp = lista[i];
              final sel = esp.idEspacio == _espacioSeleccionadoId;
              return Card(
                color: sel ? Theme.of(context).colorScheme.secondary : null,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.local_parking),
                  title: Text('Espacio ${esp.numero}'),
                  onTap: () {
                    setState(() {
                      _espacioSeleccionadoId = esp.idEspacio;
                    });
                    _mostrarCuadroDialogo(esp);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReservaButton() {
    final habilitado = _espacioSeleccionadoId != null &&
        _fechaInicio != null &&
        _fechaFin != null &&
        _horaInicio != null &&
        _horaFin != null;
    return habilitado
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.event_available),
                label:
                    Text(_reservando ? 'Reservando...' : 'Crear reservaciones'),
                onPressed: _reservando ? null : _onReservarPressed,
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Future<void> _mostrarCuadroDialogo(Espacio espacio) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Reservar Espacio ${espacio.numero}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateTimePicker('Seleccionar fecha inicio', _fechaInicio,
                  (res) => setState(() => _fechaInicio = res)),
              const SizedBox(height: 12),
              _buildDateTimePicker('Seleccionar fecha fin', _fechaFin,
                  (res) => setState(() => _fechaFin = res)),
              const SizedBox(height: 12),
              _buildTimePicker('Hora inicio', _horaInicio,
                  (res) => setState(() => _horaInicio = res)),
              const SizedBox(height: 12),
              _buildTimePicker('Hora fin', _horaFin,
                  (res) => setState(() => _horaFin = res)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _onReservarPressed();
              },
              child: const Text('Confirmar Reserva'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateTimePicker(
          String label, DateTime? date, ValueChanged<DateTime?> onChanged) =>
      OutlinedButton(
        onPressed: () async {
          final res = await showDatePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDate: date ?? DateTime.now(),
          );
          if (res != null) onChanged(res);
        },
        child: Text(date == null
            ? label
            : 'Seleccionado: ${date.toLocal().toIso8601String().split('T').first}'),
      );

  Widget _buildTimePicker(
          String label, TimeOfDay? time, ValueChanged<TimeOfDay?> onChanged) =>
      OutlinedButton(
        onPressed: () async {
          final res = await showTimePicker(
            context: context,
            initialTime: time ?? TimeOfDay.now(),
          );
          if (res != null) onChanged(res);
        },
        child: Text(
            time == null ? label : 'Seleccionado: ${time.format(context)}'),
      );

  Future<void> _onReservarPressed() async {
    setState(() => _reservando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No hay usuario autenticado';
      if (_fechaInicio!.isAfter(_fechaFin!))
        throw 'La fecha fin debe ser igual o posterior a la fecha inicio';

      // 1) Verificar si hay reservas futuras en este espacio
      final tieneReservasFuturas = await _reservController
          .hayReservasFuturasParaEspacio(_espacioSeleccionadoId!);

      // 2) Si hay reservas posteriores, solo permitir reserva de un día
      if (tieneReservasFuturas) {
        final mismoDia = _fechaInicio!.year == _fechaFin!.year &&
            _fechaInicio!.month == _fechaFin!.month &&
            _fechaInicio!.day == _fechaFin!.day;
        if (!mismoDia) {
          throw 'Este espacio solo admite reservas de un día (hay reservas posteriores).';
        }
      }

      final idPeriodo = await _periodoController.obtenerIdPeriodoActivo();
      if (idPeriodo == null) throw 'No hay periodo activo';

      final usuarioRef = FirebaseFirestore.instance.doc('usuarios/${user.uid}');
      final espacioRef =
          FirebaseFirestore.instance.doc('espacios/$_espacioSeleccionadoId');
      final periodoRef = FirebaseFirestore.instance.doc('periodo/$idPeriodo');

      final base = Reservacion(
        id: '',
        usuarioRef: usuarioRef,
        espacioRef: espacioRef,
        periodoRef: periodoRef,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        horaInicio: '${_horaInicio!.hour}:${_horaInicio!.minute}',
        horaFin: '${_horaFin!.hour}:${_horaFin!.minute}',
        estado: 'pendiente',
      );

      await _reservController.crearReservacionesPorRango(base);
      await _espacioController.ocuparEspacio(_espacioSeleccionadoId!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservaciones creadas exitosamente')),
      );

      setState(() {
        _zonaSeleccionada = null;
        _espacioSeleccionadoId = null;
        _fechaInicio = _fechaFin = null;
        _horaInicio = _horaFin = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _reservando = false);
    }
  }
}
