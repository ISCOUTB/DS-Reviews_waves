import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'utils/color_utils.dart';

// Inicializar logger para esta pantalla
final log = Logger('LoginScreen');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://reviews-waves-86c01-default-rtdb.firebaseio.com',
  ).ref();
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  
  DateTime? _birthDate;
  String? _selectedGender;
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final List<String> _genderOptions = ['Masculino', 'Femenino', 'No binario', 'Prefiero no decir'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    if (!mounted) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              )
            )
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _birthDate && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _handleLogin();
      } else {
        await _handleRegistration();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }  Future<void> _handleLogin() async {
    if (!mounted) return;
    
    final BuildContext currentContext = context;
    
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      
      if (!cred.user!.emailVerified) {
        await _showEmailVerificationDialog();
        await _auth.signOut();
        
        if (!mounted) return;
        setState(() => _errorMessage = 'Por favor verifica tu correo antes de iniciar sesión');
        return;
      }
      
      if (mounted && currentContext.mounted) {
        Navigator.of(currentContext).pop();
      }
    } catch (e) {
      if (!mounted) return;
      rethrow;
    }
  }
  Future<void> _handleRegistration() async {
    final BuildContext currentContext = context;
    
    final cred = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    
    await _database.child('usuarios/${cred.user!.uid}/perfil').set({
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'gender': _selectedGender,
      'birthDate': DateFormat('dd/MM/yyyy').format(_birthDate!),
      'birthDateIso': _birthDate!.toIso8601String(),
      'registrationDate': DateTime.now().toIso8601String(),
    });
    
    await cred.user!.sendEmailVerification();
    
    if (!mounted) return;
    
    await _showVerificationDialog();
    
    if (mounted && currentContext.mounted) {
      Navigator.of(currentContext).pop();
    }
  }
  Future<void> _showEmailVerificationDialog() async {
    if (!mounted) return;
    final BuildContext currentContext = context;
    
    await showDialog(
      context: currentContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Correo no verificado'),
        content: const Text('Debes verificar tu correo antes de iniciar sesión.'),
        actions: [
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) {
                await user.sendEmailVerification();
                if (currentContext.mounted && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              }
            },
            child: const Text('Reenviar correo'),
          ),
          TextButton(
            onPressed: () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  Future<void> _showVerificationDialog() async {
    if (!mounted) return;
    final BuildContext currentContext = context;
    
    await showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Verifica tu correo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Te hemos enviado un correo de verificación.\n'
              'Por favor verifica tu correo antes de iniciar sesión.',
            ),
            const SizedBox(height: 16),
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 50,
              color: Colors.blue,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) {
                await user.sendEmailVerification();
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Correo reenviado'))
                  );
                }
              }
            },
            child: const Text('Reenviar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              ),
            ),
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) {
                await user.reload();
                if (dialogContext.mounted) {
                  if (user.emailVerified) {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop(); // cierra diálogo
                      if (currentContext.mounted && Navigator.of(currentContext).canPop()) {
                        Navigator.of(currentContext).pop(); // cierra pantalla
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Aún no verificado'))
                    );
                  }
                }
              }
            },
            child: const Text('Ya verifiqué'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Error desconocido: $code';
    }
  }

  Future<void> _handleNavigationState() async {
    if (!_isLogin) {
      setState(() => _isLogin = true);
    }
  }  @override
  Widget build(BuildContext context) {    
    return PopScope(
      canPop: _isLogin,      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          await _handleNavigationState();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Fondo con degradado sutil
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    ColorUtils.withSafeOpacity(Theme.of(context).primaryColor, 0.05),
                  ],
                ),
              ),
            ),
            // Imagen decorativa en la esquina
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: ColorUtils.withSafeOpacity(Theme.of(context).primaryColor, 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -70,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: ColorUtils.withSafeOpacity(Theme.of(context).primaryColor, 0.06),
                  borderRadius: BorderRadius.circular(125),
                ),
              ),
            ),            // Contenido principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: MediaQuery.of(context).size.width > 600 
                            ? 500 
                            : MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo y título
                            Center(
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.movie_creation_outlined,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _isLogin ? 'Bienvenido de nuevo' : 'Crear una cuenta',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin 
                                ? 'Inicia sesión para acceder a tus reseñas'
                                : 'Regístrate para comenzar a compartir tus reseñas',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),                            const SizedBox(height: 24),
                            // Error message
                            if (_errorMessage.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

                            // Registration fields
                            if (!_isLogin) ...[
                              // Full name field
                              const Text(
                                'Nombre completo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF444444),
                                ),
                              ),
                              const SizedBox(height: 8),                              TextFormField(
                                controller: _fullNameController,
                                decoration: InputDecoration(
                                  hintText: 'Ingresa tu nombre completo',
                                  hintStyle: const TextStyle(color: Color(0xFF888888)),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                style: const TextStyle(color: Colors.black),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu nombre';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Username field
                              const Text(
                                'Nombre de usuario',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF444444),
                                ),
                              ),
                              const SizedBox(height: 8),                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: 'Elige un nombre de usuario',
                                  hintStyle: const TextStyle(color: Color(0xFF888888)),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.alternate_email),
                                ),
                                style: const TextStyle(color: Colors.black),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa un nombre de usuario';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),                              // Birth date picker
                              const Text(
                                'Fecha de nacimiento',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF444444),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectBirthDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.grey),
                                      const SizedBox(width: 12),                                      Text(
                                        _birthDate == null 
                                          ? 'Seleccionar fecha de nacimiento'
                                          : DateFormat('dd/MM/yyyy').format(_birthDate!),
                                        style: TextStyle(
                                          color: _birthDate == null ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Gender selector
                              const Text(
                                'Género',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF444444),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),                                child: DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  decoration: InputDecoration(
                                    hintText: 'Selecciona tu género',
                                    hintStyle: const TextStyle(color: Color(0xFF888888)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  style: const TextStyle(color: Colors.black),
                                  dropdownColor: Colors.white,
                                  items: _genderOptions.map((String gender) {
                                    return DropdownMenuItem<String>(
                                      value: gender,
                                      child: Text(gender),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor selecciona un género';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                              // Email field
                            const Text(
                              'Correo electrónico',                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'correo@ejemplo.com',
                                hintStyle: const TextStyle(color: Color(0xFF888888)),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.black),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!value.contains('@')) {
                                  return 'Por favor ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password field
                            const Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const SizedBox(height: 8),                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: _isLogin ? '••••••••' : 'Mínimo 6 caracteres',
                                hintStyle: const TextStyle(color: Color(0xFF888888)),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                if (!_isLogin && value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),                            // Confirm password (registration only)
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Confirmar contraseña',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF444444),
                                ),
                              ),
                              const SizedBox(height: 8),                              TextFormField(
                                controller: _confirmController,
                                decoration: InputDecoration(
                                  hintText: 'Confirma tu contraseña',
                                  hintStyle: const TextStyle(color: Color(0xFF888888)),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                style: const TextStyle(color: Colors.black),
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Botón de submit
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                  ? SizedBox(                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white.withAlpha(204), // 0.8 * 255 = ~204
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ),
                            ),                            const SizedBox(height: 16),
                            
                            // Forgot password button (only for login)
                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    _showForgotPasswordDialog();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(10, 10),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            
                            // Login/Register toggle button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                    ? '¿No tienes una cuenta?'
                                    : '¿Ya tienes una cuenta?',
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _errorMessage = '';
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: const Size(10, 10),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    _isLogin ? 'Regístrate' : 'Inicia sesión',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Políticas de privacidad y términos (sólo en registro)
                            if (!_isLogin) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Al registrarte, aceptas nuestros Términos de servicio y Política de privacidad',
                                style: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }  Future<void> _showForgotPasswordDialog() async {
    if (!mounted) return;
    
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';
    String successMessage = '';
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Recuperar contraseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(                  'Ingresa tu correo electrónico y te enviaremos instrucciones para restablecer tu contraseña.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'correo@ejemplo.com',
                    hintStyle: const TextStyle(color: Color(0xFF888888)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (successMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            successMessage,
                            style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                    },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      
                      if (email.isEmpty) {
                        setState(() {
                          errorMessage = 'Por favor ingresa tu correo electrónico';
                        });
                        return;
                      }
                      
                      if (!email.contains('@')) {
                        setState(() {
                          errorMessage = 'Por favor ingresa un correo válido';
                        });
                        return;
                      }
                      
                      setState(() {
                        isLoading = true;
                        errorMessage = '';
                        successMessage = '';
                      });
                        try {
                        // Enviar el correo de restablecimiento (método simple sin configuraciones adicionales)
                        await _auth.sendPasswordResetEmail(
                          email: email,
                        );
                        
                        setState(() {
                          isLoading = false;
                          successMessage = 'Se ha enviado un correo para restablecer tu contraseña. Por favor revisa tu bandeja de entrada.';
                        });
                        
                        // Mostrar un diálogo informativo después de enviar el correo
                        await Future.delayed(const Duration(seconds: 2), () async {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                            
                            // Mostrar información adicional una vez cerrado el primer diálogo
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (BuildContext infoContext) => AlertDialog(
                                  title: const Text('Correo enviado'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.mark_email_read,                                        size: 50,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Hemos enviado instrucciones para recuperar tu contraseña a tu correo electrónico.',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Sigue las instrucciones en el correo para crear una nueva contraseña. Si no encuentras el correo, verifica tu carpeta de spam o correo no deseado.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(infoContext).pop();
                                      },
                                      child: const Text('Entendido'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        });
                          } on FirebaseAuthException catch (e) {
                        log.info('Error en recuperación de contraseña: ${e.code}');
                        setState(() {
                          isLoading = false;
                          switch (e.code) {
                            case 'user-not-found':
                              errorMessage = 'No hay usuario registrado con este correo';
                              break;
                            case 'invalid-email':
                              errorMessage = 'El formato del correo electrónico no es válido';
                              break;
                            case 'too-many-requests':
                              errorMessage = 'Demasiados intentos. Por favor, inténtalo más tarde.';
                              break;
                            default:
                              errorMessage = 'Error al enviar el correo. Intenta de nuevo más tarde.';
                              break;
                          }
                        });
                      } catch (e) {
                        log.info('Error desconocido en recuperación de contraseña: $e');
                        setState(() {
                          isLoading = false;
                          errorMessage = 'Error desconocido: $e';
                        });
                      }
                    },
                child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Enviar correo'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DottedBackgroundPainter extends CustomPainter {
  final Color dotColor;
  
  DottedBackgroundPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 30.0;
    const dotSize = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}