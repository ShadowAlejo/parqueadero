import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/reservacion_controller.dart';
import '../models/usuario.dart';
import 'mapa_parqueadero.dart';
import 'mis_reservas_screen.dart';
import 'configuracion_screen.dart';
import 'datos_vehiculares_screen.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authC = AuthController();
  final _reservC = ReservacionController();
  Usuario? usuario;

  int pendientesCount = 0;
  int confirmadasCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  Future<void> _loadUsuario() async {
    final u = await _authC.getCurrentUsuario();
    setState(() => usuario = u);
    if (usuario != null) {
      _loadReservasCounts();
    }
  }

  Future<void> _loadReservasCounts() async {
    try {
      final counts = await _reservC.contarReservasPendientesYConfirmadas();
      setState(() {
        pendientesCount = counts['pendientes'] ?? 0;
        confirmadasCount = counts['confirmadas'] ?? 0;
      });
    } catch (_) {
      setState(() {
        pendientesCount = 0;
        confirmadasCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio'),
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
      body: SingleChildScrollView(
        child: usuario == null
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
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.pending_actions,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.orange[300]
                                            : Colors.orange,
                                        size: 20,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Reservas pendientes: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                      Text(
                                        pendientesCount.toString(),
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.orange[200]
                                              : Colors.orange[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.greenAccent[200]
                                            : Colors.green,
                                        size: 20,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Reservas confirmadas: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                      Text(
                                        confirmadasCount.toString(),
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.greenAccent[100]
                                              : Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                        _buildMenuButton(Icons.map, 'Disponibilidad'),
                        _buildMenuButton(Icons.bookmark, 'Mis reservas'),
                        if (usuario!.rol == 'admin')
                          _buildMenuButton(Icons.analytics, 'Ver reportes'),
                        _buildMenuButton(Icons.settings, 'Configuración'),
                        _buildMenuButton(Icons.directions_car, 'Vehículos'),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label) {
    return ElevatedButton(
      onPressed: () {
        switch (label) {
          case 'Disponibilidad':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapaParqueaderoScreen()),
            );
            break;
          case 'Mis reservas':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MisReservasScreen()),
            );
            break;
          case 'Configuración':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConfiguracionScreen()),
            );
            break;
          case 'Vehículos':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DatosVehicularesScreen()),
            );
            break;
        }
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(16),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
