class AppConstants {
  AppConstants._();

  // Supabase
  static const String supabaseUrl = 'https://yclrizfepzfutwusgheu.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljbHJpemZlcHpmdXR3dXNnaGV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MzEzMjAsImV4cCI6MjA5MjQwNzMyMH0.n3jQdsq_IB6TURP5vQ0Oam1QuId9MMWAOXUboSuWO0Y';

  // AWS S3
  static const String s3BucketName = 'yapp-media-production';
  static const String s3Region = 'ap-south-1';
  static const String s3BaseUrl = 'https://$s3BucketName.s3.$s3Region.amazonaws.com';

  // Edge Function URLs
  static const String generateUploadUrlEndpoint = '$supabaseUrl/functions/v1/generate-upload-url';
  static const String getPlaybackUrlEndpoint = '$supabaseUrl/functions/v1/get-playback-url';
  static const String processAudioEndpoint = '$supabaseUrl/functions/v1/process-audio';
  static const String createYapEndpoint = '$supabaseUrl/functions/v1/create-yap';
  static const String deletePostEndpoint = '$supabaseUrl/functions/v1/delete-post';
  static const String deleteYapEndpoint = '$supabaseUrl/functions/v1/delete-yap';

  // Voice limits
  static const int maxYapDurationSeconds = 60;
  static const int maxReplyDurationSeconds = 30;

  // Audio specs
  static const int audioSampleRate = 48000;
  static const int audioBitRate = 48000;
  static const int audioChannels = 1;

  // Feed
  static const int feedPageSize = 20;

  // App
  static const String appName = 'Yapp';
}
