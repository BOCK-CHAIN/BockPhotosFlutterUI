class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // If your S3 bucket is public (or fronted by CDN), set this to serve images
  // Example: https://your-bucket.s3.amazonaws.com
  static const String publicBucketBaseUrl = String.fromEnvironment(
    'PUBLIC_BUCKET_BASE_URL',
    defaultValue: '',
  );
}