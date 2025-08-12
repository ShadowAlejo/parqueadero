import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/reservacion_controller.dart';
import '../models/usuario.dart';
import 'mapa_parqueadero.dart';
import 'mis_reservas_screen.dart';
import 'configuracion_screen.dart';
import 'datos_vehiculares_screen.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authC = AuthController();
  final _reservC = ReservacionController();
  Usuario? usuario;

  int pendientesCount = 0;
  int confirmadasCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  Future<void> _loadUsuario() async {
    final u = await _authC.getCurrentUsuario();
    setState(() => usuario = u);
    if (usuario != null) {
      await _loadReservasCounts();
    }
  }

  Future<void> _loadReservasCounts() async {
    try {
      final counts = await _reservC.contarReservasPendientesYConfirmadas();
      setState(() {
        pendientesCount = counts['pendientes'] ?? 0;
        confirmadasCount = counts['confirmadas'] ?? 0;
      });
    } catch (_) {
      setState(() {
        pendientesCount = 0;
        confirmadasCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: cs.primary,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content:
                      const Text('¿Estás seguro de que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sí, cerrar sesión'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await _authC.logout();
            },
          )
        ],
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.surfaceVariant.withOpacity(0.6), cs.surface],
                ),
              ),
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadReservasCounts();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderSummaryCard(
                          nombre: usuario!.nombre,
                          pendientes: pendientesCount,
                          confirmadas: confirmadasCount,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Accesos rápidos',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            final isWide = maxW >= 900;
                            final isTablet = maxW >= 600 && !isWide;
                            final crossAxisCount =
                                isWide ? 4 : (isTablet ? 3 : 2);
                            const spacing = 16.0;
                            final itemWidth =
                                (maxW - (crossAxisCount - 1) * spacing) /
                                    crossAxisCount;
                            const itemHeight = 150.0;
                            final ratio = itemWidth / itemHeight;

                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: ratio,
                              ),
                              children: [
                                _MenuCard(
                                  icon: Icons.map_rounded,
                                  title: 'Disponibilidad',
                                  subtitle: 'Ver zonas y reservar',
                                  color: cs.primary,
                                  onTap: () => _goTo('Disponibilidad'),
                                ),
                                _MenuCard(
                                  icon: Icons.bookmark_rounded,
                                  title: 'Mis reservas',
                                  subtitle: 'Pendientes y confirmadas',
                                  color: cs.secondary,
                                  onTap: () => _goTo('Mis reservas'),
                                  topRightBadge: pendientesCount > 0
                                      ? _Badge(
                                          text: '$pendientesCount',
                                          background: Colors.orange,
                                        )
                                      : null,
                                  bottomRightBadge: confirmadasCount > 0
                                      ? _Badge(
                                          text: '$confirmadasCount',
                                          background: Colors.green,
                                        )
                                      : null,
                                ),
                                _MenuCard(
                                  icon: Icons.directions_car_rounded,
                                  title: 'Vehículos',
                                  subtitle: 'Datos vehiculares',
                                  color: cs.tertiary,
                                  onTap: () => _goTo('Vehículos'),
                                ),
                                _MenuCard(
                                  icon: Icons.settings_rounded,
                                  title: 'Configuración',
                                  subtitle: 'Preferencias de la app',
                                  color: cs.primaryContainer,
                                  onTap: () => _goTo('Configuración'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _goTo(String label) {
    switch (label) {
      case 'Disponibilidad':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapaParqueaderoScreen()),
        );
        break;
      case 'Mis reservas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MisReservasScreen()),
        );
        break;
      case 'Configuración':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConfiguracionScreen()),
        );
        break;
      case 'Vehículos':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DatosVehicularesScreen()),
        );
        break;
    }
  }
}

// ================== Widgets auxiliares ==================

class _HeaderSummaryCard extends StatelessWidget {
  final String nombre;
  final int pendientes;
  final int confirmadas;

  const _HeaderSummaryCard({
    required this.nombre,
    required this.pendientes,
    required this.confirmadas,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.secondaryContainer.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: cs.onPrimaryContainer.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.person_rounded,
                size: 30, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $nombre',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: txt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reserva tu parqueadero en segundos.',
                  style: txt.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatPill(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pendientes',
                      value: pendientes,
                      color: Colors.orange,
                    ),
                    _StatPill(
                      icon: Icons.check_circle_rounded,
                      label: 'Confirmadas',
                      value: confirmadas,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? topRightBadge;
  final Widget? bottomRightBadge;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.topRightBadge,
    this.bottomRightBadge,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fondo de la card: tinte suave que funciona en ambos temas
    final Color bg = isDark
        ? Color.alphaBlend(cs.surfaceVariant.withOpacity(0.20), cs.surface)
        : Color.alphaBlend(widget.color.withOpacity(0.08), cs.surface);

    // Fondo del recuadro del icono
    final Color iconBg = isDark
        ? cs.onSurface.withOpacity(0.06)
        : widget.color.withOpacity(0.18);

    // Color del icono con buen contraste
    final Color iconFg = isDark ? cs.onSurface : widget.color;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono con contraste correcto en light/dark
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: iconFg, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: txt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      widget.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: txt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.topRightBadge != null)
                Positioned(top: 6, right: 6, child: widget.topRightBadge!),
              if (widget.bottomRightBadge != null)
                Positioned(
                    bottom: 6, right: 6, child: widget.bottomRightBadge!),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  const _Badge({required this.text, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1.0,
        ),
      ),
    );
  }
}
