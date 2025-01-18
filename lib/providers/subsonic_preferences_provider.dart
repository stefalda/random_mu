import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model class to represent connection details
class SubsonicConnectionDetails {
  final String serverUrl;
  final String username;
  final String password;

  const SubsonicConnectionDetails({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  bool isCompiled() {
    return serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
      };

  // Create from JSON for retrieval
  factory SubsonicConnectionDetails.fromJson(Map<String, dynamic> json) {
    return SubsonicConnectionDetails(
      serverUrl: json['serverUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  // Empty constructor for initial state
  factory SubsonicConnectionDetails.empty() {
    return const SubsonicConnectionDetails(
      serverUrl: '',
      username: '',
      password: '',
    );
  }
}

// Provider to manage connection details persistence
class ConnectionDetailsNotifier
    extends StateNotifier<SubsonicConnectionDetails> {
  final SharedPreferences _prefs;
  static const _prefsKey = 'subsonic_connection_details';

  ConnectionDetailsNotifier(this._prefs)
      : super(SubsonicConnectionDetails.empty()) {
    // Load saved details when initialized
    loadSavedDetails();
  }

  Future<void> loadSavedDetails() async {
    final savedJson = _prefs.getString(_prefsKey);
    if (savedJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(savedJson) as Map,
        );
        state = SubsonicConnectionDetails.fromJson(json);
      } catch (e) {
        debugPrint('Error loading saved connection details: $e');
        // If there's an error loading, keep the empty state
      }
    }
  }

  Future<void> saveConnectionDetails({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final details = SubsonicConnectionDetails(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    try {
      // Save to SharedPreferences
      await _prefs.setString(
        _prefsKey,
        jsonEncode(details.toJson()),
      );
      // Update state
      state = details;
    } catch (e) {
      debugPrint('Error saving connection details: $e');
      rethrow;
    }
  }

  Future<void> clearSavedDetails() async {
    try {
      await _prefs.remove(_prefsKey);
      state = SubsonicConnectionDetails.empty();
    } catch (e) {
      debugPrint('Error clearing connection details: $e');
      rethrow;
    }
  }
}

// Provider for connection details
final connectionDetailsProvider =
    StateNotifierProvider<ConnectionDetailsNotifier, SubsonicConnectionDetails>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ConnectionDetailsNotifier(prefs);
});
