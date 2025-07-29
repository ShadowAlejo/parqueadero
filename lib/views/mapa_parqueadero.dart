// lib/views/mapa_parqueadero.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class MapaParqueaderoScreen extends StatefulWidget {
  @override
  State<MapaParqueaderoScreen> createState() => _MapaParqueaderoScreenState();
}

class _MapaParqueaderoScreenState extends State<MapaParqueaderoScreen>
    with SingleTickerProviderStateMixin {
  String? zonaSeleccionada;
  double zoomLevel = 1.0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<_ZoomOnlyImageViewerState> _zoomKey = GlobalKey();

  // Controladores y estado para el filtro
  final TextEditingController _numCtrl = TextEditingController();
  DateTimeRange? _dateRange;
  bool? _isAvailable;

  // Imágenes para cada zona
  final List<String> imagesZonaA = ['assets/images/zonaA.png'];
  final List<String> imagesZonaB = ['assets/images/zonaB.png'];
  final List<String> imagesZonaC = [
    'assets/images/zonaC1.png',
    'assets/images/zonaC2.png'
  ];
  final List<String> imagesZonaD = [
    'assets/images/zonaD1.png',
    'assets/images/zonaD2.png',
    'assets/images/zonaD3.png',
    'assets/images/zonaD4.png',
  ];

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Abre el selector de rango de fechas
  Future<void> _pickDateRange() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _checkAvailability();
    }
  }

  // Comprueba disponibilidad (simulación; conecta aquí tu lógica real)
  void _checkAvailability() {
    final num = int.tryParse(_numCtrl.text);
    if (zonaSeleccionada == null || num == null || _dateRange == null) {
      setState(() => _isAvailable = null);
      return;
    }
    // TODO: sustituir por EspaciosController.isDisponible(zonaSeleccionada, num, _dateRange.start, _dateRange.end)
    setState(() => _isAvailable = num % 3 != 0);
  }

  void _onZoomChanged(double newZoom) => setState(() => zoomLevel = newZoom);
  void _resetZoom() => _zoomKey.currentState?.resetZoom();

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ayuda'),
        content: Text(
            'Puedes hacer zoom en el mapa usando dos dedos o pellizcando la imagen.\n\n'
            'Selecciona una zona (A, B, C, D) para ver el filtro de espacios.\n\n'
            'Usa el botón de reset para volver al zoom original.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final squareSize = screenW < screenH ? screenW : screenH;

    return Scaffold(
      appBar: AppBar(
        title: Text('Disponibilidad'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
              icon: Icon(Icons.help_outline), onPressed: _showHelpDialog),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on,
                      color: Theme.of(context).colorScheme.onSurface),
                  SizedBox(width: 6),
                  Text(
                    'ESPE - Belisario Quevedo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // ------------------------------------------------
              // Mapa con carrusel de imágenes
              // ------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset('assets/images/mapa.png',
                              fit: BoxFit.cover),
                        ),
                      ),
                      Container(
                        width: squareSize - 32,
                        height: squareSize - 32,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 16,
                                offset: Offset(0, 8))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildCarrousel(zonaSeleccionada),
                        ),
                      ),
                      // Zoom indicator
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: zonaSeleccionada == null
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[900]!.withOpacity(0.85)
                                    : Colors.grey[800]!.withOpacity(0.85))
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[300]!.withOpacity(0.85)
                                    : Colors.grey[900]!.withOpacity(0.85)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          child: Text(
                            'Zoom: x${zoomLevel.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      if (zoomLevel > 1.01)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Tooltip(
                            message: 'Restablecer zoom',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _resetZoom,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.refresh,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // ------------------------------------------------
              // Botones de selección de zona
              // ------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _zonaButton('A'),
                    SizedBox(width: 16),
                    _zonaButton('B'),
                    SizedBox(width: 16),
                    _zonaButton('C'),
                    SizedBox(width: 16),
                    _zonaButton('D'),
                  ],
                ),
              ),

              // ------------------------------------------------
              // FILTRO DE NÚMERO Y FECHA
              // ------------------------------------------------
              if (zonaSeleccionada != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24),
                      Text(
                        'Número de espacio (solo dígitos):',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _numCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '$zonaSeleccionada',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _checkAvailability(),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickDateRange,
                        icon: Icon(Icons.date_range),
                        label: Text(_dateRange == null
                            ? 'Seleccionar rango de fechas'
                            : '${_dateRange!.start.day}/${_dateRange!.start.month}'
                                ' → ${_dateRange!.end.day}/${_dateRange!.end.month}'),
                      ),
                      SizedBox(height: 24),
                      if (_isAvailable != null)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: _isAvailable!
                                  ? () {
                                      // TODO: aquí lanzarías tu reserva real
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isAvailable! ? Colors.green : Colors.red,
                              ),
                              child: Text(
                                '$zonaSeleccionada${_numCtrl.text}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _isAvailable! ? 'Disponible 👍' : 'Ocupado 🚫',
                              style: TextStyle(
                                color:
                                    _isAvailable! ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],

              // ------------------------------------------------
              // (Opcional) Sección de "Reserva actual" u otros datos
              // ------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 32.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reserva actual',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.directions_car,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.lightBlueAccent[100]
                                  : Theme.of(context).colorScheme.primary),
                          SizedBox(width: 8),
                          Text('Espacio: B-12',
                              style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                      // ... resto de filas de "Reserva actual" ...
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zonaButton(String label) {
    final isSelected = zonaSeleccionada == label;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          zonaSeleccionada = label;
          _numCtrl.clear();
          _dateRange = null;
          _isAvailable = null;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[800])
            : Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[900]!),
                  width: 2)
              : BorderSide.none,
        ),
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        elevation: isSelected ? 16 : 4,
        shadowColor: isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!.withOpacity(0.7)
                : Colors.grey[900]!.withOpacity(0.7))
            : Colors.black.withOpacity(0.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 20,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCarrousel(String? zona) {
    List<String> images;
    if (zona == 'A') {
      images = imagesZonaA;
    } else if (zona == 'B') {
      images = imagesZonaB;
    } else if (zona == 'C') {
      images = imagesZonaC;
    } else if (zona == 'D') {
      images = imagesZonaD;
    } else {
      images = [];
    }

    return images.isEmpty
        ? SizedBox.shrink()
        : PageView.builder(
            itemCount: images.length,
            itemBuilder: (ctx, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: true,
                child: Image.asset(images[index], fit: BoxFit.cover),
              );
            },
          );
  }
}

