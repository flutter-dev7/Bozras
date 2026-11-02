import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/usecases/delete_fcm_token_usecase.dart';
import '../../domain/usecases/save_fcm_token_usecase.dart';

class PushService {
  PushService({
    required SaveFcmTokenUseCase saveToken,
    required DeleteFcmTokenUseCase deleteToken,
  })  : _saveToken = saveToken,
        _deleteToken = deleteToken;

  final SaveFcmTokenUseCase _saveToken;
  final DeleteFcmTokenUseCase _deleteToken;

  bool _active = false;
  bool _listening = false;
  String? _token;

  void Function(String orderId)? _onOpenOrder;
  void Function(RemoteMessage message)? _onForeground;

  static String? orderIdOf(RemoteMessage message) {
    final value = message.data['orderId'];

    return value is String && value.isNotEmpty ? value : null;
  }

  Future<void> start({
    required void Function(String orderId) onOpenOrder,
    required void Function(RemoteMessage message) onForeground,
  }) async {
    _active = true;
    _onOpenOrder = onOpenOrder;
    _onForeground = onForeground;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    final token = await messaging.getToken();

    if (token != null) await _register(token);

    if (!_listening) {
      _listening = true;

      messaging.onTokenRefresh.listen((value) {
        if (_active) _register(value);
      });
      FirebaseMessaging.onMessage.listen((message) => _onForeground?.call(message));
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
    }

    final initial = await messaging.getInitialMessage();

    if (initial != null) _open(initial);
  }

  /// Вызывать до выхода из аккаунта, пока токен доступа ещё действует.
  Future<void> stop() async {
    _active = false;

    final token = _token;
    _token = null;

    try {
      if (token != null) {
        await _deleteToken(token).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('FCM token delete failed: $e');
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('FCM local token delete failed: $e');
    }
  }

  Future<void> _register(String token) async {
    _token = token;

    if (kDebugMode) debugPrint('FCM token: $token');

    try {
      await _saveToken(token);
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  void _open(RemoteMessage message) {
    final id = orderIdOf(message);

    if (id != null) _onOpenOrder?.call(id);
  }
}