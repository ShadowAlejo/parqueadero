import 'package:flutter/material.dart';
import 'zona_detalle_page.dart';

class MapaPanel extends StatefulWidget {
  @override
  _MapaPanelState createState() => _MapaPanelState();
}

class _MapaPanelState extends State<MapaPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa del Parqueadero'),
        backgroundColor: Color(0xFF0A6E39),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Stack(
          children: [
            // 🗺️ Fondo del mapa PNG que cubre toda la pantalla
            Positioned.fill(
              child: Transform.rotate(
                angle: 0, // Puedes cambiar este valor para rotar la imagen (0 = sin rotación, 3.14 = 180 grados)
                child: Image.asset(
                  'assets/images/mapa.png',
                  fit: BoxFit.fill, // Estira la imagen para cubrir toda la pantalla
                ),
              ),
            ),

            // 🔘 Botón A - Arriba izquierda
            Positioned(
              top: 40,
              left: 20,
              child: _buildCornerButton('A', Colors.red),
            ),

            // 🔘 Botón B - Arriba derecha
            Positioned(
              top: 40,
              right: 20,
              child: _buildCornerButton('B', Colors.blue),
            ),

            // 🔘 Botón C - Abajo izquierda
            Positioned(
              bottom: 40,
              left: 20,
              child: _buildCornerButton('C', Colors.green),
            ),

            // 🔘 Botón D - Abajo derecha
            Positioned(
              bottom: 40,
              right: 20,
              child: _buildCornerButton('D', Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        _showZoneInfo(label, color);
      },
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(16),
        backgroundColor: color,
        elevation: 6,
        shadowColor: color.withOpacity(0.3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showZoneInfo(String zone, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZonaDetallePage(zona: zone, color: color),
      ),
    );
  }
}

// CustomPainter para el pin estilo Google Maps
class PinPainter extends CustomPainter {
  final Color color;
  PinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dibuja la gota (pin)
    Path path = Path();
    path.moveTo(size.width / 2, size.height);
    path.quadraticBezierTo(0, size.height * 0.55, size.width / 2, size.height * 0.15);
    path.quadraticBezierTo(size.width, size.height * 0.55, size.width / 2, size.height);
    canvas.drawPath(path, paint);

    // Dibuja el círculo exterior
    final double circleRadius = size.width * 0.35;
    final Offset circleCenter = Offset(size.width / 2, size.height * 0.32);
    canvas.drawCircle(circleCenter, circleRadius, paint);

    // Dibuja el círculo hueco interior
    final double innerRadius = size.width * 0.18;
    final Paint innerPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..blendMode = BlendMode.clear;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawCircle(circleCenter, innerRadius, innerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 