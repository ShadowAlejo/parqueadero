import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authC = AuthController();
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isRegister = false;
  String nombre = '', telefono = '';

  void _mostrarError(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(mensaje),
        actions: [
          TextButton(
            child: Text('Aceptar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/espe_logo.png',
                width: 100,
              ),
              SizedBox(height: 20),
              Text(
                isRegister ? 'Registro ESPE' : 'Ingreso ESPE',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A6E39),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Correo institucional',
                            hintText: 'ejemplo@espe.edu.ec',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (v) => email = v!.trim(),
                          validator: (v) {
                            if (v == null || !v.endsWith('@espe.edu.ec')) {
                              return 'Debe usar correo @espe.edu.ec';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            hintText: '********',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          onSaved: (v) => password = v!.trim(),
                          validator: (v) {
                            if (v == null ||
                                !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{6,}$')
                                    .hasMatch(v)) {
                              return 'Contraseña inválida';
                            }
                            return null;
                          },
                        ),
                        if (isRegister) ...[
                          SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person),
                            ),
                            onSaved: (v) => nombre = v!.trim(),
                            validator: (v) =>
                                v!.isNotEmpty ? null : 'Campo requerido',
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Teléfono (10 dígitos)',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            onSaved: (v) => telefono = v!.trim(),
                            validator: (v) {
                              if (v == null || v.length != 10) {
                                return 'Debe tener 10 dígitos';
                              }
                              return null;
                            },
                          ),
                        ],
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              _mostrarError(context,
                                  'Verifica los campos. Requisitos:\n\n• Correo @espe.edu.ec\n• Teléfono: 10 dígitos\n• Contraseña: al menos una mayúscula, una minúscula, un número y un símbolo.');
                              return;
                            }

                            _formKey.currentState!.save();

                            String? error;
                            if (isRegister) {
                              final perfil = Usuario(
                                id: '',
                                nombre: nombre,
                                email: email,
                                telefono: telefono,
                                rol: 'usuario',
                              );
                              error = await _authC.register(
                                email: email,
                                password: password,
                                perfil: perfil,
                              );
                            } else {
                              error = await _authC.login(
                                email: email,
                                password: password,
                              );
                            }

                            if (error != null) {
                              _mostrarError(context, error);
                            }
                          },
                          child: Text(isRegister ? 'Registrar' : 'Ingresar'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              setState(() => isRegister = !isRegister),
                          child: Text(
                            isRegister
                                ? '¿Ya tienes cuenta? Inicia sesión'
                                : '¿No tienes cuenta? Regístrate',
                            style: TextStyle(color: Color(0xFF0A6E39)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
