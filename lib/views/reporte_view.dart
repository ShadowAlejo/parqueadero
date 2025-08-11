import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/auth_controller.dart';
import 'package:parqueadero/controllers/periodo_controller.dart';
import 'package:parqueadero/controllers/reservacion_controller.dart';
import 'package:parqueadero/models/periodo_model.dart';
import 'package:parqueadero/models/reservacion_model.dart';
import 'package:parqueadero/theme.dart';

class ReporteView extends StatefulWidget {
  @override
  _ReporteViewState createState() => _ReporteViewState();
}

class _ReporteViewState extends State<ReporteView> {
  final AuthController _authController = AuthController();
  final PeriodoController _periodoController = PeriodoController();
  final ReservacionController _reservacionController = ReservacionController();

  String? _selectedPeriodo;
  int _numeroDeUsuarios = 0;
  Map<String, int> _reservacionesPorEstado = {};
  Map<String, int> _reservacionesPorSeccion = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _numeroDeUsuarios = await _authController.obtenerNumeroDeUsuarios();
      setState(() {});
    } catch (e) {
      print('Error al obtener el número de usuarios: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _obtenerReservacionesPorEstado(String idPeriodo) async {
    _reservacionController
        .obtenerNumeroDeReservacionesPorEstado(idPeriodo)
        .listen((map) {
      setState(() {
        _reservacionesPorEstado = map;
      });
    });
  }

  void _obtenerReservacionesPorSeccion(String idPeriodo) async {
    _reservacionController
        .obtenerReservacionesPorSeccion(idPeriodo)
        .listen((map) {
      setState(() {
        _reservacionesPorSeccion = map;
      });
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(String title, Map<String, int> data, Color color) {
    if (data.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: AppColors.textPrimary.withOpacity(0.3),
            ),
            SizedBox(height: 12),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...data.entries.map((entry) {
            double percentage = data.values.reduce((a, b) => a + b) > 0
                ? (entry.value / data.values.reduce((a, b) => a + b)) * 100
                : 0;
            
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.analytics, size: 24),
            SizedBox(width: 8),
            Text("Reportes y Estadísticas"),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Cargando reportes...',
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de período
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Text(
                                'Seleccionar Período',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          FutureBuilder<List<Periodo>>(
                            future: _periodoController.obtenerPeriodos(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Text('Error al cargar los períodos');
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text('No hay períodos disponibles');
                              } else {
                                return DropdownButtonFormField<String>(
                                  value: _selectedPeriodo,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  hint: Text("Selecciona un período"),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedPeriodo = newValue;
                                      if (newValue != null) {
                                        _obtenerReservacionesPorEstado(newValue);
                                        _obtenerReservacionesPorSeccion(newValue);
                                      }
                                    });
                                  },
                                  items: snapshot.data!.map((periodo) {
                                    return DropdownMenuItem<String>(
                                      value: periodo.idPeriodo,
                                      child: Row(
                                        children: [
                                          Icon(
                                            periodo.activo ? Icons.check_circle : Icons.radio_button_unchecked,
                                            color: periodo.activo ? Colors.green : Colors.grey,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(periodo.nombre),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Estadísticas generales
                    Text(
                      'Estadísticas Generales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Usuarios Registrados',
                            '$_numeroDeUsuarios',
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Períodos Activos',
                            _selectedPeriodo != null ? '1' : '0',
                            Icons.calendar_today,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Reportes detallados
                    if (_selectedPeriodo != null) ...[
                      Text(
                        'Reportes del Período',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      SizedBox(height: 12),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDataCard(
                                'Reservaciones por Estado',
                                _reservacionesPorEstado,
                                Colors.orange,
                              ),
                              SizedBox(height: 16),
                              _buildDataCard(
                                'Reservaciones por Sección',
                                _reservacionesPorSeccion,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 64,
                                color: AppColors.textPrimary.withOpacity(0.3),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Selecciona un período',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textPrimary.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'para ver los reportes detallados',
                                style: TextStyle(
                                  color: AppColors.textPrimary.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
