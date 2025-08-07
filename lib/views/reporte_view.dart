import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/auth_controller.dart'; // Auth Controller
import 'package:parqueadero/controllers/periodo_controller.dart'; // Periodo Controller
import 'package:parqueadero/controllers/reservacion_controller.dart'; // Reservacion Controller
import 'package:parqueadero/models/periodo_model.dart'; // Modelo de Periodo
import 'package:parqueadero/models/reservacion_model.dart'; // Modelo de Reservación

class ReporteView extends StatefulWidget {
  @override
  _ReporteViewState createState() => _ReporteViewState();
}

class _ReporteViewState extends State<ReporteView> {
  final AuthController _authController =
      AuthController(); // Controlador de autenticación
  final PeriodoController _periodoController =
      PeriodoController(); // Controlador de periodos
  final ReservacionController _reservacionController =
      ReservacionController(); // Controlador de reservaciones

  String? _selectedPeriodo; // Periodo seleccionado
  int _numeroDeUsuarios = 0; // Número de usuarios
  Map<String, int> _reservacionesPorEstado = {}; // Reservas por estado
  Map<String, int> _reservacionesPorSeccion = {}; // Reservas por sección

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  // Cargar los datos iniciales (número de usuarios, periodos y demás)
  void _cargarDatosIniciales() async {
    // Obtener número de usuarios
    _numeroDeUsuarios = await _authController.obtenerNumeroDeUsuarios();
    setState(() {});
  }

  // Obtener el número de usuarios
  Future<int> obtenerNumeroDeUsuarios() async {
    try {
      return await _authController.obtenerNumeroDeUsuarios();
    } catch (e) {
      print('Error al obtener el número de usuarios: $e');
      return 0;
    }
  }

  // Obtener el número de reservaciones por estado
  void _obtenerReservacionesPorEstado(String idPeriodo) async {
    _reservacionController
        .obtenerNumeroDeReservacionesPorEstado(idPeriodo)
        .listen((map) {
      setState(() {
        _reservacionesPorEstado = map;
      });
    });
  }

  // Obtener el número de reservaciones por sección
  void _obtenerReservacionesPorSeccion(String idPeriodo) async {
    _reservacionController
        .obtenerReservacionesPorSeccion(idPeriodo)
        .listen((map) {
      setState(() {
        _reservacionesPorSeccion = map;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Generar Reporte"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar el dropdown de periodos (necesita FutureBuilder para esperar la data)
            FutureBuilder<List<Periodo>>(
              future: _periodoController
                  .obtenerPeriodos(), // Usamos _periodoController para obtener los periodos
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar los periodos.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay periodos disponibles.'));
                } else {
                  return DropdownButton<String>(
                    value: _selectedPeriodo,
                    hint: Text("Selecciona un periodo"),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPeriodo = newValue;
                        // Obtener las reservaciones para el periodo seleccionado
                        _obtenerReservacionesPorEstado(_selectedPeriodo!);
                        _obtenerReservacionesPorSeccion(_selectedPeriodo!);
                      });
                    },
                    items: snapshot.data!.map((periodo) {
                      return DropdownMenuItem<String>(
                        value: periodo.idPeriodo,
                        child: Text(periodo.nombre),
                      );
                    }).toList(),
                  );
                }
              },
            ),

            SizedBox(height: 20),
            // Mostrar el número de usuarios
            Text("Número de usuarios registrados: $_numeroDeUsuarios"),

            SizedBox(height: 20),
            // Mostrar reservaciones por estado usando StreamBuilder
            Text("Reservaciones por estado:"),
            if (_reservacionesPorEstado.isNotEmpty)
              ..._reservacionesPorEstado.entries.map((entry) {
                return Text("${entry.key}: ${entry.value}");
              }).toList(),

            SizedBox(height: 20),
            // Mostrar reservaciones por sección usando StreamBuilder
            Text("Reservaciones por sección:"),
            if (_reservacionesPorSeccion.isNotEmpty)
              ..._reservacionesPorSeccion.entries.map((entry) {
                return Text("${entry.key}: ${entry.value}");
              }).toList(),
          ],
        ),
      ),
    );
  }
}
