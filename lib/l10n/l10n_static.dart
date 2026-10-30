import 'dart:ui';

import 'package:random_mu/l10n/generated/app_localizations.dart';

/// Translations without a [BuildContext].
///
/// Used where there is no widget tree: the Android Auto browse tree labels and
/// the download notifications. It follows the device locale and falls back to
/// English when the language is not translated.
AppLocalizations get appL10n {
  final locale = PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales
      .any((item) => item.languageCode == locale.languageCode);
  return lookupAppLocalizations(
    supported ? Locale(locale.languageCode) : const Locale('en'),
  );
}
