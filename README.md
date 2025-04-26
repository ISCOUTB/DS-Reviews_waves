![Imagen de WhatsApp 2025-03-21 a las 11 38 33_a4c9ae09](https://github.com/user-attachments/assets/27fca6f7-1889-45e3-aa38-6467eab3bba0)# Reviews Waves

![Logo Reviews Waves](assets/readme/logo.jpg)


---

## 🌊 ¿Qué es Reviews Waves?

**Reviews Waves** es una plataforma social y moderna desarrollada en Flutter, que permite a los usuarios descubrir, buscar, reseñar y gestionar películas y series favoritas. Integra autenticación segura, perfiles personalizados y almacenamiento en la nube con Firebase, todo en una interfaz atractiva, intuitiva y adaptable a cualquier dispositivo.

---

## 🖼️ Logo

El logo de Reviews Waves representa una gran ola azul estilizada, inspirada en el arte japonés, con un barco navegando sobre ella y el nombre "Review Waves" en letras blancas. Refleja la idea de navegar entre olas de opiniones y descubrimientos audiovisuales.

---

## 📚 Índice

- [¿Qué es Reviews Waves?](#qué-es-reviews-waves)
- [Características principales](#características-principales)
- [Arquitectura y tecnologías](#arquitectura-y-tecnologías)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Instalación y configuración](#instalación-y-configuración)
- [Guía de uso y pantallas](#guía-de-uso-y-pantallas)
- [Gestión de usuarios y perfiles](#gestión-de-usuarios-y-perfiles)
- [Búsqueda y filtrado](#búsqueda-y-filtrado)
- [Gestión de favoritos](#gestión-de-favoritos)
- [Temas y personalización](#temas-y-personalización)
- [Buenas prácticas y seguridad](#buenas-prácticas-y-seguridad)
- [Contribuciones](#contribuciones)
- [Licencia](#licencia)
- [Contacto](#contacto)

---

## 🚀 Características principales

- **Búsqueda avanzada:** Encuentra películas y series por nombre, género o popularidad.
- **Filtrado por género:** Visualiza contenido agrupado por géneros, tanto para películas como para series.
- **Detalle enriquecido:** Consulta sinopsis, géneros, imágenes y más detalles de cada título.
- **Gestión de favoritos:** Guarda y accede rápidamente a tus películas y series preferidas.
- **Autenticación segura:** Registro e inicio de sesión con email y contraseña, con verificación por correo electrónico.
- **Perfiles personalizados:** Añade nombre, usuario, descripción, género y fecha de nacimiento a tu perfil.
- **Persistencia en la nube:** Todos los datos de usuario y favoritos se almacenan en Firebase Realtime Database.
- **Tema claro/oscuro:** Cambia el tema de la app en tiempo real.
- **Interfaz responsive:** Adaptada para móviles, tablets y escritorio.
- **Notificaciones y feedback:** Uso de Snackbars y diálogos para informar al usuario.
- **Código modular y escalable:** Separación clara de lógica, servicios y UI.

---

## 🏗️ Arquitectura y tecnologías

- **Flutter:** Framework principal para el desarrollo multiplataforma.
- **Firebase:**  
  - *Firebase Auth*: Autenticación de usuarios.
  - *Firebase Realtime Database*: Almacenamiento de perfiles y favoritos.
- **The Movie Database (TMDb) API:** Fuente de datos de películas y series.
- **Paquetes destacados:**  
  `firebase_core`, `firebase_auth`, `firebase_database`, `intl`, `logging`, `google_fonts`, `cached_network_image`, `shimmer`, `lottie`
- **Patrones de diseño:**  
  - Separación de lógica de negocio (servicios) y presentación (pantallas/widgets).
  - Uso de `FutureBuilder` y `StreamBuilder` para manejo reactivo de datos.

---

## 📂 Estructura del proyecto

```
rw/
├── lib/
│   ├── main.dart                # Punto de entrada principal
│   ├── api_service.dart         # Lógica para consumir la API de películas/series
│   ├── detail_screen.dart       # Pantalla de detalle de películas/series
│   ├── perfil_screen.dart       # Pantalla de perfil de usuario
│   ├── widgets/                 # Widgets reutilizables
│   └── ...                      # Otros archivos y pantallas
├── android/                     # Proyecto Android nativo
├── ios/                         # Proyecto iOS nativo
├── pubspec.yaml                 # Dependencias y configuración Flutter
└── README.md                    # Este archivo
```

---

## ⚙️ Instalación y configuración

1. **Clona el repositorio:**
   ```sh
   git clone https://github.com/tuusuario/reviews-waves.git
   cd reviews-waves/rw
   ```

2. **Instala las dependencias:**
   ```sh
   flutter pub get
   ```

3. **Configura Firebase:**
   - Descarga tu archivo `google-services.json` (Android) y/o `GoogleService-Info.plist` (iOS) desde la consola de Firebase.
   - Colócalos en las carpetas correspondientes (`android/app/` y `ios/Runner/`).
   - Asegúrate de que la base de datos y autenticación estén habilitadas en tu proyecto Firebase.

4. **Configura la API de TMDb:**
   - Regístrate en [TMDb](https://www.themoviedb.org/) y obtén tu API Key.
   - Añade tu API Key en el archivo `api_service.dart`.

5. **Ejecuta la app:**
   ```sh
   flutter run
   ```

---

## 📝 Guía de uso y pantallas

### 1. **Pantalla principal**
- Visualiza carruseles de películas y series populares.
- Explora contenido por género.
- Usa la barra de búsqueda para encontrar títulos específicos.

**Captura sugerida:**  
_Toma una captura de la pantalla principal mostrando los carruseles de películas y series populares, la barra de búsqueda y los botones de filtro y perfil en la parte superior._

### 2. **Búsqueda y filtrado**
- Escribe en la barra superior para buscar por nombre.
- Usa el botón de filtro para seleccionar un género y ver solo ese tipo de contenido.

**Captura sugerida:**  
_Toma una captura del diálogo de filtro de géneros abierto y otra de los resultados de búsqueda mostrando una lista de películas o series._

### 3. **Detalle de contenido**
- Haz clic en cualquier película o serie para ver su información detallada.
- Consulta sinopsis, géneros, imagen y otros datos relevantes.

**Captura sugerida:**  
_Toma una captura de la pantalla de detalle de una película o serie, mostrando la imagen, sinopsis, géneros y botones de acción._

### 4. **Gestión de favoritos**
- (Próximamente) Marca películas y series como favoritas para acceder a ellas rápidamente desde tu perfil.

**Captura sugerida:**  
_Cuando esté implementado, toma una captura de la lista de favoritos en el perfil del usuario._

### 5. **Autenticación y perfiles**
- Regístrate con tu correo electrónico y verifica tu cuenta.
- Personaliza tu perfil con nombre, usuario, descripción, género y fecha de nacimiento.
- Accede a tu perfil desde el menú de usuario.

**Captura sugerida:**  
_Toma una captura del formulario de registro y otra del perfil de usuario mostrando los datos personalizados._

### 6. **Tema claro/oscuro**
- Cambia el tema de la app desde el icono correspondiente en la barra superior.

**Captura sugerida:**  
_Toma dos capturas: una con el tema claro y otra con el tema oscuro, mostrando la misma pantalla para comparar._

---

## 👤 Gestión de usuarios y perfiles

- **Registro:**  
  - Formulario con campos para nombre completo, usuario, email, contraseña, fecha de nacimiento, género y descripción.
  - Verificación de correo electrónico obligatoria antes de completar el registro.
  - Almacenamiento seguro de datos en Firebase.

- **Inicio de sesión:**  
  - Autenticación con email y contraseña.
  - Feedback inmediato en caso de error o éxito.

- **Perfil de usuario:**  
  - Visualización y edición de datos personales.
  - (Próximamente) Visualización de favoritos y reseñas propias.

---

## 🔍 Búsqueda y filtrado

- **Búsqueda por nombre:**  
  - Resultados instantáneos usando la API de TMDb.
- **Filtrado por género:**  
  - Selecciona un género para ver solo películas o series de ese tipo.
- **Carruseles por género:**  
  - Explora contenido agrupado visualmente por género.

---

## ⭐ Gestión de favoritos

- (Próximamente)  
  - Guarda películas y series como favoritas.
  - Accede a tu lista de favoritos desde tu perfil.
  - Sincronización en la nube con Firebase.

---

## 🎨 Temas y personalización

- **Tema claro:**  
  - Colores suaves, fondo claro, textos oscuros.
- **Tema oscuro:**  
  - Fondo oscuro, textos claros, ideal para uso nocturno.
- **Cambio instantáneo:**  
  - Cambia el tema desde la barra superior en cualquier momento.

---

## 🛡️ Buenas prácticas y seguridad

- **Autenticación segura:**  
  - Uso de Firebase Auth con verificación de email.
- **Validación de formularios:**  
  - Comprobación de contraseñas, emails y campos obligatorios.
- **Gestión de errores:**  
  - Feedback claro al usuario ante cualquier error.
- **Persistencia segura:**  
  - Datos sensibles almacenados solo en Firebase.
- **Código modular:**  
  - Separación de lógica, servicios y UI para facilitar el mantenimiento y escalabilidad.

---

## 🧑‍💻 Contribuciones

¡Las contribuciones son bienvenidas!  
Puedes ayudar a mejorar Reviews Waves reportando bugs, sugiriendo nuevas funcionalidades o enviando pull requests.

1. Haz un fork del repositorio.
2. Crea una rama para tu feature o fix.
3. Haz tus cambios y escribe pruebas si es necesario.
4. Haz un pull request describiendo tus cambios.

---

## 📄 Licencia

Este proyecto es privado y no está destinado para distribución pública.  
Si deseas reutilizar el código, por favor contacta al autor.

---

## 📬 Contacto

¿Tienes dudas, sugerencias o quieres colaborar?  
Escríbeme a [tu-email@ejemplo.com](mailto:tu-email@ejemplo.com)

---

> _Reviews Waves es una plataforma en constante evolución. ¡Tu feedback y colaboración son esenciales para seguir creciendo!_
