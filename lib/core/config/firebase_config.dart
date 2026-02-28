import '../config/api_config.dart';

class FirebaseConfig {
  // Firebase project configuration
  static const String projectId = 'crick11-app';
  static const String messagingSenderId = '123456789';
  static const String appId = '1:123456789:android:abcdef';
  static const String apiKey = 'YOUR_FIREBASE_API_KEY';
  
  // Cloud messaging
  static const bool vapidKey = false;
  
  // Firebase storage
  static const String storageBucket = 'crick11-app.appspot.com';
  
  // Auth domain
  static const String authDomain = 'crick11-app.firebaseapp.com';
}
