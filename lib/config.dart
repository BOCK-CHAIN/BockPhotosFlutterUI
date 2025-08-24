class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'postgresql://neondb_owner:npg_7yI0UXzSanWs@ep-flat-cake-ad7etjbq-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require',
  );
}