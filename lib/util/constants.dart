/// Uygulama genelinde kullanılan sabit değerler
class AppConstants {
  AppConstants._();

  // API URLs
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String osrmBaseUrl = 'http://localhost:5001';
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String openStreetMapCopyright =
      'https://openstreetmap.org/copyright';
  static const String authBaseUrl = 'http://localhost:3000/api';

  // User Agent
  static const String userAgentPackageName = 'com.emindundar.maptracking';

  // Map Defaults
  static const double defaultZoom = 15.0;
  static const double navigationZoom = 18.0;
  static const double positionTolerance = 0.005;
  static const double navigationStartToleranceMeters = 50.0;

  // Search
  static const int searchLimit = 3;
  static const int searchDebounceMs = 500;
  static const int minSearchQueryLength = 2;
}

/// Uygulama genelinde kullanılan text string'leri
class AppStrings {
  AppStrings._();

  // AppBar Titles
  static const String mapTitle = 'Harita';

  // Search
  static const String searchHint = 'Konum ara...';
  static const String startPointHint = 'Başlangıç noktası';
  static const String destinationHint = 'Varış noktası';
  static const String currentLocation = 'Mevcut Konum';
  static const String noResultsFound = 'Sonuç bulunamadı';
  static const String searchResultsTitle = 'Sonuçlar';
  static const String searching = 'Aranıyor...';
  static const String routeSummaryTitle = 'Rota hazır';

  // Buttons
  static const String closeButton = 'Kapat';
  static const String retryButton = 'Tekrar Kontrol Et';
  static const String appSettingsButton = 'Uygulama Ayarları';
  static const String locationSettingsButton = 'Konum Ayarları';

  // Permission Messages
  static const String checkingPermission = 'Konum izni kontrol ediliyor...';
  static const String permissionGranted = 'Konum izni verildi!';

  // Error Messages
  static const String serverError = 'Sunucu hatası:';
  static const String searchError =
      'Arama yapılamadı, internet bağlantınızı kontrol edin.';
  static const String routeError = 'Rota alınamadı, lütfen tekrar deneyin.';
  static const String navigationStartError =
      'Navigasyon başlatılamadı. Başlangıç noktasına yaklaşın.';
  static const String noRouteError =
      'Navigasyon başlatılamadı. Önce bir rota oluşturun.';

  // Auth Messages
  static const String authInvalidCredentials = 'E-posta veya şifre hatalı.';
  static const String authNetworkError =
      'İnternet bağlantısı yok. Lütfen tekrar deneyin.';
  static const String authServerError =
      'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
  static const String authTokenMissing = 'Oturum tokenı alınamadı.';
  static const String authUnexpectedError =
      'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';

  // Auth Labels
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String repeatPasswordLabel = 'Repeat Password';
  static const String registerButton = 'Register';
  static const String alreadyHaveAccount = 'I have account? ';
  static const String loginAction = 'Log in';

  // Auth Validation
  static const String emailRequired = 'Email zorunludur.';
  static const String passwordRequired = 'Şifre zorunludur.';
  static const String passwordMinLength = 'Şifre en az 6 karakter olmalıdır.';
  static const String passwordMismatch = 'Şifreler eşleşmiyor.';

  // Attribution
  static const String openStreetMapAttribution = 'OpenStreetMap contributors';
}
