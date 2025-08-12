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

  // Carrusel
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Mapeo zona → imágenes
  List<String> _imagenesZona(String? z) {
    if (z == null) return ['assets/images/mapa.png'];
    switch (z) {
      case 'A':
        return ['assets/images/zonaA.png'];
      case 'B':
        return ['assets/images/zonaB.png'];
      case 'C':
        return ['assets/images/zonaC1.png', 'assets/images/zonaC2.png'];
      case 'D':
        return [
          'assets/images/zonaD1.png',
          'assets/images/zonaD2.png',
          'assets/images/zonaD3.png',
          'assets/images/zonaD4.png',
        ];
      default:
        return ['assets/images/mapa.png'];
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Mapa con zoom + carrusel + flechas
          _buildMapa(),

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

  // ====== Mapa/carrusel (solo visual) ======
  Widget _buildMapa() {
    final imagenes = _imagenesZona(_zonaSeleccionada);
    final multiple = imagenes.length > 1;

    // Más grande
    final double alto = MediaQuery.of(context).size.height * 0.20;

    void irAnterior() {
      if (!multiple) return;
      if (_paginaActual > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    void irSiguiente() {
      if (!multiple) return;
      if (_paginaActual < imagenes.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.black12,
          height: alto.clamp(300.0, 560.0).toDouble(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Imagen única o carrusel (zoom sin desplazamiento)
              multiple
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: imagenes.length,
                      onPageChanged: (i) => setState(() => _paginaActual = i),
                      itemBuilder: (ctx, i) =>
                          _ZoomOnlyImage(path: imagenes[i]),
                    )
                  : _ZoomOnlyImage(path: imagenes.first),

              // Flecha izquierda
              if (multiple)
                Positioned(
                  left: 8,
                  child: _ArrowButton(
                    icon: Icons.chevron_left,
                    enabled: _paginaActual > 0,
                    onTap: irAnterior,
                  ),
                ),

              // Flecha derecha
              if (multiple)
                Positioned(
                  right: 8,
                  child: _ArrowButton(
                    icon: Icons.chevron_right,
                    enabled: _paginaActual < imagenes.length - 1,
                    onTap: irSiguiente,
                  ),
                ),

              // Indicadores
              if (multiple)
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: List.generate(
                        imagenes.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _paginaActual == i ? 14 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _paginaActual == i
                                ? Colors.white
                                : Colors.white70,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Etiqueta de zona
              if (_zonaSeleccionada != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Zona ${_zonaSeleccionada!}'
                      '${multiple ? ' (${_paginaActual + 1}/${imagenes.length})' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
              if (sel) {
                _zonaSeleccionada = null;
              } else {
                _zonaSeleccionada = z;
              }
              _espacioSeleccionadoId = null;

              // Reset carrusel
              _paginaActual = 0;
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
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
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ====== Lógica existente (sin cambios) ======

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
          child: Text(
            'De espacio 1-$total',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

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
      if (_fechaInicio!.isAfter(_fechaFin!)) {
        throw 'La fecha fin debe ser igual o posterior a la fecha inicio';
      }

      final tieneReservasFuturas = await _reservController
          .hayReservasFuturasParaEspacio(_espacioSeleccionadoId!);

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

      await FirebaseAuth.instance.currentUser?.getIdToken(true);
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

        _paginaActual = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _reservando = false);
    }
  }
}

// ========= Widgets visuales =========

// Zoom SIN desplazamiento y con doble-tap 1x ↔ 2x (un solo AnimationController)
class _ZoomOnlyImage extends StatefulWidget {
  final String path;
  const _ZoomOnlyImage({super.key, required this.path});

  @override
  State<_ZoomOnlyImage> createState() => _ZoomOnlyImageState();
}

class _ZoomOnlyImageState extends State<_ZoomOnlyImage>
    with SingleTickerProviderStateMixin {
  late final TransformationController _tc;
  late final AnimationController _animCtrl;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _tc = TransformationController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final anim = _animation;
        if (anim != null) _tc.value = anim.value;
      });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(begin: _tc.value, end: target).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl
      ..stop()
      ..reset()
      ..forward();
  }

  void _toggleDoubleTapZoom() {
    final target = _tc.value.isIdentity()
        ? (Matrix4.identity()..scale(2.0))
        : Matrix4.identity();
    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _toggleDoubleTapZoom,
      child: InteractiveViewer(
        transformationController: _tc,
        panEnabled: false, // sin desplazamiento
        scaleEnabled: true,
        minScale: 1.0,
        maxScale: 4.0,
        boundaryMargin: EdgeInsets.zero, // no se sale del marco
        clipBehavior: Clip.hardEdge, // recorta al borde redondeado
        child: Image.asset(
          widget.path,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

// Botón circular semitransparente para flechas
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _ArrowButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = Colors.black.withOpacity(0.35);
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
