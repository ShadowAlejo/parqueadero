import 'package:flutter/material.dart';
import 'package:parqueadero/models/espacio_model.dart';
import 'package:intl/intl.dart';

class ReservaEspacioDialog extends StatefulWidget {
  final Espacio espacio;
  final void Function(DateTime fechaInicio, DateTime fechaFin,
      TimeOfDay horaInicio, TimeOfDay horaFin) onConfirmar;

  const ReservaEspacioDialog({
    required this.espacio,
    required this.onConfirmar,
    Key? key,
  }) : super(key: key);

  @override
  State<ReservaEspacioDialog> createState() => _ReservaEspacioDialogState();
}

class _ReservaEspacioDialogState extends State<ReservaEspacioDialog> {
  DateTime? _fechaInicioLocal;
  DateTime? _fechaFinLocal;
  TimeOfDay? _horaInicioLocal;
  TimeOfDay? _horaFinLocal;

  // ------- Formato -------
  String _fmtFecha(DateTime d) => DateFormat('d MMM y', 'es').format(d);
  String _fmtHora(TimeOfDay t) {
    final loc = MaterialLocalizations.of(context);
    return loc.formatTimeOfDay(t, alwaysUse24HourFormat: true);
  }

  // ------- Pickers -------
  Future<void> _seleccionarFechaInicio() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _fechaInicioLocal ?? hoy,
      firstDate: hoy,
      lastDate: DateTime(hoy.year + 2),
      helpText: 'Selecciona la fecha de inicio',
    );
    if (picked != null) {
      setState(() {
        _fechaInicioLocal = DateTime(picked.year, picked.month, picked.day);
        if (_fechaFinLocal != null &&
            _fechaFinLocal!.isBefore(_fechaInicioLocal!)) {
          _fechaFinLocal = _fechaInicioLocal;
        }
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final base = _fechaInicioLocal ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _fechaFinLocal ?? base,
      firstDate: base,
      lastDate: DateTime(base.year + 2),
      helpText: 'Selecciona la fecha de fin',
    );
    if (picked != null) {
      setState(() =>
          _fechaFinLocal = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInicioLocal ?? TimeOfDay.now(),
      helpText: 'Selecciona la hora de inicio',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _horaInicioLocal = picked);
  }

  Future<void> _seleccionarHoraFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaFinLocal ?? TimeOfDay.now(),
      helpText: 'Selecciona la hora de fin',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _horaFinLocal = picked);
  }

  // ------- UI pickers (responsive: 1 o 2 columnas) -------
  Widget _pickerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si cada columna quedaría <170 px, usamos 1 columna (full width)
        final tentativeTwoColWidth = (constraints.maxWidth - 12) / 2;
        final columns = tentativeTwoColWidth < 170 ? 1 : 2;
        final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PickerTile(
              label: 'Fecha inicio',
              value: _fechaInicioLocal == null
                  ? 'Seleccionar'
                  : _fmtFecha(_fechaInicioLocal!),
              icon: Icons.calendar_today,
              onTap: _seleccionarFechaInicio,
              width: itemWidth,
            ),
            _PickerTile(
              label: 'Fecha fin',
              value: _fechaFinLocal == null
                  ? 'Seleccionar'
                  : _fmtFecha(_fechaFinLocal!),
              icon: Icons.calendar_today,
              onTap: _seleccionarFechaFin,
              width: itemWidth,
            ),
            _PickerTile(
              label: 'Hora inicio',
              value: _horaInicioLocal == null
                  ? 'Seleccionar'
                  : _fmtHora(_horaInicioLocal!),
              icon: Icons.access_time,
              onTap: _seleccionarHoraInicio,
              width: itemWidth,
            ),
            _PickerTile(
              label: 'Hora fin',
              value: _horaFinLocal == null
                  ? 'Seleccionar'
                  : _fmtHora(_horaFinLocal!),
              icon: Icons.access_time,
              onTap: _seleccionarHoraFin,
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _fechaInicioLocal != null &&
        _fechaFinLocal != null &&
        _horaInicioLocal != null &&
        _horaFinLocal != null;

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
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Espacio ${widget.espacio.numero}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona la fecha y hora de tu reserva:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Grid responsive de pickers
                  _pickerGrid(),

                  const SizedBox(height: 20),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar Reserva'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: canConfirm
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

// ---------- Botón reutilizable para cada picker ----------
class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final double width;

  const _PickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width, // ocupa todo el ancho calculado (columna)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity, // botón a todo el ancho del tile
            height: 52, // un poco más alto
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.circle, size: 0), // placeholder
              // truco: usamos Row interno para controlar icono+texto
              label: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
