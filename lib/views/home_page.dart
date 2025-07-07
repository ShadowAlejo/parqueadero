import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';
import 'dart:math' as math;
import 'mapa_parqueadero.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authC = AuthController();
  Usuario? usuario;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  Future<void> _loadUsuario() async {
    final u = await _authC.getCurrentUsuario();
    setState(() => usuario = u);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio - Parqueadero ESPE'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Cerrar sesión'),
                  content: Text('¿Estás seguro de que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Sí, cerrar sesión'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _authC.logout();
              }
            },
          )
        ],
      ),
      body: usuario == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage:
                                AssetImage('assets/images/usuario.png'),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  usuario!.nombre,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF0A6E39)),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.pending_actions,
                                        color: Colors.orange, size: 20),
                                    SizedBox(width: 4),
                                    Text('Reservas pendientes: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text('2',
                                        style: TextStyle(
                                            color: Colors.orange[800],
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                    SizedBox(width: 4),
                                    Text('Reservas confirmadas: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text('4',
                                        style: TextStyle(
                                            color: Colors.green[800],
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.local_parking,
                                        color: Colors.blue, size: 20),
                                    SizedBox(width: 4),
                                    Text('Código: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text('ESPE-1234',
                                        style: TextStyle(
                                            color: Colors.blue[800],
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Seleccione una opción:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 30),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuButton(Icons.map, 'Ver disponibilidad'),
                      _buildMenuButton(Icons.bookmark, 'Mis reservas'),
                      if (usuario!.rol == 'admin')
                        _buildMenuButton(Icons.analytics, 'Ver reportes'),
                      _buildMenuButton(Icons.settings, 'Configuración'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label) {
    return ElevatedButton(
      onPressed: () {
        if (label == 'Ver disponibilidad') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapaParqueaderoScreen()),
          );
        }
        if (label == 'Mis reservas') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MisReservasScreen()),
          );
        }
        if (label == 'Configuración') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ConfiguracionScreen()),
          );
        }
        // Aquí puedes agregar otras navegaciones para otros botones si lo deseas
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(16),
        backgroundColor: Color(0xFF0A6E39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class MapaScreen extends StatefulWidget {
  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen>
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2), // Más pequeño
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF0A6E39)),
                          ),
                          child: Text(
                            'Zoom: x${zoomLevel.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13), // Letra más pequeña
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

// Pantalla de Mis Reservas
class MisReservasScreen extends StatefulWidget {
  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _ReservaData {
  String zona;
  String espacio;
  DateTime fecha;
  String horario;
  String estado; // 'actual', 'futura', 'pasada'
  _ReservaData(
      {required this.zona,
      required this.espacio,
      required this.fecha,
      required this.horario,
      required this.estado});
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  List<_ReservaData> reservas = [
    _ReservaData(
      zona: 'B',
      espacio: 'B-12',
      fecha: DateTime.now(),
      horario: '08:30 - 10:00',
      estado: 'actual',
    ),
    _ReservaData(
      zona: 'A',
      espacio: 'A-2',
      fecha: DateTime.now().add(Duration(days: 1)),
      horario: '10:00 - 11:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'C',
      espacio: 'C-5',
      fecha: DateTime.now().add(Duration(days: 2)),
      horario: '12:00 - 13:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'D',
      espacio: 'D-8',
      fecha: DateTime.now().add(Duration(days: 3)),
      horario: '09:00 - 10:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'A',
      espacio: 'A-4',
      fecha: DateTime.now().add(Duration(days: 4)),
      horario: '13:00 - 14:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'B',
      espacio: 'B-15',
      fecha: DateTime.now().add(Duration(days: 5)),
      horario: '11:00 - 12:00',
      estado: 'futura',
    ),
  ];

  final List<String> horarios = [
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
  ];

  void _cancelarReserva(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar reserva'),
        content: Text('¿Estás seguro de que deseas cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        reservas.removeAt(index);
      });
    }
  }

  void _cambiarFecha(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: reservas[index].fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        reservas[index].fecha = picked;
      });
    }
  }

  void _cambiarHorario(int index) async {
    String? nuevoHorario = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selected = reservas[index].horario;
        return AlertDialog(
          title: Text('Seleccionar horario'),
          content: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: horarios
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (value) {
              selected = value;
              Navigator.of(context).pop(value);
            },
          ),
        );
      },
    );
    if (nuevoHorario != null) {
      setState(() {
        reservas[index].horario = nuevoHorario;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasFuturas =
        reservas.where((r) => r.estado == 'futura').toList();
    final reservaActual = reservas.firstWhere(
      (r) => r.estado == 'actual',
      orElse: () => _ReservaData(
          zona: '',
          espacio: '',
          fecha: DateTime.now(),
          horario: '',
          estado: 'ninguna'),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis reservas'),
        backgroundColor: Color(0xFF0A6E39),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  if (reservaActual.estado == 'actual') ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reserva actual',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF0A6E39))),
                          Card(
                            color: Colors.green[50],
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Icon(Icons.directions_car,
                                  color: Color(0xFF0A6E39)),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Zona: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: reservaActual.zona),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Espacio: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: reservaActual.espacio),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Fecha: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(
                                        text:
                                            '${reservaActual.fecha.day.toString().padLeft(2, '0')}/${reservaActual.fecha.month.toString().padLeft(2, '0')}/${reservaActual.fecha.year}'),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Horario: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: reservaActual.horario),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Estado: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(
                                        text: 'Confirmada',
                                        style: TextStyle(color: Colors.green)),
                                  ])),
                                ],
                              ),
                              trailing: Icon(Icons.lock, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Próximas reservas',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0A6E39))),
                  ),
                  if (reservasFuturas.isEmpty)
                    Center(child: Text('No tienes reservas futuras.'))
                  else
                    ...reservasFuturas.map((r) {
                      final idx = reservas.indexOf(r);
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.directions_car,
                              color: Color(0xFF0A6E39)),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Zona: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: r.zona),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Espacio: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: r.espacio),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Fecha: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text:
                                        '${r.fecha.day.toString().padLeft(2, '0')}/${r.fecha.month.toString().padLeft(2, '0')}/${r.fecha.year}'),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Horario: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: r.horario),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Estado: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: 'Confirmada',
                                    style: TextStyle(color: Colors.green)),
                              ])),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_calendar,
                                    color: Colors.orange),
                                tooltip: 'Cambiar fecha',
                                onPressed: () => _cambiarFecha(idx),
                              ),
                              IconButton(
                                icon: Icon(Icons.schedule, color: Colors.blue),
                                tooltip: 'Cambiar horario',
                                onPressed: () => _cambiarHorario(idx),
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Cancelar reserva',
                                onPressed: () => _cancelarReserva(idx),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de Configuración
class ConfiguracionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        backgroundColor: Color(0xFF0A6E39),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto de perfil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: AssetImage('assets/images/usuario.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, color: Color(0xFF0A6E39)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text('Cambiar contraseña',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Aquí iría la lógica para cambiar contraseña
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Cambiar contraseña'),
                    content: Text('Funcionalidad próximamente disponible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.lock_reset),
              label: Text('Cambiar contraseña'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A6E39),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Acerca de la aplicación'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Parqueadero ESPE', textAlign: TextAlign.center),
                          SizedBox(height: 8),
                          Text('Versión: 1.0.0', textAlign: TextAlign.center),
                          SizedBox(height: 8),
                          Text('Desarrollado por Equipo Moviles 2025',
                              textAlign: TextAlign.center),
                          SizedBox(height: 8),
                          Text('© Xriva 21',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.info_outline),
                label: Text('Información'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Color(0xFF0A6E39),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
