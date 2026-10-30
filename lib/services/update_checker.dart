import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:random_mu/services/github_update_checker.dart';

void checkForUpdates(BuildContext context) async {
  // Android only: the web build has no store package to update.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
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
