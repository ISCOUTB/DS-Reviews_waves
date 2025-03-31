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
}
