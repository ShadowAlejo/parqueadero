import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';

// Notificador global para el modo de tema
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Sistema Parqueadero ESPE',
          theme: appTheme,
          darkTheme: darkAppTheme,
          themeMode: mode,
          home: StreamBuilder(
            stream: _authCtrl.authStateChanges,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              return snapshot.hasData ? HomePage() : LoginPage();
            },
          ),
        );
      },
    );
  }
}
