import 'package:flutter/material.dart';
import 'package:parqueadero/views/periodo_view.dart'; // Importa la vista PeriodoView
import 'package:parqueadero/views/espacio_view.dart'; // Importa la vista EspacioView
import 'package:parqueadero/views/reportes_view.dart';

class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Administrativo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mensaje de bienvenida
            Text('Bienvenido al Panel Administrativo',
                style: TextStyle(fontSize: 24)),

            SizedBox(height: 20),

            // Botón para ir a la vista PeriodoView
            ElevatedButton(
              onPressed: () {
                // Navega a la vista PeriodoView cuando se presiona el botón
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PeriodoView()), // Navega a PeriodoView
                );
              },
              child: Text('Editar Períodos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Botón para ir a la vista EspacioView
            ElevatedButton(
              onPressed: () {
                // Navega a la vista EspacioView cuando se presiona el botón
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EspacioView()), // Navega a EspacioView
                );
              },
              child: Text('Editar Espacios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Botón para ir a la vista de reportes
            ElevatedButton(
              onPressed: () {
                // Navega a la vista de reportes cuando se presiona el botón
                /*Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ReportesView()), // Navega a ReportesView
                );*/
              },
              child: Text('Reportes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
