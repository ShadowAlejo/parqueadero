import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';

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
              await _authC.logout();
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
                    'Bienvenido, ${usuario!.nombre}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Selecciona una opción:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 30),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuButton(
                          Icons.calendar_today, 'Reservar espacio'),
                      _buildMenuButton(Icons.cancel, 'Cancelar reserva'),
                      _buildMenuButton(Icons.map, 'Ver disponibilidad'),
                      if (usuario!.rol == 'admin')
                        _buildMenuButton(Icons.analytics, 'Ver reportes'),
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
            MaterialPageRoute(builder: (context) => MapaScreen()),
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

class MapaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final squareSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de ESPE - Belisario Quevedo'),
        backgroundColor: Color(0xFF0A6E39),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Text(
            'Mapa de parqueadero',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A6E39),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                width: squareSize - 32,
                height: squareSize - 32,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF0A6E39), width: 2),
                ),
                child: _ZoomOnlyImageViewer(squareSize: squareSize - 32),
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
    );
  }

  Widget _zonaButton(String label) {
    return ElevatedButton(
      onPressed: () {
        // Acción para cada zona (A, B, C, D) si se requiere
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0A6E39),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        elevation: 4,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ZoomOnlyImageViewer extends StatelessWidget {
  final double squareSize;
  const _ZoomOnlyImageViewer({required this.squareSize});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      panEnabled: false, // Solo zoom, sin desplazamiento
      scaleEnabled: true,
      constrained: true,
      child: SizedBox(
        width: squareSize,
        height: squareSize,
        child: Image.asset(
          'assets/images/mapa.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
