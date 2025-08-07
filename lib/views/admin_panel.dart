import 'package:flutter/material.dart';
import 'package:parqueadero/views/periodo_view.dart';
import 'package:parqueadero/views/espacio_view.dart';
import 'package:parqueadero/views/reporte_view.dart';
import 'package:parqueadero/theme.dart';

class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, size: 28),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Panel Administrativo',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con información
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Bienvenido al Panel Administrativo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gestiona períodos, espacios y visualiza reportes del sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Título de sección
                Text(
                  'Gestión del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 16),

                // Grid de opciones administrativas
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Determinar el número de columnas basado en el ancho de la pantalla
                    int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                    double childAspectRatio =
                        constraints.maxWidth > 600 ? 1.3 : 1.1;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildAdminCard(
                          context,
                          'Períodos',
                          Icons.calendar_today,
                          'Gestionar períodos académicos',
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PeriodoView()),
                          ),
                        ),
                        _buildAdminCard(
                          context,
                          'Espacios',
                          Icons.local_parking,
                          'Administrar espacios de parqueo',
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EspacioView()),
                          ),
                        ),
                        _buildAdminCard(
                          context,
                          'Reportes',
                          Icons.analytics,
                          'Visualizar estadísticas y reportes',
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ReporteView()),
                          ),
                        ),
                        _buildAdminCard(
                          context,
                          'Configuración',
                          Icons.settings,
                          'Configuraciones del sistema',
                          Colors.purple,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Configuración próximamente disponible'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
