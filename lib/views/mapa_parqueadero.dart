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
    _animController.dispose();
    super.dispose();
  }

  void _onZoomChanged(double newZoom) {
    setState(() {
      zoomLevel = newZoom;
    });
  }

  void _resetZoom() {
    _zoomKey.currentState?.resetZoom();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ayuda'),
        content: Text(
            'Puedes hacer zoom en el mapa usando dos dedos o pellizcando la imagen.\n\nSelecciona una zona (A, B, C, D) para ver información o filtrar el mapa.\n\nUsa el botón de reset para volver al zoom original.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Entendido'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final squareSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de parqueadero'),
        backgroundColor: Color(0xFF0A6E39),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: 'Ayuda',
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8),
              Text(
                'ESPE - Belisario Quevedo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A6E39),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: squareSize - 32,
                        height: squareSize - 32,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          border:
                              Border.all(color: Color(0xFF0A6E39), width: 2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _ZoomOnlyImageViewer(
                            key: _zoomKey,
                            squareSize: squareSize - 32,
                            onZoomChanged: _onZoomChanged,
                          ),
                        ),
                      ),
                      // Indicador de zoom en la esquina superior izquierda
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF0A6E39)),
                          ),
                          child: Text(
                            'Zoom: x${zoomLevel.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      // Botón de reset en la esquina inferior derecha, solo si el zoom es mayor a 1.0
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
                                    border:
                                        Border.all(color: Color(0xFF0A6E39)),
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.refresh,
                                      color: Color(0xFF0A6E39)),
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
              Text(
                'Seleccione una zona:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
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
              // Sección de datos de reserva inventados
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 32.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF0A6E39), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserva actual',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0A6E39),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.directions_car, color: Color(0xFF0A6E39)),
                          SizedBox(width: 8),
                          Text('Espacio: B-12', style: TextStyle(fontSize: 15)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Color(0xFF0A6E39)),
                          SizedBox(width: 8),
                          Text('Hora de entrada: 08:30',
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.date_range, color: Color(0xFF0A6E39)),
                          SizedBox(width: 8),
                          Text('Fecha: 2024-06-10',
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Estado: Confirmada',
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
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
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Color(0xFFF4B400) : Color(0xFF0A6E39),
        foregroundColor: isSelected ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Color(0xFFF4B400), width: 2)
              : BorderSide.none,
        ),
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        elevation: isSelected ? 8 : 4,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
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
      if (widget.onZoomChanged != null) {
        widget.onZoomChanged!(scale);
      }
      setState(() {}); // Para actualizar panEnabled
    }
  }

  void resetZoom() {
    setState(() {
      _controller.value = Matrix4.identity();
      _lastScale = 1.0;
      if (widget.onZoomChanged != null) {
        widget.onZoomChanged!(1.0);
      }
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
      panEnabled: _lastScale > 1.01, // Solo permitir pan si hay zoom
      scaleEnabled: true,
      constrained: true,
      transformationController: _controller,
      child: SizedBox(
        width: widget.squareSize,
        height: widget.squareSize,
        child: Image.asset(
          'assets/images/mapa.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
