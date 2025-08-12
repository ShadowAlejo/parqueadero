import 'package:flutter/material.dart';
import 'package:parqueadero/views/periodo_view.dart';
import 'package:parqueadero/views/espacio_view.dart';
import 'package:parqueadero/views/reporte_view.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        backgroundColor: cs.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surfaceVariant.withOpacity(0.6),
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(),
                const SizedBox(height: 20),

                // === GRID RESPONSIVE SIN OVERFLOW ===
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxW = constraints.maxWidth;
                    final bool isWide = maxW >= 900;
                    final bool isTablet = maxW >= 600 && !isWide;
                    final int crossAxisCount = isWide ? 3 : (isTablet ? 3 : 2);

                    // Cálculo del alto para evitar overflow
                    // (un poco más alto en móvil)
                    final double crossAxisSpacing = 16;
                    final double itemWidth =
                        (maxW - (crossAxisCount - 1) * crossAxisSpacing) /
                            crossAxisCount;
                    final double itemHeight = isWide ? 160 : 190;
                    final double ratio = itemWidth / itemHeight;

                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: 16,
                        childAspectRatio: ratio, // <- ratio dinámico
                      ),
                      children: [
                        _AdminActionCard(
                          colorA: cs.primary,
                          colorB: cs.secondary,
                          icon: Icons.date_range_rounded,
                          title: 'Períodos',
                          subtitle: 'Crear y editar periodos académicos',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PeriodoView()),
                          ),
                        ),
                        _AdminActionCard(
                          colorA: cs.tertiary,
                          colorB: cs.primary,
                          icon: Icons.local_parking_rounded,
                          title: 'Espacios',
                          subtitle: 'Gestionar zonas y espacios',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EspacioView()),
                          ),
                        ),
                        _AdminActionCard(
                          colorA: cs.secondary,
                          colorB: cs.tertiary,
                          icon: Icons.insights_rounded,
                          title: 'Reportes',
                          subtitle: 'Ocupación, reservas y métricas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReporteView()),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),
                _InfoBanner(
                  icon: Icons.info_outline_rounded,
                  text:
                      'Consejo: puedes volver aquí desde el menú principal para revisar rápidamente los reportes y abrir o cerrar periodos.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- Widgets de UI -----------------

class _HeaderCard extends StatelessWidget {
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: cs.onPrimaryContainer.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 34,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido al Panel',
                    style: txt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimaryContainer,
                    )),
                const SizedBox(height: 4),
                Text(
                  'Administra periodos, espacios de parqueo y reportes desde un mismo lugar.',
                  style: txt.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _ChipStat(text: 'Gestión rápida'),
                    _ChipStat(text: 'Diseño Material'),
                    _ChipStat(text: 'Accesos directos'),
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

class _ChipStat extends StatelessWidget {
  final String text;
  const _ChipStat({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.85),
            ),
      ),
    );
  }
}

class _AdminActionCard extends StatefulWidget {
  final Color colorA;
  final Color colorB;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.colorA,
    required this.colorB,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AdminActionCard> createState() => _AdminActionCardState();
}

class _AdminActionCardState extends State<_AdminActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.colorA.withOpacity(0.18),
                widget.colorB.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outline.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de icono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  color: cs.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),

              // Título
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: txt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),

              // Subtítulo: ocupa el resto y no desborda
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
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: txt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
