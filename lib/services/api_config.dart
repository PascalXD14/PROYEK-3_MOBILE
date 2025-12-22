class ApiConfig {
  static const String baseUrl = 'http://192.168.1.4:8000/api';

  // MIDTRANS CONFIG (TAMBAHKAN KODE INI)
  static const String midtransClientKey = "SB-Mid-client-gdbkHN9762-zrf0a";
  static const String midtransMerchantBaseUrl =
      "https://nonnatty-nonprofitablely-haley.ngrok-free.dev/";

  static Uri endpoint(String path) => Uri.parse('$baseUrl/$path');

  static String get origin {
    final i = baseUrl.indexOf('/api');
    return i == -1 ? baseUrl : baseUrl.substring(0, i);
  }

  static String toAbsolute(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    if (pathOrUrl.startsWith('/')) return '$origin$pathOrUrl';
    return '$origin/$pathOrUrl';
  }
}
