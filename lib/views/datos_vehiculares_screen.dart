import 'package:flutter/material.dart';
import '../theme.dart';

class DatosVehicularesScreen extends StatefulWidget {
  @override
  State<DatosVehicularesScreen> createState() => _DatosVehicularesScreenState();
}

class _DatosVehicularesScreenState extends State<DatosVehicularesScreen> {
  List<Map<String, String>> vehiculos = [
    {
      'tipo': 'auto',
      'placas': 'ABC-123',
      'matricula': '123456',
      'color': 'Rojo',
    },
    {
      'tipo': 'moto',
      'placas': 'XYZ-789',
      'matricula': '654321',
      'color': 'Negro',
    },
  ];

  IconData _iconoVehiculo(String tipo) {
    switch (tipo) {
      case 'auto':
        return Icons.directions_car;
      case 'moto':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }

  Color _colorVehiculo(String color) {
    switch (color.toLowerCase()) {
      case 'rojo':
        return Colors.red;
      case 'negro':
        return Colors.black;
      case 'azul':
        return Colors.blue;
      case 'blanco':
        return Colors.white;
      case 'gris':
        return Colors.grey;
      case 'amarillo':
        return Colors.yellow;
      case 'verde':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  void _eliminarVehiculo(int index) async {
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
      setState(() {
        vehiculos.removeAt(index);
      });
    }
  }

  void _editarVehiculo(BuildContext context, int index) async {
    final v = vehiculos[index];
    String tipo = v['tipo'] ?? 'auto';
    String placas = v['placas'] ?? '';
    String matricula = v['matricula'] ?? '';
    String color = v['color'] ?? '';
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
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipo,
                    items: tipoOptions
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.toUpperCase())))
                        .toList(),
                    onChanged: (val) => tipo = val ?? tipo,
                    decoration: InputDecoration(labelText: 'Tipo'),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: placas,
                    decoration: InputDecoration(labelText: 'Placa'),
                    onChanged: (val) => placas = val,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: matricula,
                    decoration: InputDecoration(labelText: 'Matrícula'),
                    onChanged: (val) => matricula = val,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: colorOptions.contains(color) ? color : null,
                    items: colorOptions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => color = val ?? color,
                    decoration: InputDecoration(labelText: 'Color'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  vehiculos[index] = {
                    'tipo': tipo,
                    'placas': placas,
                    'matricula': matricula,
                    'color': color,
                  };
                });
                Navigator.pop(context);
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehículos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: vehiculos.length,
        itemBuilder: (context, index) {
          final v = vehiculos[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Icon(
                _iconoVehiculo(v['tipo'] ?? ''),
                size: 40,
                color: _colorVehiculo(v['color'] ?? ''),
              ),
              title: Text(
                (v['tipo']?.toUpperCase() ?? ''),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Placa: ${v['placas']}'),
                  Text('Matrícula: ${v['matricula']}'),
                  Text('Color: ${v['color']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar',
                    onPressed: () => _editarVehiculo(context, index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Eliminar',
                    onPressed: () => _eliminarVehiculo(index),
                  ),
                ],
              ),
            ),
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

  void _agregarVehiculo(BuildContext context) async {
    String tipo = 'auto';
    String placas = '';
    String matricula = '';
    String color = '';
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
                DropdownButtonFormField<String>(
                  value: tipo,
                  items: tipoOptions
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (val) => tipo = val ?? tipo,
                  decoration: InputDecoration(labelText: 'Tipo'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Placa'),
                  onChanged: (val) => placas = val,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Matrícula'),
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
                  setState(() {
                    vehiculos.add({
                      'tipo': tipo,
                      'placas': placas,
                      'matricula': matricula,
                      'color': color,
                    });
                  });
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
}
