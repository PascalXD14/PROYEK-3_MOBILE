class ApiConfig {
  static const String baseUrl = 'http://192.168.1.17:8000/api';

  static Uri endpoint(String path) => Uri.parse('$baseUrl/$path');

  // Origin tanpa "/api"
  static String get origin {
    final i = baseUrl.indexOf('/api');
    return i == -1 ? baseUrl : baseUrl.substring(0, i);
  }

  /// Ubah path relatif ("/storage/..") jadi URL absolut.
  static String toAbsolute(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    if (pathOrUrl.startsWith('/')) return '$origin$pathOrUrl';
    return '$origin/$pathOrUrl';
  }
}
