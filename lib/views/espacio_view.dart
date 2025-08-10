import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/models/espacio_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EspacioView extends StatefulWidget {
  @override
  _EspacioViewState createState() => _EspacioViewState();
}

class _EspacioViewState extends State<EspacioView> {
  final EspacioController _controller = EspacioController();
  TextEditingController _seccionController = TextEditingController();
  TextEditingController _cantidadController = TextEditingController();

  // Variable para almacenar las secciones disponibles obtenidas desde Firestore
  List<String> secciones = [];

  @override
  void initState() {
    super.initState();
    // Iniciar la obtención de las secciones disponibles
    _obtenerSecciones();
  }

  // Obtener las secciones únicas de Firestore en tiempo real
  Stream<List<String>> _obtenerSecciones() {
    return FirebaseFirestore.instance
        .collection('espacios')
        .snapshots()
        .map((snapshot) {
      Set<String> seccionesSet = {};
      snapshot.docs.forEach((doc) {
        String seccion = doc['seccion'];
        seccionesSet.add(seccion); // Extraemos las secciones únicas
      });
      return seccionesSet.toList(); // Convertimos Set a List
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Espacios')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo para ingresar la sección (solo es necesario para agregar espacios)
            TextField(
              controller: _seccionController,
              decoration: InputDecoration(labelText: 'Sección'),
            ),
            // Campo para ingresar la cantidad de espacios
            TextField(
              controller: _cantidadController,
              decoration: InputDecoration(labelText: 'Cantidad de Espacios'),
              keyboardType: TextInputType.number,
            ),
            // Botón para agregar múltiples espacios
            ElevatedButton(
              onPressed: () async {
                String seccion = _seccionController.text;
                int cantidad = int.tryParse(_cantidadController.text) ?? 0;

                if (cantidad > 0 && seccion.isNotEmpty) {
                  try {
                    await _controller.agregarMultiplesEspacios(
                        seccion, cantidad);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Espacios agregados correctamente.')));
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Ingrese una sección y cantidad válida.')));
                }
              },
              child: Text('Agregar Espacios'),
            ),
            // Mostrar total de espacios por todas las secciones en tiempo real
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _obtenerSecciones(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error al obtener las secciones.');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No hay secciones disponibles.');
                  } else {
                    // Mostrar el total de espacios por sección en tiempo real
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        String seccion = snapshot.data![index];
                        return StreamBuilder<int>(
                          stream: _controller
                              .obtenerTotalDeEspaciosPorSeccionEnTiempoReal(
                                  seccion),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text('Sección $seccion:'),
                                trailing: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return ListTile(
                                title: Text('Sección $seccion:'),
                                trailing: Text('Error'),
                              );
                            } else {
                              return ListTile(
                                title: Text('Sección $seccion:'),
                                trailing:
                                    Text('${snapshot.data ?? 0} Espacios'),
                              );
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
