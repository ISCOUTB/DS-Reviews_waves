import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

// Inicializar logger para la pantalla de perfil
final log = Logger('PerfilScreen');

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  // Configuración específica para tu instancia de Firebase Realtime Database
  final _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://reviews-waves-86c01-default-rtdb.firebaseio.com',
  ).ref();
  final _auth = FirebaseAuth.instance;
  
  final _nombreCompletoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  bool _isLoading = true;
  bool _isSaving = false;
  final Map<String, String> _usuariosExistentes = {};
  String? _usuarioOriginal;
  
  final List<String> _opcionesGenero = [
    'Masculino',
    'Femenino',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    _cargarPerfilUsuario();
    _cargarUsuariosExistentes();
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _usuarioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // Cargar nombres de usuario existentes para validación de unicidad
  Future<void> _cargarUsuariosExistentes() async {
    try {
      final snapshot = await _database.child('usuarios').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        for (var entry in data.entries) {
          final userId = entry.key as String;
          final userData = entry.value as Map<dynamic, dynamic>;
          
          if (userData.containsKey('perfil') && 
              (userData['perfil'] as Map<dynamic, dynamic>).containsKey('usuario')) {
            final username = (userData['perfil'] as Map<dynamic, dynamic>)['usuario'] as String;
            // Guardamos el uid asociado a cada nombre de usuario
            _usuariosExistentes[username] = userId;
          }
        }
      }
    } catch (e) {
      _mostrarError('Error al cargar usuarios: $e');
    }
  }

  // Cargar el perfil del usuario actual
  Future<void> _cargarPerfilUsuario() async {
    if (_auth.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final String uid = _auth.currentUser!.uid;
      final snapshot = await _database.child('usuarios/$uid/perfil').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        setState(() {
          _nombreCompletoController.text = data['nombreCompleto'] ?? '';
          _usuarioController.text = data['usuario'] ?? '';
          _usuarioOriginal = data['usuario'];
          _descripcionController.text = data['descripcion'] ?? '';
          
          if (data['fechaNacimiento'] != null) {
            _fechaNacimiento = DateTime.parse(data['fechaNacimiento']);
          }
          
          _generoSeleccionado = data['genero'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar el perfil: $e');
    }
  }

  // Guardar el perfil del usuario en Firebase
  Future<void> _guardarPerfil() async {
    if (_auth.currentUser == null) {
      _mostrarError('No has iniciado sesión');
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final String nombreUsuario = _usuarioController.text.trim();
    final String uid = _auth.currentUser!.uid;
    
    // Verificar si el nombre de usuario ya existe y no es el usuario actual
    if (_usuariosExistentes.containsKey(nombreUsuario) && 
        _usuariosExistentes[nombreUsuario] != uid &&
        nombreUsuario != _usuarioOriginal) {
      _mostrarError('El nombre de usuario ya existe. Por favor, elige otro.');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      await _database.child('usuarios/$uid/perfil').set({
        'nombreCompleto': _nombreCompletoController.text.trim(),
        'usuario': nombreUsuario,
        'descripcion': _descripcionController.text.trim(),
        'fechaNacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
        'genero': _generoSeleccionado,
      });
      
      // Actualizar la variable de usuario original
      _usuarioOriginal = nombreUsuario;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al guardar el perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Seleccionar fecha de nacimiento
  Future<void> _seleccionarFecha() async {
    final DateTime fechaActual = DateTime.now();
    final DateTime fechaMinima = DateTime(fechaActual.year - 100, 1, 1);
    final DateTime fechaMaxima = DateTime(fechaActual.year - 13, fechaActual.month, fechaActual.day);
    
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? fechaMaxima,
      firstDate: fechaMinima,
      lastDate: fechaMaxima,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      fieldLabelText: 'Fecha de nacimiento',
      errorFormatText: 'Ingresa una fecha válida',
      errorInvalidText: 'Debes tener al menos 13 años',
    );
    
    if (fechaSeleccionada != null) {
      setState(() => _fechaNacimiento = fechaSeleccionada);
    }
  }

  // Validar que el usuario tenga al menos 13 años
  bool _validarEdadMinima() {
    if (_fechaNacimiento == null) return false;
    
    final DateTime hoy = DateTime.now();
    final int edadEnAnios = hoy.year - _fechaNacimiento!.year;
    
    if (edadEnAnios > 13) return true;
    if (edadEnAnios < 13) return false;
    
    // Si tiene exactamente 13 años, verificar mes y día
    if (hoy.month < _fechaNacimiento!.month) return false;
    if (hoy.month > _fechaNacimiento!.month) return true;
    
    // Mismo mes, verificar el día
    return hoy.day >= _fechaNacimiento!.day;
  }

  // Reiniciar los campos a los valores originales
  Future<void> _cancelarCambios() async {
    await _cargarPerfilUsuario();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios cancelados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Color.fromRGBO(
                              Theme.of(context).primaryColor.r.round(),
                              Theme.of(context).primaryColor.g.round(),
                              Theme.of(context).primaryColor.b.round(),
                              0.3
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white70,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Nombre completo
                    TextFormField(
                      controller: _nombreCompletoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa tu nombre completo';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Nombre de usuario
                    TextFormField(
                      controller: _usuarioController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email),
                        helperText: 'Este nombre de usuario será visible para otros usuarios',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa un nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Acerca de ti',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        helperText: 'Máximo 150 caracteres',
                      ),
                      maxLines: 3,
                      maxLength: 150,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fecha de nacimiento
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _fechaNacimiento == null
                                  ? 'Selecciona tu fecha de nacimiento'
                                  : DateFormat('dd/MM/yyyy').format(_fechaNacimiento!),
                              style: TextStyle(
                                color: _fechaNacimiento == null
                                    ? Colors.grey
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: _fechaNacimiento == null ? Colors.grey : Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_fechaNacimiento != null && !_validarEdadMinima())
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, left: 12.0),
                        child: Text(
                          'Debes tener al menos 13 años',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Género
                    DropdownButtonFormField<String>(
                      value: _generoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Género *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: _opcionesGenero.map((String genero) {
                        return DropdownMenuItem<String>(
                          value: genero,
                          child: Text(genero),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _generoSeleccionado = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecciona una opción';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _guardarPerfil,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Guardar Cambios'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _cancelarCambios,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}