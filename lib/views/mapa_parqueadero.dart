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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Color(0xFF0A6E39)),
                  SizedBox(width: 6),
                  Text(
                    'ESPE - Belisario Quevedo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A6E39),
                    ),
                  ),
                ],
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
        // Navegar a la pantalla de detalle de zona
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ZonaDetalleScreen(zona: label),
          ),
        );
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

class ZonaDetalleScreen extends StatefulWidget {
  final String zona;
  const ZonaDetalleScreen({Key? key, required this.zona}) : super(key: key);

  @override
  State<ZonaDetalleScreen> createState() => _ZonaDetalleScreenState();
}

class _ZonaDetalleScreenState extends State<ZonaDetalleScreen> {
  String? zonaSeleccionada;
  String? horarioSeleccionado;
  DateTime? fechaSeleccionada;
  String? espacioSeleccionado;
  final Map<String, String> zonaImagen = {
    'A': 'assets/images/zonaA.png',
    'B': 'assets/images/zonaB.png',
    'C': 'assets/images/zonaC.png',
    'D': 'assets/images/zonaD.png',
  };
  final Map<String, List<String>> espaciosDisponibles = {
    'A': ['A-1', 'A-2', 'A-3', 'A-4'],
    'B': ['B-10', 'B-12', 'B-15'],
    'C': ['C-5', 'C-6'],
    'D': ['D-7', 'D-8', 'D-9'],
  };
  final List<String> horarios = [
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
  ];
  final Color colorSecundario = Color(0xFFA5D6A7); // Verde pastel opaco

  @override
  void initState() {
    super.initState();
    zonaSeleccionada = widget.zona;
  }

  void _cambiarZona(String nuevaZona) {
    setState(() {
      zonaSeleccionada = nuevaZona;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagen = zonaImagen[zonaSeleccionada!] ?? 'assets/images/mapa.png';
    // Espacios disponibles según la fecha seleccionada (demo: alternar según día par/impar)
    List<String> espacios = [];
    if (fechaSeleccionada != null) {
      final base = espaciosDisponibles[zonaSeleccionada!] ?? [];
      if (fechaSeleccionada!.day % 2 == 0) {
        espacios = base.where((e) => base.indexOf(e) % 2 == 0).toList();
      } else {
        espacios = base.where((e) => base.indexOf(e) % 2 == 1).toList();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Zona ${zonaSeleccionada!}'),
        backgroundColor: Color(0xFF0A6E39),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF0A6E39), width: 2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    imagen,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
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
            Row(
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
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selección de fecha primero
                  Text(
                    'Seleccione una fecha:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0A6E39),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() {
                              fechaSeleccionada = picked;
                              espacioSeleccionado =
                                  null; // Limpiar selección de espacio
                            });
                          }
                        },
                        icon: Icon(Icons.date_range),
                        label: Text('Seleccionar fecha'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorSecundario,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        fechaSeleccionada != null
                            ? '${fechaSeleccionada!.day.toString().padLeft(2, '0')}/${fechaSeleccionada!.month.toString().padLeft(2, '0')}/${fechaSeleccionada!.year}'
                            : 'Ninguna',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // Espacios disponibles solo si hay fecha
                  if (fechaSeleccionada != null) ...[
                    Text(
                      'Espacios disponibles:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0A6E39),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (espacios.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        children: espacios
                            .map((e) => ChoiceChip(
                                  label: Text(e),
                                  selected: espacioSeleccionado == e,
                                  selectedColor: colorSecundario,
                                  backgroundColor: Colors.green[100],
                                  labelStyle: TextStyle(
                                    color: espacioSeleccionado == e
                                        ? Colors.black
                                        : Colors.black87,
                                    fontWeight: espacioSeleccionado == e
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      espacioSeleccionado = e;
                                    });
                                  },
                                ))
                            .toList(),
                      )
                    else
                      Text('No hay espacios disponibles para esta fecha.'),
                    SizedBox(height: 24),
                  ],
                  if (espacioSeleccionado != null) ...[
                    Text(
                      'Seleccione un horario:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0A6E39),
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: horarioSeleccionado,
                      hint: Text('Seleccione un horario'),
                      isExpanded: true,
                      items: horarios
                          .map((h) => DropdownMenuItem(
                                value: h,
                                child: Text(h),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          horarioSeleccionado = value;
                        });
                      },
                    ),
                    SizedBox(height: 32),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back),
                        label: Text('Regresar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0A6E39),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: (horarioSeleccionado != null &&
                                fechaSeleccionada != null &&
                                espacioSeleccionado != null)
                            ? () {
                                // Acción de reservar espacio
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Espacio $espacioSeleccionado reservado en zona ${zonaSeleccionada!} para $horarioSeleccionado el ${fechaSeleccionada!.day.toString().padLeft(2, '0')}/${fechaSeleccionada!.month.toString().padLeft(2, '0')}/${fechaSeleccionada!.year}'),
                                  ),
                                );
                              }
                            : null,
                        icon: Icon(Icons.event_available),
                        label: Text('Reservar espacio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorSecundario,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zonaButton(String label) {
    final isSelected = zonaSeleccionada == label;
    return ElevatedButton(
      onPressed: () {
        _cambiarZona(label);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? colorSecundario : Color(0xFF0A6E39),
        foregroundColor: isSelected ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: colorSecundario, width: 2)
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
