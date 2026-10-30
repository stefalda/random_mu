import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:random_mu/l10n/playback_mode_l10n.dart';
import 'package:random_mu/main.dart';

/// The single control for the playback mode, shown in the title bar.
///
/// The icon matches the Android Auto action: the shuffle glyph when playback is
/// shuffled, the sequential (list + play) glyph when it follows the container
/// order. Tapping it flips the mode, which also reorders the live queue.
class PlaybackModeButton extends ConsumerWidget {
  const PlaybackModeButton({
    super.key,
    this.onChanged,
    this.showLabel = false,
  });

  /// Notified after the mode changed (e.g. to refresh a page).
  final VoidCallback? onChanged;

  /// Shows the mode name next to the icon.
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerService = ref.read(playerServiceProvider);

    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final mode = playerService.mode;
        final shuffled = mode.isShuffle;
        final theme = Theme.of(context);

        final button = IconButton(
          tooltip: context.l10n.playbackModeTooltip(mode.localizedLabel(context)),
          // Same glyph pair as the Android Auto mode action.
          icon: Icon(
            shuffled ? Icons.shuffle : Icons.playlist_play,
            color: shuffled ? theme.colorScheme.primary : null,
          ),
          onPressed: () async {
            await playerService.toggleMode();
            onChanged?.call();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 1200),
                  content: Text(
                    playerService.mode.localizedPlaybackMessage(context),
                  ),
                ),
              );
          },
        );

        if (!showLabel) return button;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            Text(
              mode.localizedLabel(context),
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
