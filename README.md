
<img src="https://github.com/user-attachments/assets/93a2eea3-a7ea-4c69-a138-e6b81e66eb15" alt="rwlogo" width="600">


## 🌊 ¿Qué es Reviews Waves?

**Reviews Waves** es una plataforma web y móvil desarrollada en Flutter cuyo propósito es ser el sitio de referencia para reseñar, puntuar y compartir experiencias sobre películas, series y libros.  
El objetivo es crear una comunidad donde los usuarios puedan:

- Descubrir y buscar películas, series y libros.
- Escribir y leer reseñas de otros usuarios.
- Puntuar cada obra y ver las calificaciones de la comunidad.
- Compartir sus propias experiencias y recomendaciones.
- Publicar y difundir sus propios libros u obras literarias, permitiendo a otros usuarios descubrir creaciones originales.

La plataforma integra autenticación segura, perfiles personalizados y almacenamiento en la nube con Firebase, todo en una interfaz atractiva, intuitiva y adaptable a cualquier dispositivo.

---

## 🖼️ Logo

El logo de Reviews Waves representa una gran ola azul estilizada, inspirada en el arte japonés, con un barco navegando sobre ella y el nombre "Review Waves" en letras blancas. Refleja la idea de navegar entre olas de opiniones, experiencias y descubrimientos audiovisuales y literarios.

---

## 📚 Índice

