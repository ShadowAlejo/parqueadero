import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/controllers/periodo_controller.dart';
import 'package:parqueadero/models/periodo_model.dart';
import 'package:parqueadero/theme.dart';

class PeriodoView extends StatefulWidget {
  @override
  _PeriodoViewState createState() => _PeriodoViewState();
}

class _PeriodoViewState extends State<PeriodoView> {
  final PeriodoController _periodoController = PeriodoController();
  final TextEditingController _nombreController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // Crear un nuevo periodo
  _crearNuevoPeriodo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar si ya existe un periodo activo
      List<Periodo> periodos = await _periodoController.obtenerPeriodos();
      if (periodos.isNotEmpty) {
        // Desmarcar el periodo activo anterior
        Periodo periodoActivo = periodos.firstWhere((p) => p.activo,
            orElse: () => Periodo(idPeriodo: '', activo: false, nombre: ''));
        if (periodoActivo.idPeriodo.isNotEmpty) {
          await _periodoController.actualizarPeriodo(Periodo(
            idPeriodo: periodoActivo.idPeriodo,
            activo: false,
            nombre: periodoActivo.nombre,
          ));
        }
      }

      // Crear el nuevo periodo
      String nombre = _nombreController.text.trim();
      if (nombre.isNotEmpty) {
        String idPeriodo = DateTime.now()
            .millisecondsSinceEpoch
            .toString();
        await _periodoController.agregarPeriodo(Periodo(
          idPeriodo: idPeriodo,
          activo: true,
          nombre: nombre,
        ));

        // Llamar a la función para cambiar la disponibilidad de todos los espacios a true
        await EspacioController().cambiarDisponibilidadDeTodosLosEspacios();

        _nombreController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Período creado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error al crear el período: $e'),
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

  // Mostrar un diálogo para crear el nuevo periodo
  _mostrarDialogoCrear() {
    _nombreController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text("Crear Nuevo Período"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ingresa el nombre del nuevo período académico",
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: "Nombre del Período",
                  hintText: "Ej: 2024-2025",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _crearNuevoPeriodo();
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_nombreController.text.trim().isNotEmpty) {
                  _crearNuevoPeriodo();
                  Navigator.of(context).pop();
                }
              },
              child: _isLoading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text("Crear"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Construir la vista con la lista de periodos y el botón de creación
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calendar_today, size: 24),
            SizedBox(width: 8),
            Text("Gestión de Períodos"),
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
        child: StreamBuilder<List<Periodo>>(
          stream: _periodoController.obtenerPeriodosStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Cargando períodos...',
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: AppColors.textPrimary.withOpacity(0.3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No hay períodos registrados",
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Crea el primer período académico",
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            List<Periodo> periodos = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estadísticas
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Períodos Registrados',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '${periodos.length}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: periodos.any((p) => p.activo) 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            periodos.any((p) => p.activo) ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: periodos.any((p) => p.activo) 
                                ? Colors.green 
                                : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Períodos Académicos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: periodos.length,
                      itemBuilder: (context, index) {
                        Periodo periodo = periodos[index];
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
                            border: periodo.activo 
                              ? Border.all(color: Colors.green.withOpacity(0.3), width: 2)
                              : null,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: periodo.activo 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                periodo.activo ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: periodo.activo ? Colors.green : Colors.grey,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              periodo.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              periodo.activo ? "Período Activo" : "Período Inactivo",
                              style: TextStyle(
                                color: periodo.activo 
                                  ? Colors.green 
                                  : AppColors.textPrimary.withOpacity(0.7),
                                fontWeight: periodo.activo ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: periodo.activo 
                              ? Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ACTIVO',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _mostrarDialogoCrear,
        icon: _isLoading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(Icons.add),
        label: Text(_isLoading ? 'Creando...' : 'Nuevo Período'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
      ),
    );
  }
}
