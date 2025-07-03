import 'package:flutter/material.dart';
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
  // Campos extra para registro:
  String nombre = '', telefono = '', rol = '';

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegister ? 'Registro' : 'Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v!.trim(),
                validator: (v) => v!.contains('@') ? null : 'Email inválido',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (v) => password = v!.trim(),
                validator: (v) =>
                    v!.length >= 6 ? null : 'Al menos 6 caracteres',
              ),
              if (isRegister) ...[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nombre'),
                  onSaved: (v) => nombre = v!.trim(),
                  validator: (v) => v!.isNotEmpty ? null : 'Requerido',
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Teléfono'),
                  onSaved: (v) => telefono = v!.trim(),
                  validator: (v) => v!.isNotEmpty ? null : 'Requerido',
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Rol'),
                  onSaved: (v) => rol = v!.trim(),
                  validator: (v) => v!.isNotEmpty ? null : 'Requerido',
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                child: Text(isRegister ? 'Registrar' : 'Ingresar'),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  String? error;
                  if (isRegister) {
                    // crear perfil y credenciales
                    final perfil = Usuario(
                      id: '', // se pondrá en controller
                      nombre: nombre,
                      email: email,
                      telefono: telefono,
                      rol: rol,
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
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text(error)));
                  }
                },
              ),
              TextButton(
                child: Text(isRegister
                    ? '¿Ya tienes cuenta? Inicia sesión'
                    : '¿No tienes cuenta? Regístrate'),
                onPressed: () => setState(() => isRegister = !isRegister),
              )
            ],
          ),
        ),
      ),
    );
  }
}
