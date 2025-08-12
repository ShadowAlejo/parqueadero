import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/controllers/periodo_controller.dart';
import 'package:parqueadero/controllers/reservacion_controller.dart';
import 'package:parqueadero/models/espacio_model.dart';
import 'package:parqueadero/models/reservacion_model.dart';
import 'buscador_espacio_new.dart';
import 'reserva_espacio_new.dart';

class MapaParqueaderoScreen extends StatefulWidget {
  @override
  State<MapaParqueaderoScreen> createState() => _MapaParqueaderoScreenState();
}

class _MapaParqueaderoScreenState extends State<MapaParqueaderoScreen> {
  final EspacioController _espacioController = EspacioController();
  final PeriodoController _periodoController = PeriodoController();
  final ReservacionController _reservController = ReservacionController();

  String? _zonaSeleccionada;
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
            _buildRangoLabel(),
            const SizedBox(height: 16),
            _buildBuscadorEspacio(),
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

  // NUEVO: Etiqueta con el rango dinámico de espacios
  Widget _buildRangoLabel() {
    return StreamBuilder<int>(
      stream: _espacioController
          .obtenerTotalDeEspaciosPorSeccionEnTiempoReal(_zonaSeleccionada!),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final total = snap.data!;
        if (total == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('De espacio 1-$total',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }

  // NUEVO: Buscador de espacio por número
  Widget _buildBuscadorEspacio() {
    return BuscadorEspacioWidget(
      zona: _zonaSeleccionada!,
      espacioController: _espacioController,
      onEspacioReservar: (espacio) async {
        await showDialog(
          context: context,
          builder: (ctx) => ReservaEspacioDialog(
            espacio: espacio,
            onConfirmar: (fechaInicio, fechaFin, horaInicio, horaFin) async {
              setState(() {
                _fechaInicio = fechaInicio;
                _fechaFin = fechaFin;
                _horaInicio = horaInicio;
                _horaFin = horaFin;
                _espacioSeleccionadoId = espacio.idEspacio;
              });
              await _onReservarPressed();
            },
          ),
        );
      },
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

      // Aseguramos que el token esté actualizado antes de ejecutar la creación de reservaciones
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      // Llamamos a la función que maneja la creación de reservaciones
      await _reservController.crearReservacionesPorRango(base);

      // Actualizamos el espacio a ocupado
      await _espacioController.ocuparEspacio(_espacioSeleccionadoId!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservaciones creadas exitosamente')),
      );

      // Limpiamos los valores de la UI
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
