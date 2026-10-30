import 'package:flutter/widgets.dart';
import 'package:random_mu/l10n/generated/app_localizations.dart';

export 'package:random_mu/l10n/generated/app_localizations.dart';

/// Shorthand for the app translations: `context.l10n.playAll`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
