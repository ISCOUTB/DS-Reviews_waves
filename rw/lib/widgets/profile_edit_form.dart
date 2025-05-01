import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ProfileEditForm extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;

  const ProfileEditForm({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _usuarioController;
  late TextEditingController _descripcionController;
  late TextEditingController _fechaNacimientoController;
  String? _selectedGender;
  DateTime? _selectedDate;

  final List<String> _genderOptions = [
    'Masculino',
    'Femenino',
    'No binario',
    'Prefiero no decir'
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.userData['fullName'] ?? '');
    _usuarioController = TextEditingController(text: widget.userData['username'] ?? '');
    _descripcionController = TextEditingController(text: widget.userData['bio'] ?? '');
    _fechaNacimientoController = TextEditingController(text: widget.userData['birthDate'] ?? '');
    _selectedGender = widget.userData['gender'];

    // Intentar parsear la fecha si existe
    if (widget.userData['birthDate'] != null) {
      try {
        _selectedDate = DateFormat('dd/MM/yyyy').parse(widget.userData['birthDate']);
      } catch (e) {
        // Si no se puede parsear, dejamos _selectedDate como null
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _descripcionController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDatePickerSheet(),
    );
  }

  Widget _buildDatePickerSheet() {
    final DateTime today = DateTime.now();
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = DateTime(today.year - 10, today.month, today.day);
    
    DateTime focusedDay = _selectedDate ?? DateTime(today.year - 20, today.month, today.day);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selecciona tu fecha de nacimiento',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Calendario
          StatefulBuilder(
            builder: (context, setModalState) {
              return TableCalendar(
                firstDay: firstDate,
                lastDay: lastDate,
                focusedDay: focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setModalState(() {
                    _selectedDate = selectedDay;
                    focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  focusedDay = focusedDay;
                },
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          // Botones de acción
          Expanded(child: Container()),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_selectedDate != null) {
                  setState(() {
                    _fechaNacimientoController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
                  });
                }
                Navigator.pop(context);
              },
              child: Text(
                'Confirmar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Información Personal',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(
            begin: -0.2,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutQuad,
          ),
          
          const SizedBox(height: 24),
          
          // Campo de nombre completo
          _buildTextField(
            controller: _nombreController,
            label: 'Nombre completo',
            hint: 'Ingresa tu nombre completo',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Campo de nombre de usuario
          _buildTextField(
            controller: _usuarioController,
            label: 'Nombre de usuario',
            hint: '@usuario',
            icon: Icons.alternate_email,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un nombre de usuario';
              }
              if (value.length < 3) {
                return 'El nombre de usuario debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Campo de fecha de nacimiento
          _buildDateField(
            controller: _fechaNacimientoController,
            label: 'Fecha de nacimiento',
            hint: 'DD/MM/AAAA',
            icon: Icons.calendar_today,
          ),
          
          const SizedBox(height: 16),
          
          // Campo de género
          _buildDropdownField(
            label: 'Género',
            value: _selectedGender,
            items: _genderOptions,
            hint: 'Selecciona tu género',
            icon: Icons.person_outline,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Campo de descripción
          _buildTextField(
            controller: _descripcionController,
            label: 'Sobre mí',
            hint: 'Cuéntanos sobre ti...',
            icon: Icons.description,
            maxLines: 4,
          ),
          
          const SizedBox(height: 32),
          
          // Botón de guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Preparar datos actualizados
                  Map<String, dynamic> updatedData = {
                    'fullName': _nombreController.text,
                    'username': _usuarioController.text,
                    'bio': _descripcionController.text,
                    'birthDate': _fechaNacimientoController.text,
                    'gender': _selectedGender,
                  };
                  
                  widget.onSave(updatedData);
                }
              },
              child: Text(
                'Guardar cambios',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeOutQuad,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
      ),
      validator: validator,
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 400.ms,
      delay: 100.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: _showDatePicker,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[100],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona tu fecha de nacimiento';
            }
            return null;
          },
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 400.ms,
      delay: 200.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
      ),
      hint: Text(hint),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona una opción';
        }
        return null;
      },
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 400.ms,
      delay: 300.ms,
      curve: Curves.easeOutQuad,
    );
  }
}