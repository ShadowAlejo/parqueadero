import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';
import 'package:firebase_core/firebase_core.dart';

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
      title: 'Sistema Parqueadero ESPE',
      theme: ThemeData(
        primaryColor: Color(0xFF0A6E39),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF0A6E39),
          secondary: Color(0xFFF4B400),
          error: Color(0xFFD32F2F),
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0A6E39),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0A6E39),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.roboto(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0A6E39)),
          ),
          labelStyle: GoogleFonts.roboto(color: Colors.black87),
        ),
      ),
      home: StreamBuilder(
        stream: _authCtrl.authStateChanges,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          return snapshot.hasData ? HomePage() : LoginPage();
        },
      ),
    );
  }
}
