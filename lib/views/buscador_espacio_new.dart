import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/models/espacio_model.dart';

class _EspacioSeleccionadoResult {
  final Espacio? espacio;
  _EspacioSeleccionadoResult(this.espacio);
}

class BuscadorEspacioWidget extends StatelessWidget {
  final String zona;
  final EspacioController espacioController;
  final void Function(Espacio)? onEspacioReservar;
  const BuscadorEspacioWidget(
      {required this.zona,
      required this.espacioController,
      this.onEspacioReservar,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () async {
          final resultado = await showDialog<_EspacioSeleccionadoResult>(
            context: context,
            builder: (ctx) => Center(
              child: Material(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: BuscadorEspacioDialog(
                    zona: zona,
                    espacioController: espacioController,
                  ),
                ),
              ),
            ),
          );
          if (resultado != null &&
              resultado.espacio != null &&
              resultado.espacio!.disponible) {
            if (onEspacioReservar != null) {
              onEspacioReservar!(resultado.espacio!);
            }
          }
        },
        child: AbsorbPointer(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar espacio por número',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class BuscadorEspacioDialog extends StatefulWidget {
  final String zona;
  final EspacioController espacioController;
  const BuscadorEspacioDialog(
      {required this.zona, required this.espacioController, Key? key})
      : super(key: key);

  @override
  State<BuscadorEspacioDialog> createState() => _BuscadorEspacioDialogState();
}

class _BuscadorEspacioDialogState extends State<BuscadorEspacioDialog> {
  final TextEditingController _controller = TextEditingController();
  Espacio? _espacioSeleccionado;
  String? _mensaje;
  int? _minEspacio;
  int? _maxEspacio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Etiqueta de zona y rango
          StreamBuilder<int>(
            stream: widget.espacioController
                .obtenerTotalDeEspaciosPorSeccionEnTiempoReal(widget.zona),
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final total = snap.data!;
              if (total == 0) return const SizedBox.shrink();
              _minEspacio = 1;
              _maxEspacio = total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Zona ${widget.zona}: Espacios $_minEspacio-$_maxEspacio',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          ),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Buscar espacio por número',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {
              _espacioSeleccionado = null;
              _mensaje = null;
            }),
          ),
          const SizedBox(height: 12),
          StreamBuilder<Map<String, List<Espacio>>>(
            stream: widget.espacioController
                .obtenerEspaciosEnTiempoReal()
                .map((list) {
              // Agrupa por zona
              final map = <String, List<Espacio>>{};
              for (final e in list) {
                if (!map.containsKey(e.seccion)) map[e.seccion] = [];
                map[e.seccion]!.add(e);
              }
              return map;
            }),
            builder: (ctx, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              var lista = snap.data?[widget.zona] ?? [];
              // Ordenar por número
              lista.sort((a, b) =>
                  int.tryParse(a.numero)
                      ?.compareTo(int.tryParse(b.numero) ?? 0) ??
                  0);
              final filtro = _controller.text.trim();
              final filtrados = filtro.isEmpty
                  ? lista
                  : lista.where((e) => e.numero.contains(filtro)).toList();
              if (filtrados.isEmpty) {
                return const Text('No hay espacios que coincidan.');
              }
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final esp = filtrados[i];
                    return ListTile(
                      title: Text('Espacio ${esp.numero} - ' +
                          (esp.disponible ? 'Disponible' : 'Reservado')),
                      selected:
                          _espacioSeleccionado?.idEspacio == esp.idEspacio,
                      onTap: () {
                        setState(() {
                          _espacioSeleccionado = esp;
                          _mensaje = esp.disponible
                              ? 'Este espacio ya está disponible.'
                              : 'Este espacio ya está reservado.';
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (_mensaje != null)
            Text(
              _mensaje!,
              style: TextStyle(
                color: _espacioSeleccionado?.disponible == true
                    ? Colors.green
                    : (_espacioSeleccionado?.disponible == false
                        ? Colors.red
                        : Colors.orange),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.event_available),
              label: const Text('Reservar este espacio'),
              onPressed: (_espacioSeleccionado != null &&
                      _espacioSeleccionado!.disponible)
                  ? () {
                      Navigator.of(context).pop(
                          _EspacioSeleccionadoResult(_espacioSeleccionado));
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
