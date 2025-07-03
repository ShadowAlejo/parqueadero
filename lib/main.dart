import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:parqueadero/controllers/auth_controller.dart';
import 'package:parqueadero/firebase_options.dart';
import 'package:parqueadero/views/home_page.dart';
import 'package:parqueadero/views/login_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthController _authCtrl = AuthController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MVC Auth',
      home: StreamBuilder(
        stream: _authCtrl.authStateChanges,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          // Si hay usuario, vamos a Home; si no, a Login
          final user = snapshot.data;
          return user != null ? HomePage() : LoginPage();
        },
      ),
    );
  }
}
