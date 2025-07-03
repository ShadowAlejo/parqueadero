import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class HomePage extends StatelessWidget {
  final _authC = AuthController();

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _authC.logout(),
          )
        ],
      ),
      body: Center(child: Text('Contenido protegido')),
    );
  }
}
