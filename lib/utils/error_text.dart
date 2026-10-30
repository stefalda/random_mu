import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:random_mu/l10n/l10n.dart';

/// Turns an exception into a short, localized sentence.
///
/// Socket and timeout failures are the common case on a phone (no network, a
/// server that stopped answering), and Subsonic API messages are meaningful on
/// their own, so they are kept as the detail.
String describeError(BuildContext context, Object? error) =>
    describeErrorFor(context.l10n, error);

/// Same as [describeError] but takes the translations directly, for code that
/// runs after an `await` and must not touch the [BuildContext].
String describeErrorFor(AppLocalizations l10n, Object? error) {
  if (error == null) return l10n.errorUnexpected;

  if (error is TimeoutException) return l10n.errorTimeout;

  final text = error.toString();
  final lower = text.toLowerCase();

  if (error is SocketException ||
      error is http.ClientException ||
      lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('no address associated') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection closed') ||
      lower.contains('failed to fetch')) {
    return l10n.errorNoConnection;
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return l10n.errorTimeout;
  }

  final status = RegExp(r'(?:status code|code)[:\s]+(\d{3})').firstMatch(lower);
  if (status != null) return l10n.errorServer(status.group(1)!);
  if (lower.contains('failed to make request')) {
    final digits = RegExp(r'(\d{3})').firstMatch(lower);
    return digits != null
        ? l10n.errorServer(digits.group(1)!)
        : l10n.errorNoConnection;
  }

  final detail = text.replaceFirst('Exception: ', '').trim();
  if (detail.isEmpty) return l10n.errorUnexpected;
  return l10n.errorWithDetail(
    detail.length > 140 ? '${detail.substring(0, 140)}…' : detail,
  );
}
