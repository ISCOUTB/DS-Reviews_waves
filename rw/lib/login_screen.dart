import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logging/logging.dart';

final log = Logger('LoginScreen');

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
  final _usernameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await _handleLogin();
      } else {
        await _handleRegistration();
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      log.warning('Error de autenticación: $e');
    }
  }

  Future<void> _handleLogin() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito y volver a la pantalla anterior
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Sesión iniciada exitosamente!')),
      );
      Navigator.pop(context);
    } catch (e) {
      throw e; // Re-lanzar la excepción para que sea manejada por _submitForm
    }
  }

  Future<void> _handleRegistration() async {
    try {
      // Crear la cuenta de usuario
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Guardar la información adicional en la base de datos de Firebase
      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!.uid);
      }
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito y volver a la pantalla anterior
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cuenta creada exitosamente!')),
      );
      Navigator.pop(context);
    } catch (e) {
      throw e; // Re-lanzar la excepción para que sea manejada por _submitForm
    }
  }

  Future<void> _createUserProfile(String userId) async {
    try {
      // Referencia a la base de datos de Firebase
      final database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://reviews-waves-86c01-default-rtdb.firebaseio.com',
      ).ref();
      
      // Crear perfil inicial del usuario
      await database.child('usuarios/$userId').set({
        'perfil': {
          'username': _usernameController.text.trim(),
          'createdAt': ServerValue.timestamp,
          'avatarUrl': '', // URL de avatar vacía por defecto
          'bio': '',
        },
        'stats': {
          'reviews': 0,
          'likes': 0,
          'followers': 0,
        },
        'favoritos': {
          'peliculas': {},
          'series': {},
        }
      });
    } catch (e) {
      log.warning('Error al crear perfil de usuario: $e');
      throw Exception('Error al crear el perfil. Inténtalo de nuevo.');
    }
  }

  // Convierte los códigos de error de Firebase en mensajes amigables para el usuario
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No existe ninguna cuenta con este correo electrónico.';
        case 'wrong-password':
          return 'Contraseña incorrecta. Inténtalo de nuevo.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este correo electrónico.';
        case 'weak-password':
          return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
        case 'invalid-email':
          return 'El formato del correo electrónico no es válido.';
        case 'operation-not-allowed':
          return 'La operación no está permitida. Contacta al soporte.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Inténtalo más tarde.';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    }
    return 'Error inesperado. Por favor inténtalo de nuevo.';
  }

  // Función auxiliar para convertir opacity (0.0-1.0) a alpha (0-255)
  int _opacityToAlpha(double opacity) {
    return (opacity * 255).round();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tema actual para usar los colores apropiados
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    
    // Paleta de colores adaptativa
    final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo o Ícono principal
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(_opacityToAlpha(0.2)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.movie_filter,
                        size: 60,
                        color: primaryColor,
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Título de la pantalla
                    Text(
                      _isLogin ? '¡Bienvenido de nuevo!' : 'Únete a Reviews Waves',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 12),
                    
                    // Subtítulo
                    Text(
                      _isLogin 
                          ? 'Inicia sesión para ver tus películas y series favoritas'
                          : 'Crea una cuenta para guardar tus reviews y descubrir nuevos contenidos',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 32),
                    
                    // Campo de nombre de usuario (solo para registro)
                    if (!_isLogin)
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de usuario',
                          hintText: 'Ingresa tu nombre de usuario',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: inputBorderColor!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: inputBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                        validator: (value) {
                          if (!_isLogin && (value == null || value.trim().length < 3)) {
                            return 'El nombre de usuario debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms)
                        .slideY(begin: 0.2, end: 0, duration: 400.ms),
                    
                    if (!_isLogin) const SizedBox(height: 16),
                    
                    // Campo de correo electrónico
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        hintText: 'Ingresa tu correo electrónico',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorderColor!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo electrónico';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Ingresa un correo electrónico válido';
                        }
                        return null;
                      },
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms),
                    
                    const SizedBox(height: 16),
                    
                    // Campo de contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: _isLogin ? 'Ingresa tu contraseña' : 'Crea una contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        if (!_isLogin && value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms),
                    
                    const SizedBox(height: 8),
                    
                    // Olvidé mi contraseña (solo para login)
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Implementar recuperación de contraseña aquí
                            if (_emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingresa tu correo electrónico primero')),
                              );
                              return;
                            }
                            
                            _auth.sendPasswordResetEmail(email: _emailController.text.trim())
                                .then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Se ha enviado un correo para restablecer tu contraseña')),
                              );
                            }).catchError((error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_getErrorMessage(error))),
                              );
                            });
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 700.ms),
                    
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms)
                        .shake(duration: 400.ms),
                    
                    const SizedBox(height: 24),
                    
                    // Botón de acción principal
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 800.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms),
                    
                    const SizedBox(height: 16),
                    
                    // Divisor con texto "O"
                    Row(
                      children: [
                        Expanded(child: Divider(color: inputBorderColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'O',
                            style: TextStyle(color: subtitleColor),
                          ),
                        ),
                        Expanded(child: Divider(color: inputBorderColor)),
                      ],
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 900.ms),
                    
                    const SizedBox(height: 16),
                    
                    // Botón alternativo (cambiar modo)
                    TextButton(
                      onPressed: _toggleAuthMode,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text(
                        _isLogin
                            ? '¿No tienes una cuenta? Regístrate'
                            : '¿Ya tienes una cuenta? Inicia sesión',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 1000.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}