import 'package:flutter/widgets.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:random_mu/services/playback_mode.dart';

extension PlaybackModeL10n on PlaybackMode {
  /// Localized name of the mode ("Sequential" / "Shuffled").
  String localizedLabel(BuildContext context) =>
      isShuffle ? context.l10n.modeShuffled : context.l10n.modeSequential;

  /// Localized sentence used in snackbars.
  String localizedPlaybackMessage(BuildContext context) =>
      isShuffle ? context.l10n.playbackShuffled : context.l10n.playbackSequential;
}
