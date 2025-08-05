import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/controllers/periodo_controller.dart';
import 'package:parqueadero/models/periodo_model.dart';

class PeriodoView extends StatefulWidget {
  @override
  _PeriodoViewState createState() => _PeriodoViewState();
}

class _PeriodoViewState extends State<PeriodoView> {
  final PeriodoController _periodoController = PeriodoController();
  final TextEditingController _nombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Crear un nuevo periodo
  _crearNuevoPeriodo() async {
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
          .toString(); // Usar timestamp como ID único
      await _periodoController.agregarPeriodo(Periodo(
        idPeriodo: idPeriodo,
        activo: true,
        nombre: nombre,
      ));

      // Llamar a la función para cambiar la disponibilidad de todos los espacios a true
      await EspacioController().cambiarDisponibilidadDeTodosLosEspacios();

      _nombreController.clear();
    }
  }

  // Mostrar un diálogo para crear el nuevo periodo
  _mostrarDialogoCrear() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Crear Nuevo Periodo"),
          content: TextField(
            controller: _nombreController,
            decoration: InputDecoration(labelText: "Nombre del Periodo"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                _crearNuevoPeriodo();
                Navigator.of(context).pop();
              },
              child: Text("Crear"),
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
        title: Text("Periodos"),
      ),
      body: StreamBuilder<List<Periodo>>(
        stream: _periodoController.obtenerPeriodosStream(), // Cambiado a stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No hay periodos registrados"));
          }

          List<Periodo> periodos = snapshot.data!;

          return ListView.builder(
            itemCount: periodos.length,
            itemBuilder: (context, index) {
              Periodo periodo = periodos[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(periodo.nombre),
                  subtitle: Text(periodo.activo ? "Activo" : "Inactivo"),
                  trailing: periodo.activo
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrear,
        child: Icon(Icons.add),
        tooltip: "Crear Nuevo Periodo",
      ),
    );
  }
}
