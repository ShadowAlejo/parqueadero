import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/auth_controller.dart';
import 'package:parqueadero/controllers/periodo_controller.dart';
import 'package:parqueadero/controllers/reservacion_controller.dart';
import 'package:parqueadero/models/periodo_model.dart';
import 'package:parqueadero/theme.dart';

class ReportesView extends StatefulWidget {
  @override
  _ReportesViewState createState() => _ReportesViewState();
}

class _ReportesViewState extends State<ReportesView> {
  final AuthController _authController = AuthController();
  final PeriodoController _periodoController = PeriodoController();
  final ReservacionController _reservacionController = ReservacionController();

  String? _selectedPeriodo;
  int _totalUsuarios = 0;
  int _totalReservaciones = 0;
  int _reservacionesActivas = 0;
  int _reservacionesCompletadas = 0;
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
      _totalUsuarios = await _authController.obtenerNumeroDeUsuarios();
      setState(() {});
    } catch (e) {
      print('Error al cargar datos iniciales: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cargarEstadisticasPeriodo(String idPeriodo) async {
    // Aquí se cargarían las estadísticas específicas del período
    // Por ahora usamos valores de ejemplo
    setState(() {
      _totalReservaciones = 150;
      _reservacionesActivas = 45;
      _reservacionesCompletadas = 105;
    });
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, List<Map<String, dynamic>> data, Color color) {
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
              Icon(Icons.bar_chart, color: color, size: 20),
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
          ...data.map((item) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['label'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${item['value']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: item['percentage'] / 100,
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
            Icon(Icons.assessment, size: 24),
            SizedBox(width: 8),
            Text("Reportes Detallados"),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Descargando reporte...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
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
                              Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Text(
                                'Filtrar por Período',
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
                                        _cargarEstadisticasPeriodo(newValue);
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

                    // Métricas principales
                    Text(
                      'Métricas Principales',
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
                          child: _buildMetricCard(
                            'Usuarios',
                            '$_totalUsuarios',
                            'Registrados',
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Reservaciones',
                            '$_totalReservaciones',
                            'Totales',
                            Icons.bookmark,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Activas',
                            '$_reservacionesActivas',
                            'En curso',
                            Icons.play_circle,
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Completadas',
                            '$_reservacionesCompletadas',
                            'Finalizadas',
                            Icons.check_circle,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Gráficos y análisis
                    if (_selectedPeriodo != null) ...[
                      Text(
                        'Análisis Detallado',
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
                              _buildChartCard(
                                'Uso por Sección',
                                [
                                  {'label': 'Sección A', 'value': 45, 'percentage': 30.0},
                                  {'label': 'Sección B', 'value': 38, 'percentage': 25.3},
                                  {'label': 'Sección C', 'value': 32, 'percentage': 21.3},
                                  {'label': 'Sección D', 'value': 35, 'percentage': 23.3},
                                ],
                                Colors.blue,
                              ),
                              SizedBox(height: 16),
                              _buildChartCard(
                                'Estado de Reservaciones',
                                [
                                  {'label': 'Activas', 'value': _reservacionesActivas, 'percentage': (_reservacionesActivas / _totalReservaciones * 100)},
                                  {'label': 'Completadas', 'value': _reservacionesCompletadas, 'percentage': (_reservacionesCompletadas / _totalReservaciones * 100)},
                                ],
                                Colors.green,
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
                                Icons.assessment_outlined,
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
                                'para ver el análisis detallado',
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
