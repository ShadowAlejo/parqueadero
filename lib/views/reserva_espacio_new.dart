import 'package:flutter/material.dart';
import 'package:parqueadero/models/espacio_model.dart';

class ReservaEspacioDialog extends StatefulWidget {
  final Espacio espacio;
  final void Function(DateTime fechaInicio, DateTime fechaFin,
      TimeOfDay horaInicio, TimeOfDay horaFin) onConfirmar;
  const ReservaEspacioDialog(
      {required this.espacio, required this.onConfirmar, Key? key})
      : super(key: key);

  @override
  State<ReservaEspacioDialog> createState() => _ReservaEspacioDialogState();
}

class _ReservaEspacioDialogState extends State<ReservaEspacioDialog> {
  DateTime? _fechaInicioLocal;
  DateTime? _fechaFinLocal;
  TimeOfDay? _horaInicioLocal;
  TimeOfDay? _horaFinLocal;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Zona ${widget.espacio.seccion}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Espacio ${widget.espacio.numero}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.blue),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Selecciona la fecha y hora de tu reserva:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha inicio'),
                            OutlinedButton(
                              onPressed: () async {
                                final res = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                  initialDate:
                                      _fechaInicioLocal ?? DateTime.now(),
                                );
                                if (res != null) {
                                  setState(() => _fechaInicioLocal = res);
                                }
                              },
                              child: Text(_fechaInicioLocal == null
                                  ? 'Seleccionar'
                                  : '${_fechaInicioLocal!.toLocal().toIso8601String().split('T').first}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha fin'),
                            OutlinedButton(
                              onPressed: () async {
                                final res = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                  initialDate: _fechaFinLocal ?? DateTime.now(),
                                );
                                if (res != null) {
                                  setState(() => _fechaFinLocal = res);
                                }
                              },
                              child: Text(_fechaFinLocal == null
                                  ? 'Seleccionar'
                                  : '${_fechaFinLocal!.toLocal().toIso8601String().split('T').first}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hora inicio'),
                            OutlinedButton(
                              onPressed: () async {
                                final res = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      _horaInicioLocal ?? TimeOfDay.now(),
                                );
                                if (res != null) {
                                  setState(() => _horaInicioLocal = res);
                                }
                              },
                              child: Text(_horaInicioLocal == null
                                  ? 'Seleccionar'
                                  : _horaInicioLocal!.format(context)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hora fin'),
                            OutlinedButton(
                              onPressed: () async {
                                final res = await showTimePicker(
                                  context: context,
                                  initialTime: _horaFinLocal ?? TimeOfDay.now(),
                                );
                                if (res != null) {
                                  setState(() => _horaFinLocal = res);
                                }
                              },
                              child: Text(_horaFinLocal == null
                                  ? 'Seleccionar'
                                  : _horaFinLocal!.format(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 220),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar Reserva'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: (_fechaInicioLocal != null &&
                                _fechaFinLocal != null &&
                                _horaInicioLocal != null &&
                                _horaFinLocal != null)
                            ? () {
                                widget.onConfirmar(
                                  _fechaInicioLocal!,
                                  _fechaFinLocal!,
                                  _horaInicioLocal!,
                                  _horaFinLocal!,
                                );
                                Navigator.of(context).pop();
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
