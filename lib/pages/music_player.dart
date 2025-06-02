import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/player_controls.dart';

class MusicPlayerScreen extends ConsumerWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerService = ref.read(playerServiceProvider);
    final audioPlayer = playerService.audioPlayer;
    final playerStateAsyncValue = ref.watch(playerStateProvider);
    if (playerStateAsyncValue.error != null) {
      debugPrint("Error: $playerStateAsyncValue");
    }
    return StreamBuilder<MediaItem?>(
      stream: audioPlayer.currentIndexStream.map((index) {
        if (index != null && index < audioPlayer.sequence.length) {
          return audioPlayer.sequence[index].tag as MediaItem;
        }
        return null;
      }),
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        if (mediaItem == null) {
          return Center(child: Text('No song is currently playing'));
        }
        playerService.updatePlayingInfo(mediaItem);
        return Padding(
          padding: EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine orientation
              bool isHorizontal =
                  MediaQuery.of(context).orientation == Orientation.landscape;

              return Flex(
                direction: isHorizontal ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: isHorizontal
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                crossAxisAlignment: isHorizontal
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.center,
                children: [
                  isHorizontal
                      ? Container()
                      : SizedBox(
                          height: 20,
                        ),
                  // Display album cover
                  if (mediaItem.artUri != null)
                    Image.network(
                      mediaItem.artUri.toString(),
                      width: isHorizontal
                          ? constraints.maxHeight * 0.8
                          : constraints.maxWidth * 0.7,
                      height: isHorizontal
                          ? constraints.maxHeight * 0.8
                          : constraints.maxWidth * 0.7,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(
                    width: isHorizontal ? 20 : 0,
                    height: isHorizontal ? 0 : 20,
                  ),
                  // Other elements as a sub-column/row
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isHorizontal
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.center,
                      mainAxisAlignment: isHorizontal
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        // Display song title
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            mediaItem.title,
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Display artist name
                        Text(
                          mediaItem.artist ?? 'Unknown Artist',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          mediaItem.album ?? 'Unknown Album',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 20),
                        PlayerControls(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );

        /*
        return Padding(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Display album cover
                if (mediaItem.artUri != null)
                  Image.network(
                    mediaItem.artUri.toString(),
                    width: 400,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                SizedBox(height: 20),
                // Display song title
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      mediaItem.title,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    )),
                SizedBox(height: 10),
                // Display artist name
                Text(
                  mediaItem.artist ?? 'Unknown Artist',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  mediaItem.album ?? 'Unknown Album',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                PlayerControls()
              ],
            ));*/
      },
    );
  }
}
