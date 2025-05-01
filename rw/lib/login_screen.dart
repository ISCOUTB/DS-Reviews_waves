import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String _error = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });
    try {
      if (_isLogin) {
        final cred = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!cred.user!.emailVerified) {
          // Mostrar alerta de correo no verificado
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Correo no verificado'),
              content: const Text('Debes verificar tu correo antes de iniciar sesión.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    final user = _auth.currentUser;
                    if (user != null) await user.sendEmailVerification();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reenviar correo'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
          await _auth.signOut();
          setState(() => _error = 'Por favor verifica tu correo antes de iniciar sesión');
          return;
        } else {
          Navigator.of(context).pop();
        }
      } else {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await cred.user!.sendEmailVerification();
        await _showVerificationSentDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error de autenticación');
    } catch (_) {
      setState(() => _error = 'Error inesperado');
    }
    setState(() => _loading = false);
  }

  Future<void> _showVerificationSentDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verifica tu correo'),
        content: const Text('Hemos enviado un enlace de verificación. Revisa tu bandeja y haz clic en él.'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final user = _auth.currentUser;
                if (user != null) {
                  await user.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo reenviado'))
                  );
                }
              } catch (_) {}
            },
            child: const Text('Reenviar'),
          ),
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) await user.reload();
              if (user != null && user.emailVerified) {
                Navigator.of(context)
                  ..pop() // cierra diálogo
                  ..pop(); // cierra pantalla
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aún no verificado'))
                );
              }
            },
            child: const Text('Ya verifiqué'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => setState(() { _isLogin = true; _error = ''; }),
                    child: Text('Login', style: TextStyle(color: _isLogin ? Colors.blue : Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => setState(() { _isLogin = false; _error = ''; }),
                    child: Text('Registro', style: TextStyle(color: !_isLogin ? Colors.blue : Colors.grey)),
                  ),
                ],
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.contains('@') ? null : 'Email inválido',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                  obscureText: true,
                  validator: (v) => v == _passwordController.text ? null : 'Las contraseñas no coinciden',
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isLogin ? 'Ingresar' : 'Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}