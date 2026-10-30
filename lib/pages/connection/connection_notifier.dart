import 'package:flutter_riverpod/legacy.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/l10n/l10n_static.dart';
import 'package:random_mu/pages/connection/connection_state.dart';

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  ConnectionNotifier() : super(ConnectionState());

  Future<bool> validateConnection(
      String serverUrl, String username, String password) async {
    state = ConnectionState(isLoading: true);

    try {
      // Validate URL format
      final uri = Uri.parse(serverUrl);
      if (!uri.isAbsolute) {
        throw Exception(appL10n.invalidServerUrl);
      }

      // For demonstration, we'll throw an error if any field is empty
      if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
        throw Exception(appL10n.allFieldsRequired);
      }

      final client = SubsonicClient(
          baseUrl: serverUrl, username: username, password: password);
      final ping = await client.ping();
      if (!ping) {
        throw ("Error connecting to server");
      }
      // Pass the validate state
      state = ConnectionState();
      return ping;
      // Handle successful connection here (e.g., navigation)
    } catch (e) {
      state = ConnectionState(error: e.toString());
      return false;
    }
  }
}
