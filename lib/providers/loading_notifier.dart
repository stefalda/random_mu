import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingNotifier extends StateNotifier<bool> {
  LoadingNotifier() : super(false);

  void setLoading(bool value) {
    state = value;
  }
}
