class AppConfig {
  static const String supabaseUrl = "https://oglvgeblxdbcknwvcfmw.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9nbHZnZWJseGRiY2tud3ZjZm13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMzY1NjgsImV4cCI6MjA4NTcxMjU2OH0.TGPNralvnKyMtX3PkALkrro-dZ6-iQYGCmB7SBcPako";
  
  // CRITICAL: Change this to your PC's LAN IP if running on a physical device.
  // e.g. "http://192.168.1.50:3000/v1"
  // For Emulator: "http://10.0.2.2:3000/v1"
  static const String apiBaseUrl = "http://192.168.1.100:3000/v1"; 
  
  static const bool enableLogs = true;
}
