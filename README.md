# Random Muu

Random Muu is a simple, yet powerful music player app written in Flutter. It
leverages the Subsonic API to provide a seamless music experience, allowing you
to quickly play random songs from various categories. The app supports quick
song selection with options such as:

- **All Random**
- **Random by Artist**
- **Random by Playlist**
- **Random by Favorites**

Currently, the app has been tested on **Web** and **Android** platforms, with
**Navidrome** as the Subsonic-compatible server.

## Features

- **Random Music Selection**: Get a random song from your library, or filter by
  artist, playlist, or favorites.
- **Subsonic API Integration**: Fully integrates with the Subsonic API
  (Navidrome supported).
- **Cross-Platform**: Currently tested on Web and Android.

## Setup and Installation

### Prerequisites

1. Flutter 3.x or later installed on your machine.
2. A running **Navidrome** instance or any compatible Subsonic server.
3. Access to your Subsonic server credentials (username and password).

### Clone the Repository

```bash
git clone https://github.com/stefalda/random-mu.git
cd random-mu
```

### Install Dependencies

Ensure you have the Flutter environment set up. Install the required
dependencies by running:

```bash
flutter pub get
```

### Configure Navidrome (or Subsonic) API

In the `lib` folder, navigate to the `config.dart` file and add your Subsonic
server URL, username, and password.

```dart
const String serverUrl = 'http://your-navidrome-server';
const String username = 'your-username';
const String password = 'your-password';
```

### Run the Application

For **Web**:

```bash
flutter run -d chrome
```

For **Android**:

```bash
flutter run -d android
```

### Features and Usage

- **All Random**: Play a random song from your entire music library.
- **Random by Artist**: Choose a random song from a specific artist.
- **Random by Playlist**: Select a random song from your playlists.
- **Random by Favorites**: Play a random song from your favorite tracks.

### Supported Platforms

- Web (Tested)
- Android (Tested)

## Contributing

If you'd like to contribute to the project, feel free to fork the repository and
submit a pull request. Please ensure that your code follows the existing coding
style and includes relevant tests if applicable.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file
for details.
