import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/models/espacio_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parqueadero/theme.dart';

class EspacioView extends StatefulWidget {
  @override
  _EspacioViewState createState() => _EspacioViewState();
}

class _EspacioViewState extends State<EspacioView> {
  final EspacioController _controller = EspacioController();
  TextEditingController _seccionController = TextEditingController();
  TextEditingController _cantidadController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
        seccionesSet.add(seccion);
      });
      return seccionesSet.toList();
    });
  }

  // Agregar múltiples espacios con mejor UX
  Future<void> _agregarEspacios() async {
    String seccion = _seccionController.text.trim();
    int cantidad = int.tryParse(_cantidadController.text) ?? 0;

    if (cantidad <= 0 || seccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Ingrese una sección y cantidad válida'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.agregarMultiplesEspacios(seccion, cantidad);
      
      // Limpiar campos
      _seccionController.clear();
      _cantidadController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('$cantidad espacios agregados a la sección $seccion'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error al agregar espacios: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.local_parking, size: 24),
            SizedBox(width: 8),
            Text('Gestión de Espacios'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con formulario
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        Icon(
                          Icons.add_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Agregar Nuevos Espacios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _seccionController,
                            decoration: InputDecoration(
                              labelText: 'Sección',
                              hintText: 'Ej: A, B, C...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.category),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (value) {
                              if (value.isNotEmpty && _cantidadController.text.isNotEmpty) {
                                _agregarEspacios();
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cantidadController,
                            decoration: InputDecoration(
                              labelText: 'Cantidad',
                              hintText: 'Número',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (value) {
                              if (value.isNotEmpty && _seccionController.text.isNotEmpty) {
                                _agregarEspacios();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _agregarEspacios,
                        icon: _isLoading 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.add),
                        label: Text(_isLoading ? 'Agregando...' : 'Agregar Espacios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              Text(
                'Espacios por Sección',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Lista de secciones con conteo en tiempo real
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _obtenerSecciones(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Cargando secciones...',
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.withOpacity(0.7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error al cargar las secciones',
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_parking_outlined,
                              size: 64,
                              color: AppColors.textPrimary.withOpacity(0.3),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay secciones disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Agrega espacios para crear secciones',
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          String seccion = snapshot.data![index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
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
                            child: StreamBuilder<int>(
                              stream: _controller.obtenerTotalDeEspaciosPorSeccionEnTiempoReal(seccion),
                              builder: (context, snapshot) {
                                bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                                int totalEspacios = snapshot.data ?? 0;
                                
                                return ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  leading: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.local_parking,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    'Sección $seccion',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isLoading ? 'Calculando...' : '$totalEspacios espacios disponibles',
                                    style: TextStyle(
                                      color: AppColors.textPrimary.withOpacity(0.7),
                                    ),
                                  ),
                                  trailing: isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '$totalEspacios',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                );
                              },
                            ),
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
      ),
    );
  }
}
