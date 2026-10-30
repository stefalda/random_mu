import 'package:flutter/material.dart' hide ConnectionState;
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:random_mu/pages/connection/connection_notifier.dart';
import 'package:random_mu/pages/connection/connection_state.dart';
import 'package:random_mu/providers/subsonic_preferences_provider.dart';

// State notifier to handle the connection state

final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionState>(
  (ref) => ConnectionNotifier(),
);

class ConnectionPage extends ConsumerStatefulWidget {
  const ConnectionPage({super.key});

  @override
  ConsumerState<ConnectionPage> createState() => _SubsonicLoginScreenState();
}

class _SubsonicLoginScreenState extends ConsumerState<ConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved details into controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedDetails = ref.read(connectionDetailsProvider);
      _serverController.text = savedDetails.serverUrl;
      _usernameController.text = savedDetails.username;
      _passwordController.text = savedDetails.password;
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.connectTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: context.l10n.serverUrl,
                  hintText: 'https://your-server.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.pleaseEnterServerUrl;
                  }
                  try {
                    final uri = Uri.parse(value);
                    if (!uri.isAbsolute) {
                      return context.l10n.pleaseEnterValidUrl;
                    }
                  } catch (e) {
                    return context.l10n.invalidUrlFormat;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: context.l10n.username,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.pleaseEnterUsername;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: context.l10n.password,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.pleaseEnterPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (connectionState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    connectionState.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: connectionState.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final serverUrl = _serverController.text;
                          final username = _usernameController.text;
                          final password = _passwordController.text;

                          // Simulate connection attempt
                          final ping = await ref
                              .read(connectionProvider.notifier)
                              .validateConnection(
                                  serverUrl, username, password);
                          if (!ping) return;
                          // Save the details
                          await ref
                              .read(connectionDetailsProvider.notifier)
                              .saveConnectionDetails(
                                serverUrl: serverUrl,
                                username: username,
                                password: password,
                              );
                        }
                      },
                child: connectionState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.connect),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
