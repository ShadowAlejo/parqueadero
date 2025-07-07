import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';
import 'mapa_panel.dart';

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
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MapaPanel()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(16),
                          backgroundColor: Color(0xFF0A6E39),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 40),
                            SizedBox(height: 10),
                            Text('Mapa del Parqueadero', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
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
        // Navegación futura
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
