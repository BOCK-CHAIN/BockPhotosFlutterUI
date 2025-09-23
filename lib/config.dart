class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://YOUR_EC2_IP_ADDRESS', // Replace YOUR_EC2_IP_ADDRESS with your actual EC2 IP
  );
}