class _ZoomOnlyImageViewer extends StatefulWidget {
  final double squareSize;
  final void Function(double)? onZoomChanged;
  const _ZoomOnlyImageViewer(
      {Key? key, required this.squareSize, this.onZoomChanged})
      : super(key: key);

  @override
  State<_ZoomOnlyImageViewer> createState() => _ZoomOnlyImageViewerState();
}

class _ZoomOnlyImageViewerState extends State<_ZoomOnlyImageViewer> {
  late TransformationController _controller;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_onMatrixChanged);
  }

  void _onMatrixChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _lastScale).abs() > 0.01) {
      _lastScale = scale;
      widget.onZoomChanged?.call(scale);
      setState(() {});
    }
  }

  void resetZoom() {
    setState(() {
      _controller.value = Matrix4.identity();
      _lastScale = 1.0;
      widget.onZoomChanged?.call(1.0);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onMatrixChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      panEnabled: _lastScale > 1.01,
      scaleEnabled: true,
      constrained: true,
      transformationController: _controller,
      child: SizedBox(
        width: widget.squareSize,
        height: widget.squareSize,
        child: Image.asset('assets/images/mapa.png', fit: BoxFit.cover),
      ),
    );
  }
}

// (Opcional) Tu ZonaDetalleScreen puede ir aquí debajo, sin cambios.
