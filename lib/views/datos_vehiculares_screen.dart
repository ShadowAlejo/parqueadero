import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parqueadero/controllers/vehiculo_controller.dart';
import 'package:parqueadero/models/vehiculo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatosVehicularesScreen extends StatefulWidget {
  @override
  State<DatosVehicularesScreen> createState() => _DatosVehicularesScreenState();
}

class _DatosVehicularesScreenState extends State<DatosVehicularesScreen> {
  final VehiculoController _vehiculoController = VehiculoController();
  String _usuarioId = ''; // Guardamos el ID del usuario autenticado

  @override
  void initState() {
    super.initState();
    _getUserId(); // Llamamos a la función para obtener el ID del usuario
  }

  // Obtener el ID del usuario autenticado
  void _getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _usuarioId = user.uid; // Asignamos el ID del usuario autenticado
      });
    } else {
      print("No user is logged in");
    }
  }

  // Función para agregar vehículo
  void _agregarVehiculo(BuildContext context) async {
    String tipo = 'auto';
    String placas = '';
    String matricula = '';
    String color = '';
    String imagen = ''; // URL de la imagen

    final tipoOptions = ['auto', 'moto'];
    final colorOptions = [
      'Rojo',
      'Negro',
      'Azul',
      'Blanco',
      'Gris',
      'Amarillo',
      'Verde'
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Marca'),
                  onChanged: (val) => placas = val,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Modelo'),
                  onChanged: (val) => matricula = val,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: color.isNotEmpty ? color : null,
                  items: colorOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => color = val ?? color,
                  decoration: InputDecoration(labelText: 'Color'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'URL Imagen'),
                  onChanged: (val) => imagen = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (placas.isNotEmpty &&
                    matricula.isNotEmpty &&
                    color.isNotEmpty) {
                  final vehiculo = Vehiculo(
                    id: DateTime.now().toString(),
                    color: color,
                    marca: placas,
                    modelo: matricula,
                    urlImagen: imagen,
                    usuarioRef: FirebaseFirestore.instance
                        .doc('usuarios/$_usuarioId'), // Referencia al usuario
                  );
                  // Llamar al controlador para guardar el vehículo en Firestore
                  _vehiculoController.agregarVehiculo(vehiculo);
                  Navigator.pop(context);
                }
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  // Función para editar un vehículo
  void _editarVehiculo(BuildContext context, Vehiculo vehiculo) async {
    String tipo = vehiculo.marca;
    String placas = vehiculo.marca;
    String matricula = vehiculo.modelo;
    String color = vehiculo.color;
    String imagen = vehiculo.urlImagen;

    final tipoOptions = ['auto', 'moto'];
    final colorOptions = [
      'Rojo',
      'Negro',
      'Azul',
      'Blanco',
      'Gris',
      'Amarillo',
      'Verde'
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                TextFormField(
                  initialValue: placas,
                  decoration: InputDecoration(labelText: 'Marca'),
                  onChanged: (val) => placas = val,
                ),
                SizedBox(height: 12),
                TextFormField(
                  initialValue: matricula,
                  decoration: InputDecoration(labelText: 'Modelo'),
                  onChanged: (val) => matricula = val,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: color.isNotEmpty ? color : null,
                  items: colorOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => color = val ?? color,
                  decoration: InputDecoration(labelText: 'Color'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  initialValue: imagen,
                  decoration: InputDecoration(labelText: 'URL Imagen'),
                  onChanged: (val) => imagen = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (placas.isNotEmpty &&
                    matricula.isNotEmpty &&
                    color.isNotEmpty) {
                  final vehiculoActualizado = Vehiculo(
                    id: vehiculo.id, // Usamos el mismo ID
                    marca: placas,
                    modelo: matricula,
                    color: color,
                    urlImagen: imagen,
                    usuarioRef: FirebaseFirestore.instance
                        .doc('usuarios/$_usuarioId'), // Referencia al usuario
                  );
                  // Llamar al controlador para actualizar el vehículo en Firestore
                  _vehiculoController.actualizarVehiculo(vehiculoActualizado);
                  Navigator.pop(context);
                }
              },
              child: Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar los vehículos de Firestore
  @override
  Widget build(BuildContext context) {
    if (_usuarioId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Vehículos'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Vehículos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<List<Vehiculo>>(
        stream: _vehiculoController.obtenerVehiculosPorUsuario(_usuarioId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tienes vehículos registrados.'));
          }

          final vehiculos = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: vehiculos.length,
            itemBuilder: (context, index) {
              final v = vehiculos[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: v.urlImagen.isNotEmpty
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(v.urlImagen),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                      : Icon(
                          Icons.directions_car,
                          size: 40,
                          color: Colors.blue,
                        ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marca: ${v.marca}'),
                      Text('Modelo: ${v.modelo}'),
                      Text('Color: ${v.color}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar',
                        onPressed: () => _editarVehiculo(context, v),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Eliminar',
                        onPressed: () => _eliminarVehiculo(context, v.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregarVehiculo(context),
        icon: Icon(Icons.add),
        label: Text('Agregar vehículo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Eliminar vehículo
  void _eliminarVehiculo(BuildContext context, String vehiculoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar vehículo'),
        content: Text('¿Estás seguro de que deseas eliminar este vehículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Eliminar vehículo de Firestore utilizando el ID del vehículo
      await _vehiculoController
          .eliminarVehiculo(vehiculoId); // Pasamos el ID real del vehículo
      setState(() {}); // Recargar la lista de vehículos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehículo eliminado correctamente.')),
      );
    }
  }
}
