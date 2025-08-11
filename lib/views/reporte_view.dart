import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parqueadero/controllers/auth_controller.dart'; // Auth Controller
import 'package:parqueadero/controllers/periodo_controller.dart'; // Periodo Controller
import 'package:parqueadero/controllers/reservacion_controller.dart'; // Reservacion Controller
import 'package:parqueadero/models/periodo_model.dart'; // Modelo de Periodo
import 'package:parqueadero/models/reservacion_model.dart'; // Modelo de Reservación
import 'package:parqueadero/theme.dart'; // Para AppColors en la UI

/// -------------------------------
/// CONTENEDOR (lógica + estado)
/// -------------------------------
class ReporteView extends StatefulWidget {
  @override
  _ReporteViewState createState() => _ReporteViewState();
}

class _ReporteViewState extends State<ReporteView> {
  final AuthController _authController = AuthController();
  final PeriodoController _periodoController = PeriodoController();
  final ReservacionController _reservacionController = ReservacionController();

  // Estado y datos
  bool _isLoading = true;

  List<Periodo> _periodos = [];
  String? _selectedPeriodoId; // el UI trabaja por id
  Periodo? _selectedPeriodo; // seguimos guardando la instancia para tus métodos

  int _numeroDeUsuarios = 0;

  // Total de reservaciones del periodo
  int _totalReservacionesPeriodo = 0;

  // Conteo por estado del periodo
  Map<String, int> _conteoPorEstado = const {
    'pendiente': 0,
    'confirmado': 0,
    'cancelado': 0,
    'finalizado': 0,
  };

  // Conteo por sección (A/B/C/D)
  Map<String, int> _conteoPorSeccion = const {
    'A': 0,
    'B': 0,
    'C': 0,
    'D': 0,
  };

  // Suscripción al stream de conteo por sección
  StreamSubscription<Map<String, int>>? _subSecciones;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _subSecciones?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final usuarios = await _authController.obtenerNumeroDeUsuarios();
      final periodos = await _periodoController.obtenerPeriodos();

