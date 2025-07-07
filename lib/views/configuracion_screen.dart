import 'package:flutter/material.dart';

class ConfiguracionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        backgroundColor: Color(0xFF0A6E39),
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
                      child: Icon(Icons.edit, color: Color(0xFF0A6E39)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text('Cambiar contraseña',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Aquí iría la lógica para cambiar contraseña
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Cambiar contraseña'),
                    content: Text('Funcionalidad próximamente disponible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.lock_reset),
              label: Text('Cambiar contraseña'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A6E39),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Color(0xFF0A6E39),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
