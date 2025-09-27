class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://YOUR_EC2_IP_ADDRESS', // Replace YOUR_EC2_IP_ADDRESS with your actual EC2 IP
  );

  // If your S3 bucket is public (or fronted by CDN), set this to serve images
  // Example: https://your-bucket.s3.amazonaws.com
  static const String publicBucketBaseUrl = String.fromEnvironment(
    'PUBLIC_BUCKET_BASE_URL',
    defaultValue: '',
  );
}