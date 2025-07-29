import 'package:flutter/material.dart';
import '../theme.dart';
import '../main.dart';
import '../controllers/auth_controller.dart'; // Importa el controlador de autenticación
import 'package:parqueadero/views/admin_panel.dart'; // Asegúrate de que esta importación esté correcta

class ConfiguracionScreen extends StatelessWidget {
  final AuthController authController =
      AuthController(); // Instancia del controlador

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                      child: Icon(Icons.edit,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Card(
              color: Theme.of(context).cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Aquí iría la lógica para ajustes
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Ajustes'),
                            content:
                                Text('Funcionalidad próximamente disponible.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.settings),
                      label: Text('Ajustes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (context, mode, _) {
                        final isDark = mode == ThemeMode.dark;
                        return ElevatedButton.icon(
                          onPressed: () {
                            themeModeNotifier.value =
                                isDark ? ThemeMode.light : ThemeMode.dark;
                          },
                          icon:
                              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                          label: Text(isDark
                              ? 'Tema oscuro activado'
                              : 'Tema claro activado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            // Botón visible solo para administradores
            FutureBuilder<bool>(
              future:
                  authController.isAdmin(), // Verifica si el usuario es admin
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator()); // Muestra un cargador mientras se obtiene el estado
                }

                if (snapshot.hasData && snapshot.data == true) {
                  // Si el usuario es admin, muestra el botón
                  return Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navegar al panel administrativo
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AdminPanelScreen()), // Aquí se abre AdminPanelScreen
                        );
                      },
                      icon: Icon(Icons.admin_panel_settings),
                      label: Text('Acción Administrativa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                } else {
                  // Si no es admin, no muestra nada
                  return SizedBox.shrink();
                }
              },
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
                style: infoButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
