import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String _apiKey = 'e2a0016b0f875e34a2b02049ffe8ac9e';

  Future<List<dynamic>> fetchMovieReviews(int movieId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$movieId/reviews?api_key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<List<dynamic>> fetchMovies() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load movies');
    }
  }

  Future<List<dynamic>> fetchTVShows() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tv/popular?api_key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load TV shows');
    }
  }

  // Obtener lista de géneros de películas
  Future<Map<int, String>> fetchMovieGenres() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/genre/movie/list?api_key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final Map<int, String> genres = {};
      for (var genre in data['genres']) {
        genres[genre['id']] = genre['name'];
      }
      return genres;
    } else {
      throw Exception('Failed to load movie genres');
    }
  }

  // Obtener lista de géneros de series TV
  Future<Map<int, String>> fetchTVGenres() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/genre/tv/list?api_key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final Map<int, String> genres = {};
      for (var genre in data['genres']) {
        genres[genre['id']] = genre['name'];
      }
      return genres;
    } else {
      throw Exception('Failed to load TV genres');
    }
  }

  // Obtener películas populares con sus géneros
  Future<List<dynamic>> fetchMoviesWithGenres() async {
    final movies = await fetchMovies();
    final genreMap = await fetchMovieGenres();
    
    for (var movie in movies) {
      final List<dynamic> genreIds = movie['genre_ids'];
      final List<String> genreNames = genreIds
          .map((id) => genreMap[id] ?? 'Unknown')
          .toList();
      movie['genre_names'] = genreNames;
    }
    
    return movies;
  }

  // Obtener series populares con sus géneros
  Future<List<dynamic>> fetchTVShowsWithGenres() async {
    final shows = await fetchTVShows();
    final genreMap = await fetchTVGenres();
    
    for (var show in shows) {
      final List<dynamic> genreIds = show['genre_ids'];
      final List<String> genreNames = genreIds
          .map((id) => genreMap[id] ?? 'Unknown')
          .toList();
      show['genre_names'] = genreNames;
    }
    
    return shows;
  }

  // Obtener detalles de una película específica con géneros
  Future<Map<String, dynamic>> fetchMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey&append_to_response=credits,videos'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Los géneros ya vienen incluidos en el detalle como 'genres'
      return data;
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  // Obtener detalles de una serie específica con géneros
  Future<Map<String, dynamic>> fetchTVShowDetails(int tvId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tv/$tvId?api_key=$_apiKey&append_to_response=credits,videos'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Los géneros ya vienen incluidos en el detalle como 'genres'
      return data;
    } else {
      throw Exception('Failed to load TV show details');
    }
  }

  Future<List<dynamic>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=$query'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to search movies');
    }
  }

  Future<List<dynamic>> searchTVShows(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search/tv?api_key=$_apiKey&query=$query'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to search TV shows');
    }
  }

  Future<List<dynamic>> fetchMoviesByGenre(int genreId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/discover/movie?api_key=$_apiKey&with_genres=$genreId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to fetch movies by genre');
    }
  }

  Future<List<dynamic>> fetchTVShowsByGenre(int genreId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/discover/tv?api_key=$_apiKey&with_genres=$genreId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to fetch TV shows by genre');
    }
  }

  // Obtener imagen de fondo de una película o serie
  String getBackdropUrl(String? backdropPath) {
    if (backdropPath != null) {
      return 'https://image.tmdb.org/t/p/w780$backdropPath'; // Resolución adecuada para fondos
    } else {
      return 'https://via.placeholder.com/780x439.png?text=No+Image+Available'; // Fondo por defecto
    }
  }
}
