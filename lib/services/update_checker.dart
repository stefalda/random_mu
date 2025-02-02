import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:random_mu/services/github_update_checker.dart';

void checkForUpdates(BuildContext context) async {
  // Check if it's android otherwise exit
  if (!Platform.isAndroid) {
    return;
  }

  final packageInfo = await PackageInfo.fromPlatform();

  final updateChecker = GithubUpdateChecker(
    owner: 'stefalda',
    repository: 'random_mu',
    currentVersion: packageInfo.version,
  );

  final updateInfo = await updateChecker.checkForUpdate();
  if (updateInfo != null && context.mounted) {
    await updateChecker.showUpdateDialog(context, updateInfo);
  }
}
