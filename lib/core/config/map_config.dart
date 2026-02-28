import 'package:flutter/material.dart';

class MapConfig {
  // Google Maps API Key - Replace with your actual API key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Default map settings
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 20.0;
  
  // Default location (Mumbai, India)
  static const double defaultLatitude = 19.0760;
  static const double defaultLongitude = 72.8777;
  
  // Marker colors for different types
  static Color getMarkerColor(String type) {
    switch (type) {
      case 'player':
        return Colors.blue;
      case 'umpire':
        return Colors.orange;
      case 'commentator':
        return Colors.purple;
      case 'ground':
        return Colors.green;
      case 'opponentTeam':
      case 'tournamentTeam':
        return Colors.red;
      default:
        return Colors.red;
    }
  }
  
  // Marker icons
  static String getMarkerIcon(String type) {
    switch (type) {
      case 'player':
        return 'assets/icons/marker_player.png';
      case 'umpire':
        return 'assets/icons/marker_umpire.png';
      case 'commentator':
        return 'assets/icons/marker_commentator.png';
      case 'ground':
        return 'assets/icons/marker_ground.png';
      case 'opponentTeam':
      case 'tournamentTeam':
        return 'assets/icons/marker_team.png';
      default:
        return 'assets/icons/marker_default.png';
    }
  }
}