- [🌊 ¿Qué es Reviews Waves?](#-qué-es-reviews-waves)
- [🖼️ Logo](#️-logo)
- [🚀 Características principales](#-características-principales)
- [🏗️ Arquitectura y tecnologías](#️-arquitectura-y-tecnologías)
- [📂 Estructura del proyecto](#-estructura-del-proyecto)
- [⚙️ Instalación y configuración](#️-instalación-y-configuración)
- [📝 Guía de uso y pantallas](#-guía-de-uso-y-pantallas)
- [👤 Gestión de usuarios y perfiles](#-gestión-de-usuarios-y-perfiles)
- [🔍 Búsqueda y filtrado](#-búsqueda-y-filtrado)
- [⭐ Gestión de favoritos](#-gestión-de-favoritos)
- [🎨 Temas y personalización](#-temas-y-personalización)
- [🛡️ Buenas prácticas y seguridad](#️-buenas-prácticas-y-seguridad)
- [🧑‍💻 Contribuciones](#-contribuciones)
- [📄 Licencia](#-licencia)
- [📬 Contacto](#-contacto)

---

## 🚀 Características principales

- **Búsqueda avanzada:** Encuentra películas, series y libros por nombre, género o popularidad.
- **Filtrado por género:** Visualiza contenido agrupado por géneros para toda clase de medios.
- **Detalle enriquecido:** Consulta sinopsis, géneros, imágenes y más detalles de cada título.
- **Sistema de reseñas:** Escribe, lee y comparte opiniones detalladas sobre cualquier contenido.
- **Calificaciones personalizadas:** Puntúa películas, series y libros según diferentes criterios.
- **Publicación de obras propias:** Comparte tus creaciones literarias con la comunidad.
- **Gestión de favoritos:** Guarda y accede rápidamente a tus películas, series y libros preferidos.
- **Autenticación segura:** Registro e inicio de sesión con email y contraseña, con verificación por correo electrónico.
- **Perfiles personalizados:** Añade nombre, usuario, descripción, género y fecha de nacimiento a tu perfil.
- **Persistencia en la nube:** Todos los datos de usuario, favoritos y reseñas se almacenan en Firebase Realtime Database.
- **Tema claro/oscuro:** Cambia el tema de la app en tiempo real.
- **Interfaz responsive:** Adaptada para móviles, tablets y escritorio.
- **Notificaciones y feedback:** Uso de Snackbars y diálogos para informar al usuario.
- **Código modular y escalable:** Separación clara de lógica, servicios y UI.

---

## 🏗️ Arquitectura y tecnologías

- **Flutter:** Framework principal para el desarrollo multiplataforma.
- **Firebase:**  
  - *Firebase Auth*: Autenticación de usuarios.
  - *Firebase Realtime Database*: Almacenamiento de perfiles, favoritos y reseñas.
  - *Firebase Storage*: Para almacenar contenido literario y portadas de libros.
- **The Movie Database (TMDb) API:** Fuente de datos de películas y series.
- **Google Books API:** Para información de libros publicados.
- **Paquetes destacados:**  
  `firebase_core`, `firebase_auth`, `firebase_database`, `firebase_storage`, `intl`, `logging`, `google_fonts`, `cached_network_image`, `shimmer`, `lottie`
- **Patrones de diseño:**  
  - Separación de lógica de negocio (servicios) y presentación (pantallas/widgets).
  - Uso de `FutureBuilder` y `StreamBuilder` para manejo reactivo de datos.

---

## 📂 Estructura del proyecto

```
rw/
├── lib/
│   ├── main.dart                # Punto de entrada principal
│   ├── api_service.dart         # Lógica para consumir la API de películas/series/libros
│   ├── detail_screen.dart       # Pantalla de detalle de contenido
│   ├── perfil_screen.dart       # Pantalla de perfil de usuario
│   ├── review_screen.dart       # Pantalla de creación y visualización de reseñas
│   ├── book_upload.dart         # Pantalla para subir obras propias
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
   - Asegúrate de que la base de datos, autenticación y storage estén habilitados en tu proyecto Firebase.

4. **Configura las APIs externas:**
   - Regístrate en [TMDb](https://www.themoviedb.org/) y obtén tu API Key.
   - Regístrate en [Google Cloud Platform](https://console.cloud.google.com/) para obtener acceso a la API de Google Books.
   - Añade tus API Keys en el archivo `api_service.dart`.

5. **Ejecuta la app:**
   ```sh
   flutter run
   ```

---

## 📝 Guía de uso y pantallas

### 1. **Pantalla principal**
- Visualiza carruseles de películas, series y libros populares.
- Explora contenido por género.
- Usa la barra de búsqueda para encontrar títulos específicos.

**Captura sugerida:**  
_Toma una captura de la pantalla principal mostrando los carruseles, la barra de búsqueda y los botones de filtro y perfil en la parte superior._

### 2. **Búsqueda y filtrado**
- Escribe en la barra superior para buscar por nombre.
- Usa el botón de filtro para seleccionar un género y ver solo ese tipo de contenido.
- Alterna entre películas, series y libros con el selector de categoría.

**Captura sugerida:**  
_Toma una captura del diálogo de filtro de géneros abierto y otra de los resultados de búsqueda mostrando una lista de contenido._

### 3. **Detalle de contenido**
- Haz clic en cualquier película, serie o libro para ver su información detallada.
- Consulta sinopsis, géneros, imagen y otros datos relevantes.
- Lee y escribe reseñas directamente desde esta pantalla.
- Otorga tu puntuación personal.

**Captura sugerida:**  
_Toma una captura de la pantalla de detalle mostrando la imagen, sinopsis, géneros y sección de reseñas._

### 4. **Creación de reseñas**
- Comparte tu opinión sobre películas, series o libros.
- Califica el contenido con un sistema de 5 estrellas.
- Añade etiquetas relevantes a tu reseña.
- Incluye imágenes o citas específicas (próximamente).

### 5. **Publicación de obras literarias**
- Sube tus propias creaciones literarias.
- Añade una portada, sinopsis y etiquetas.
- Define si tu obra es de acceso público o privado.
- Recibe comentarios y calificaciones de la comunidad.

### 6. **Gestión de favoritos**
- Marca películas, series y libros como favoritos para acceder a ellos rápidamente desde tu perfil.
- Organiza tus favoritos en colecciones personalizadas.

### 7. **Autenticación y perfiles**
- Regístrate con tu correo electrónico y verifica tu cuenta.
- Personaliza tu perfil con nombre, usuario, descripción, género y fecha de nacimiento.
- Añade tus preferencias de género para recibir recomendaciones personalizadas.
- Accede a tu perfil desde el menú de usuario.

### 8. **Tema claro/oscuro**
- Cambia el tema de la app desde el icono correspondiente en la barra superior.
- El tema se guarda en tus preferencias para futuras sesiones.

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
  - Visualización de favoritos, reseñas escritas y obras publicadas.
  - Estadísticas de actividad en la plataforma.

---

## 🔍 Búsqueda y filtrado

- **Búsqueda por nombre:**  
  - Resultados instantáneos usando las APIs correspondientes.
  - Sugerencias mientras escribes.

- **Filtrado por género:**  
  - Selecciona un género para ver solo películas, series o libros de ese tipo.
  - Combina varios géneros para una búsqueda más refinada.

- **Carruseles por género:**  
  - Explora contenido agrupado visualmente por género.
  - Descubre nuevas obras basadas en tus preferencias.

- **Filtros avanzados:**
  - Por año de publicación/estreno
  - Por calificación promedio
  - Por popularidad
  - Por idioma original

---

## ⭐ Gestión de favoritos

- **Marcado de favoritos:**
  - Guarda películas, series y libros como favoritos.
  - Organiza tus favoritos en colecciones personalizadas.
  - Comparte tus colecciones con amigos.

- **Listas personalizadas:**
  - Crea listas como "Para ver más tarde", "Recomendados", etc.
  - Añade notas personales a cada elemento.

- **Sincronización en la nube:**
  - Accede a tus favoritos desde cualquier dispositivo.
  - Recuperación automática al iniciar sesión.

---

## 🎨 Temas y personalización

- **Tema claro:**  
  - Colores suaves, fondo claro, textos oscuros.
  - Ideal para uso diurno y entornos luminosos.

- **Tema oscuro:**  
  - Fondo oscuro, textos claros, ideal para uso nocturno.
  - Reduce la fatiga visual en entornos con poca luz.

- **Cambio instantáneo:**  
  - Cambia el tema desde la barra superior en cualquier momento.
  - Preferencia de tema guardada para futuras sesiones.

- **Personalización de interfaz:** (próximamente)
  - Selección de fuentes
  - Tamaño de texto ajustable
  - Modos de visualización de contenido

---

## 🛡️ Buenas prácticas y seguridad

- **Autenticación segura:**  
  - Uso de Firebase Auth con verificación de email.
  - Protección contra ataques de fuerza bruta.

- **Validación de formularios:**  
  - Comprobación de contraseñas, emails y campos obligatorios.
  - Feedback inmediato al usuario durante la entrada de datos.

- **Gestión de errores:**  
  - Feedback claro al usuario ante cualquier error.
  - Registro de errores para análisis y mejora.

- **Persistencia segura:**  
  - Datos sensibles almacenados solo en Firebase.
  - Encriptación de información confidencial.

- **Código modular:**  
  - Separación de lógica, servicios y UI para facilitar el mantenimiento y escalabilidad.
  - Patrones de diseño optimizados para rendimiento.

- **Control de derechos de autor:**
  - Verificación de contenido subido por usuarios
  - Sistema de reporte de infracciones
  - Protección de obras originales

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

> _Reviews Waves es una plataforma en constante evolución donde puedes descubrir, reseñar y compartir tus experiencias con películas, series y libros, además de publicar tus propias creaciones literarias. ¡Tu feedback y colaboración son esenciales para seguir creciendo!_
---

> _Reviews Waves es una plataforma en constante evolución. ¡Tu feedback y colaboración son esenciales para seguir creciendo!_