      if (!mounted) return;
      setState(() {
        _numeroDeUsuarios = usuarios;
        _periodos = periodos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los datos iniciales.')),
      );
    }
  }

  // Mantengo tu llamada al total por periodo
  Future<void> _obtenerConteoReservacionesPeriodo(Periodo? periodo) async {
    try {
      final count =
          await _reservacionController.contarReservacionesDePeriodo(periodo);
      if (!mounted) return;
      setState(() {
        _totalReservacionesPeriodo = count;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _totalReservacionesPeriodo = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el total de reservaciones.')),
      );
    }
  }

  Future<void> _obtenerConteoReservacionesPorEstado(Periodo? periodo) async {
    try {
      final mapa =
          await _reservacionController.obtenerNumeroDeReservacionesPorEstado(
        periodo,
      );
      if (!mounted) return;
      setState(() {
        _conteoPorEstado = {
          'Pendiente': mapa['pendiente'] ?? 0,
          'Confirmado': mapa['confirmado'] ?? 0,
          'Cancelado': mapa['cancelado'] ?? 0,
          'Finalizado': mapa['finalizado'] ?? 0,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _conteoPorEstado = const {
          'pendiente': 0,
          'confirmado': 0,
          'cancelado': 0,
          'finalizado': 0,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el conteo por estado.')),
      );
    }
  }

  void _suscribirConteoReservacionesPorSeccion(Periodo? periodo) {
    // Cancelar suscripción previa
    _subSecciones?.cancel();

    if (periodo == null || periodo.idPeriodo.isEmpty) {
      setState(() {
        _conteoPorSeccion = const {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      });
      return;
    }

    try {
      _subSecciones = _reservacionController
          .obtenerReservacionesPorSeccion(periodo)
          .listen((mapa) {
        if (!mounted) return;
        setState(() {
          _conteoPorSeccion = {
            'A': mapa['A'] ?? 0,
            'B': mapa['B'] ?? 0,
            'C': mapa['C'] ?? 0,
            'D': mapa['D'] ?? 0,
          };
        });
      }, onError: (e) {
        if (!mounted) return;
        setState(() {
          _conteoPorSeccion = const {'A': 0, 'B': 0, 'C': 0, 'D': 0};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar el conteo por sección.')),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _conteoPorSeccion = const {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo suscribir al conteo por sección.')),
      );
    }
  }

  // Handler para el cambio en el dropdown del UI (recibe id)
  void _onPeriodoChanged(String? periodoId) {
    setState(() {
      _selectedPeriodoId = periodoId;
      _selectedPeriodo = _periodos.firstWhere(
        (p) => p.idPeriodo == periodoId,
        orElse: () => Periodo(
          idPeriodo: '',
          nombre: '',
          activo: false,
        ),
      );
      if (_selectedPeriodo!.idPeriodo.isEmpty) {
        _selectedPeriodo = null;
      }
    });

    // Dispara tus cargas/suscripciones existentes
    _obtenerConteoReservacionesPeriodo(_selectedPeriodo);
    _obtenerConteoReservacionesPorEstado(_selectedPeriodo);
    _suscribirConteoReservacionesPorSeccion(_selectedPeriodo);
  }

  @override
  Widget build(BuildContext context) {
    return ReporteViewUI(
      isLoading: _isLoading,
      periodos: _periodos,
      selectedPeriodoId: _selectedPeriodoId,
      numeroDeUsuarios: _numeroDeUsuarios,
      totalReservaciones: _totalReservacionesPeriodo, // se muestra en UI
      reservacionesPorEstado: _conteoPorEstado,
      reservacionesPorSeccion: _conteoPorSeccion,
      onPeriodoChanged: _onPeriodoChanged,
    );
  }
}

/// -------------------------------
/// UI PURO (diseño con tarjeta total horizontal y compacta)
/// -------------------------------
class ReporteViewUI extends StatelessWidget {
  const ReporteViewUI({
    super.key,
    required this.isLoading,
    required this.periodos,
    required this.selectedPeriodoId,
    required this.numeroDeUsuarios,
    required this.totalReservaciones,
    required this.reservacionesPorEstado,
    required this.reservacionesPorSeccion,
    required this.onPeriodoChanged,
  });

  final bool isLoading;
  final List<Periodo> periodos;
  final String? selectedPeriodoId;
  final int numeroDeUsuarios;
  final int totalReservaciones;
  final Map<String, int> reservacionesPorEstado;
  final Map<String, int> reservacionesPorSeccion;
  final ValueChanged<String?> onPeriodoChanged;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.analytics, size: 24),
            SizedBox(width: 8),
            Text("Reportes y Estadísticas"),
          ],
        ),
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: isLoading
            ? _LoadingBlock()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de período
                    _CardBlock(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: primary),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 12),
                          if (periodos.isEmpty)
                            const Text('No hay períodos disponibles')
                          else
                            DropdownButtonFormField<String>(
                              value: selectedPeriodoId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              hint: const Text("Selecciona un período"),
                              onChanged: onPeriodoChanged,
                              items: periodos.map((p) {
                                return DropdownMenuItem<String>(
                                  value: p.idPeriodo,
                                  child: Row(
                                    children: [
                                      Icon(
                                        p.activo
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: p.activo
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(p.nombre),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Estadísticas generales
                    Text(
                      'Estadísticas Generales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fila 1 (tarjetas compactas verticales)
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Usuarios Registrados',
                            value: '$numeroDeUsuarios',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Períodos Activos',
                            value: selectedPeriodoId != null ? '1' : '0',
                            icon: Icons.calendar_today,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Fila 2: Total de reservaciones (horizontal y más pequeño)
                    Row(
                      children: [
                        Expanded(
                          child: _StatCardHorizontalCompact(
                            title: 'Total de reservaciones',
                            value: '$totalReservaciones',
                            icon: Icons.receipt_long,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Reportes detallados
                    if (selectedPeriodoId != null) ...[
                      Text(
                        'Reportes del Período',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _DataCard(
                                title: 'Reservaciones por Estado',
                                data: reservacionesPorEstado,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              _DataCard(
                                title: 'Reservaciones por Sección',
                                data: reservacionesPorSeccion,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const Expanded(
                        child: _EmptyState(),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// ------- Sub-widgets puramente visuales -------

class _LoadingBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando reportes...',
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textPrimary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un período',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para ver los reportes detallados',
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Tarjeta compacta vertical (usuarios, períodos)
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // reducido
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20), // reducido
          ),
          const SizedBox(height: 8), // reducido
          Text(
            value,
            style: TextStyle(
              fontSize: 20, // reducido
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2), // reducido
          Text(
            title,
            style: TextStyle(
              fontSize: 11, // reducido
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta horizontal y más compacta para "Total de reservaciones"
class _StatCardHorizontalCompact extends StatelessWidget {
  const _StatCardHorizontalCompact({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Compacta un poco más que _CardBlock (menos padding)
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // un poco menor
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono a la izquierda
          Container(
            padding: const EdgeInsets.all(8), // pequeño
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20), // pequeño
          ),
          const SizedBox(width: 10),
          // Valor y título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número grande al lado del icono
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18, // más pequeño que las otras
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11, // pequeño
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.title,
    required this.data,
    required this.color,
  });

  final String title;
  final Map<String, int> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _CardBlock(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: AppColors.textPrimary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
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

    final int total = data.values.fold<int>(0, (a, b) => a + b);

    return _CardBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: color, size: 20),
              const SizedBox(width: 8),
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
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            final double percentage =
                total > 0 ? (entry.value / total) * 100 : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
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
}
