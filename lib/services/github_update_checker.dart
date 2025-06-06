import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GithubUpdateChecker {
  final String owner;
  final String repository;
  final String currentVersion;
  static const String _lastCheckKey = 'last_update_check';

  GithubUpdateChecker({
    required this.owner,
    required this.repository,
    required this.currentVersion,
  });

  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // Check if we should check for updates (not more than once per day)
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      //day - Currently an hour for debug...
      if (now - lastCheck < const Duration(hours: 1).inMilliseconds) {
        return null;
      }

      // Update last check time
      await prefs.setInt(_lastCheckKey, now);

      // Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/$owner/$repository/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');

        // Compare versions
        if (_isNewerVersion(latestVersion, currentVersion)) {
          // Find the APK asset
          final assets = List<Map<String, dynamic>>.from(data['assets']);
          final apkAsset = assets.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => {},
          );

          if (apkAsset.isNotEmpty) {
            return {
              'version': latestVersion,
              'description': data['body'],
              'downloadUrl': apkAsset['browser_download_url'],
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }

  bool _isNewerVersion(String latest, String current) {
    List<int> parseVersionParts(String version) {
      String core = version.split('+').first;
      return core.split('.').map(int.parse).toList();
    }

    int parseBuild(String version) {
      return version.contains('+')
          ? int.tryParse(version.split('+')[1]) ?? 0
          : 0;
    }

    List<int> latestParts = parseVersionParts(latest);
    List<int> currentParts = parseVersionParts(current);

    int maxLength = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (int i = 0; i < maxLength; i++) {
      int latestPart = i < latestParts.length ? latestParts[i] : 0;
      int currentPart = i < currentParts.length ? currentParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    // If MAJOR.MINOR.PATCH are equal, compare build metadata
    int latestBuild = parseBuild(latest);
    int currentBuild = parseBuild(current);

    return latestBuild > currentBuild;
  }

  Future<void> showUpdateDialog(
      BuildContext context, Map<String, dynamic> updateInfo) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A new version ${updateInfo['version']} is available.'),
              const SizedBox(height: 8),
              Text(updateInfo['description']),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Later'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Update'),
            onPressed: () async {
              final url = Uri.parse(updateInfo['downloadUrl']);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
