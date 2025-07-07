import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import 'dart:math' as math;
import 'mapa_parqueadero.dart';
import 'mapa_screen.dart';
import 'mis_reservas_screen.dart';
import 'configuracion_screen.dart';
import 'datos_vehiculares_screen.dart';

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
                      _buildMenuButton(Icons.directions_car, 'Datos'),
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
        if (label == 'Datos') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DatosVehicularesScreen()),
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
