import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

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
  
  // Nuevos controladores para los campos de registro
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  DateTime? _birthDate;
  String? _selectedGender;
  
  bool _isLogin = true;
  bool _loading = false;
  String _error = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Lista de opciones de género
  final List<String> _genderOptions = ['Masculino', 'Femenino', 'No binario', 'Prefiero no decir'];

  // Controlador para animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Para registro, validar campos adicionales
    if (!_isLogin) {
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _error = 'Por favor ingresa tu nombre completo');
        return;
      }
      if (_usernameController.text.trim().isEmpty) {
        setState(() => _error = 'Por favor ingresa un nombre de usuario');
        return;
      }
      if (_selectedGender == null) {
        setState(() => _error = 'Por favor selecciona tu género');
        return;
      }
      if (_birthDate == null) {
        setState(() => _error = 'Por favor selecciona tu fecha de nacimiento');
        return;
      }
    }
    
    setState(() { _loading = true; _error = ''; });
    
    try {
      if (_isLogin) {
        // Proceso de inicio de sesión
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
        // Proceso de registro
        final cred = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // Guardar la información adicional del perfil en la base de datos
        await _database.child('usuarios/${cred.user!.uid}/perfil').set({
          'fullName': _fullNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'gender': _selectedGender,
          // Formato legible para mostrar
          'birthDate': DateFormat('dd/MM/yyyy').format(_birthDate!),
          // También almacenar la fecha en formato ISO para cálculos si es necesario
          'birthDateISO': _birthDate!.toIso8601String(),
          'email': _emailController.text.trim(),
          // Valores por defecto para otros campos
          'bio': 'Hola, ¡me encanta compartir mis reseñas!',
          'createdAt': DateTime.now().toIso8601String(),
        });
        
        // Actualizar el displayName del usuario en Firebase Auth
        await cred.user!.updateDisplayName(_usernameController.text.trim());
        
        // Enviar correo de verificación
        await cred.user!.sendEmailVerification();
        await _showVerificationSentDialog();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Este correo ya está registrado';
          break;
        case 'invalid-email':
          errorMessage = 'El formato de correo no es válido';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil';
          break;
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este correo';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        default:
          errorMessage = e.message ?? 'Error de autenticación';
      }
      setState(() => _error = errorMessage);
    } catch (e) {
      setState(() => _error = 'Error inesperado: $e');
    }
    
    setState(() => _loading = false);
  }

  // Seleccionar fecha de nacimiento
  Future<void> _selectBirthDate() async {
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
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              )
            )
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _showVerificationSentDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        title: const Text('Verifica tu correo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 70,
              color: Theme.of(context).primaryColor,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text('Hemos enviado un enlace de verificación. Revisa tu bandeja y haz clic en él.'),
          ],
        ),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              )
            ),
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
      body: Stack(
        children: [
          // Fondo con gradiente y formas
          _buildBackground(),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Logo y título de la app
                      _buildHeader(),
                      
                      const SizedBox(height: 40),

                      // Tarjeta de autenticación
                      _buildAuthCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Notas legales e informativas
                      Text(
                        _isLogin
                            ? 'Al iniciar sesión, aceptas nuestros términos y política de privacidad'
                            : 'Al crear tu cuenta, aceptas nuestros términos y política de privacidad',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[300],
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: _isLogin ? 600.ms : 1100.ms),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Gradiente de fondo
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A237E), // Deep Indigo
                const Color(0xFF283593), // Indigo
                const Color(0xFF5C6BC0), // Lighter Indigo
              ],
            ),
          ),
        ),
        
        // Círculos decorativos
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        
        // Patrón decorativo (puntos)
        Positioned.fill(
          child: CustomPaint(
            painter: DotPatternPainter(
              dotColor: Colors.white.withOpacity(0.15),
              dotSize: 4,
              spacing: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icono o logo
        Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.movie_filter,
            size: 64,
            color: Colors.white,
          ),
        ).animate().scale(
          duration: 800.ms, 
          curve: Curves.elasticOut,
          delay: 300.ms,
        ),
        
        const SizedBox(height: 16),
        
        // Título de la app
        Text(
          'Reviews Waves',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 5.0,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ).animate().slideY(
          begin: -0.5, 
          end: 0, 
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        ),
        
        const SizedBox(height: 8),
        
        // Subtítulo o slogan
        Text(
          'Comparte y descubre reseñas de películas',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[100],
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
          delay: 400.ms,
          duration: 600.ms,
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.black.withOpacity(0.4),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de modo (login/registro)
            _buildModeSelector(),
            
            const SizedBox(height: 20),

            // Mensaje de error
            if (_error.isNotEmpty)
              _buildErrorMessage(),

            const SizedBox(height: 8),
            
            // Formulario
            Form(
              key: _formKey,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                child: Column(
                  children: [
                    // Campos adicionales para registro
                    if (!_isLogin) _buildRegistrationFields(),
                    
                    // Email
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Correo electrónico',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && v.contains('@') ? null : 'Email inválido',
                      animationDelay: _isLogin ? 0 : 400,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contraseña
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Contraseña',
                      icon: Icons.lock_rounded,
                      obscureText: _obscurePassword,
                      validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      animationDelay: _isLogin ? 100 : 500,
                    ),
                    
                    // Confirmar contraseña (solo para registro)
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmController,
                        hint: 'Confirmar contraseña',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        validator: (v) => v == _passwordController.text ? null : 'Las contraseñas no coinciden',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        animationDelay: 600,
                      ),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Botón de acción
                    _buildActionButton(),
                    
                    const SizedBox(height: 16),
                    
                    // Botón para olvidé mi contraseña
                    if (_isLogin)
                      TextButton(
                        onPressed: () {
                          // Implementar recuperación de contraseña
                          showDialog(
                            context: context,
                            builder: (context) => _buildResetPasswordDialog(),
                          );
                        },
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 0.3,
      end: 0,
      duration: 800.ms,
      curve: Curves.easeOutQuad,
      delay: 200.ms,
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeSelectorButton(
              title: 'Iniciar Sesión',
              isSelected: _isLogin,
              onTap: () => setState(() { _isLogin = true; _error = ''; }),
            ),
          ),
          Expanded(
            child: _buildModeSelectorButton(
              title: 'Registrarse',
              isSelected: !_isLogin,
              onTap: () => setState(() { _isLogin = false; _error = ''; }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectorButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildRegistrationFields() {
    return Column(
      children: [
        // Nombre completo
        _buildTextField(
          controller: _fullNameController,
          hint: 'Nombre completo',
          icon: Icons.person_rounded,
          validator: (v) => v != null && v.isNotEmpty ? null : 'Campo requerido',
          animationDelay: 0,
        ),
        
        const SizedBox(height: 16),
        
        // Nombre de usuario
        _buildTextField(
          controller: _usernameController,
          hint: 'Nombre de usuario',
          icon: Icons.alternate_email,
          validator: (v) => v != null && v.isNotEmpty ? null : 'Campo requerido',
          animationDelay: 100,
        ),
        
        const SizedBox(height: 16),
        
        // Género
        _buildDropdownField(
          value: _selectedGender,
          items: _genderOptions,
          hint: 'Selecciona tu género',
          icon: Icons.people_rounded,
          animationDelay: 200,
        ),
        
        const SizedBox(height: 16),
        
        // Fecha de nacimiento
        _buildDateField(
          animationDelay: 300,
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int animationDelay = 0,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[500],
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black87,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: TextInputAction.next,
    ).animate().fadeIn(
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 400),
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    int animationDelay = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[100],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        hint: Text(
          hint,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        icon: const Icon(Icons.arrow_drop_down_rounded),
        isExpanded: true,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue;
          });
        },
        validator: (v) => v != null ? null : 'Por favor selecciona una opción',
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 400),
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildDateField({
    int animationDelay = 0,
  }) {
    return InkWell(
      onTap: _selectBirthDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey[100],
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                size: 22,
              ),
            ),
            Expanded(
              child: Text(
                _birthDate == null
                    ? 'Selecciona tu fecha de nacimiento'
                    : DateFormat('dd/MM/yyyy').format(_birthDate!),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _birthDate == null ? Colors.grey[500] : Colors.black87,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 400),
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
        disabledBackgroundColor: Theme.of(context).primaryColor.withOpacity(0.6),
      ),
      child: _loading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'Iniciar Sesión' : 'Completar Registro',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
    ).animate().fadeIn(
      delay: _isLogin ? 200.ms : 700.ms,
    ).shimmer(
      duration: 1200.ms,
      color: Colors.white.withOpacity(0.3),
      delay: _isLogin ? 400.ms : 900.ms,
    );
  }

  Widget _buildResetPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
    bool isLoading = false;
    String error = '';
    
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Recuperar contraseña',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.password_rounded,
                  size: 64,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 16),
                
                Text(
                  'Ingresa tu correo electrónico y te enviaremos instrucciones para restablecer tu contraseña.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                if (error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      error,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                TextFormField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_rounded),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v != null && v.contains('@') ? null : 'Email inválido',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading 
                  ? null 
                  : () async {
                      if (resetFormKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                          error = '';
                        });
                        
                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: resetEmailController.text.trim());
                          
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Se ha enviado un correo para restablecer tu contraseña')),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setState(() {
                            error = e.message ?? 'Error al enviar el correo';
                            isLoading = false;
                          });
                        } catch (e) {
                          setState(() {
                            error = 'Error inesperado';
                            isLoading = false;
                          });
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Enviar',
                      style: GoogleFonts.poppins(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class DotPatternPainter extends CustomPainter {
  final Color dotColor;
  final double dotSize;
  final double spacing;

  DotPatternPainter({
    required this.dotColor,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}