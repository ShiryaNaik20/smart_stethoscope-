class AppConfig {
  static const String esp32Ip  = "192.168.1.9"; // ← your IP from Serial Monitor
  static const String flaskUrl = "https://actinally-unapperceived-isla.ngrok-free.dev";
      // static const String flaskUrl ="https://appointments-blog-vid-alexander.trycloudflare.com";
      
  static const int targetSamples = 20000; // 5 sec × 4000 Hz
  static const int displayWindow = 512;
}

