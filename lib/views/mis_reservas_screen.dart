import 'package:flutter/material.dart';

class _ReservaData {
  String zona;
  String espacio;
  DateTime fecha;
  String horario;
  String estado; // 'actual', 'futura', 'pasada'
  _ReservaData({
    required this.zona,
    required this.espacio,
    required this.fecha,
    required this.horario,
    required this.estado,
  });
}

class MisReservasScreen extends StatefulWidget {
  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  List<_ReservaData> reservas = [
    _ReservaData(
      zona: 'B',
      espacio: 'B-12',
      fecha: DateTime.now(),
      horario: '08:30 - 10:00',
      estado: 'actual',
    ),
    _ReservaData(
      zona: 'A',
      espacio: 'A-2',
      fecha: DateTime.now().add(Duration(days: 1)),
      horario: '10:00 - 11:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'C',
      espacio: 'C-5',
      fecha: DateTime.now().add(Duration(days: 2)),
      horario: '12:00 - 13:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'D',
      espacio: 'D-8',
      fecha: DateTime.now().add(Duration(days: 3)),
      horario: '09:00 - 10:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'A',
      espacio: 'A-4',
      fecha: DateTime.now().add(Duration(days: 4)),
      horario: '13:00 - 14:00',
      estado: 'futura',
    ),
    _ReservaData(
      zona: 'B',
      espacio: 'B-15',
      fecha: DateTime.now().add(Duration(days: 5)),
      horario: '11:00 - 12:00',
      estado: 'futura',
    ),
  ];

  final List<String> horarios = [
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
  ];

  void _cancelarReserva(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar reserva'),
        content: Text('¿Estás seguro de que deseas cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        reservas.removeAt(index);
      });
    }
  }

  void _cambiarFecha(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: reservas[index].fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        reservas[index].fecha = picked;
      });
    }
  }

  void _cambiarHorario(int index) async {
    String? nuevoHorario = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selected = reservas[index].horario;
        return AlertDialog(
          title: Text('Seleccionar horario'),
          content: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: horarios
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (value) {
              selected = value;
              Navigator.of(context).pop(value);
            },
          ),
        );
      },
    );
    if (nuevoHorario != null) {
      setState(() {
        reservas[index].horario = nuevoHorario;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasFuturas =
        reservas.where((r) => r.estado == 'futura').toList();
    final reservaActual = reservas.firstWhere(
      (r) => r.estado == 'actual',
      orElse: () => _ReservaData(
          zona: '',
          espacio: '',
          fecha: DateTime.now(),
          horario: '',
          estado: 'ninguna'),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis reservas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  if (reservaActual.estado == 'actual') ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reserva actual',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                          Card(
                            color: Theme.of(context).cardColor,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.directions_car,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.lightBlueAccent[100]
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Zona: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    TextSpan(
                                        text: reservaActual.zona,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Espacio: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    TextSpan(
                                        text: reservaActual.espacio,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Fecha: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    TextSpan(
                                        text:
                                            '${reservaActual.fecha.day.toString().padLeft(2, '0')}/${reservaActual.fecha.month.toString().padLeft(2, '0')}/${reservaActual.fecha.year}',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Horario: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    TextSpan(
                                        text: reservaActual.horario,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ])),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Estado: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    TextSpan(
                                        text: 'Confirmada',
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.greenAccent[100]
                                                    : Colors.green)),
                                  ])),
                                ],
                              ),
                              trailing: Icon(Icons.lock,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white54
                                      : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Próximas reservas',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface)),
                  ),
                  if (reservasFuturas.isEmpty)
                    Center(child: Text('No tienes reservas futuras.'))
                  else
                    ...reservasFuturas.map((r) {
                      final idx = reservas.indexOf(r);
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.directions_car,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.lightBlueAccent[100]
                                    : Theme.of(context).colorScheme.primary,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Zona: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: r.zona),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Espacio: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: r.espacio),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Fecha: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text:
                                        '${r.fecha.day.toString().padLeft(2, '0')}/${r.fecha.month.toString().padLeft(2, '0')}/${r.fecha.year}'),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Horario: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: r.horario),
                              ])),
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Estado: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: 'Confirmada',
                                    style: TextStyle(color: Colors.green)),
                              ])),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_calendar,
                                    color: Colors.orange),
                                tooltip: 'Cambiar fecha',
                                onPressed: () => _cambiarFecha(idx),
                              ),
                              IconButton(
                                icon: Icon(Icons.schedule, color: Colors.blue),
                                tooltip: 'Cambiar horario',
                                onPressed: () => _cambiarHorario(idx),
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Cancelar reserva',
                                onPressed: () => _cancelarReserva(idx),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
