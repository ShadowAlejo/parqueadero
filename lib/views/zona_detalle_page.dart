import 'package:flutter/material.dart';

class ZonaDetallePage extends StatelessWidget {
  final String zona;
  final Color color;

  ZonaDetallePage({required this.zona, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zona $zona'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5, // Zoom mínimo (50% del tamaño original)
        maxScale: 4.0, // Zoom máximo (400% del tamaño original)
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Image.asset(
            'assets/images/zona${zona}.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
} 