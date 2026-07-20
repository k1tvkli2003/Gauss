import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Publishes the two numbers the Android home-screen widget shows.
///
/// The widget is a mirror, never a source of pressure: it reports what was
/// charted today and how many concepts are due, and nothing else. Failure to
/// publish is silent — a stale widget must never disturb a study session.
class StatusWidgetBridge {
  const StatusWidgetBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.gauss.app/status_widget';

  final MethodChannel _channel;

  /// Android is the only target with a home-screen widget host.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> publish({required int chartedToday, required int due}) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('publishStatus', <String, int>{
        'chartedToday': chartedToday,
        'due': due,
      });
    } on PlatformException {
      // No widget placed, or the host refused the update.
    } on MissingPluginException {
      // Running against an engine without the channel (tests, other hosts).
    }
  }
}
