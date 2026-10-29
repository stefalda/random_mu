import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/pages/artwork_image.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('artworkImageProvider', () {
    test('uses a file provider for downloaded artwork', () {
      final provider = artworkImageProvider(
        Uri.file('/data/user/0/app/app_flutter/offline_music/covers/x.img'),
      );

      expect(provider, isA<FileImage>());
    });

    test('uses a network provider for the server artwork', () {
      final provider = artworkImageProvider(
        Uri.parse('https://server/rest/getCoverArt.view?id=mf-1'),
      );

      expect(provider, isA<NetworkImage>());
    });

    test('is null without artwork', () {
      expect(artworkImageProvider(null), isNull);
    });
  });

  testWidgets('shows the fallback when there is no artwork', (tester) async {
    await tester.pumpWidget(_wrap(const ArtworkImage(
      uri: null,
      fallback: Icon(Icons.music_note),
    )));

    expect(find.byIcon(Icons.music_note), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('builds an image for remote artwork', (tester) async {
    await tester.pumpWidget(_wrap(ArtworkImage(
      uri: Uri.parse('https://server/rest/getCoverArt.view?id=mf-1'),
      fallback: const Icon(Icons.music_note),
    )));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
  });
}
