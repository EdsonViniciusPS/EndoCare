import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Serviço resiliente para registro e acompanhamento de identificadores FCM
/// (`firebase_messaging` 17+) nas plataformas suportadas.
class FcmTokenService {
  FcmTokenService(this._messaging) {
    if (_isPlatformSupported) {
      _registeredSub = _messaging.onRegistered.listen((token) {
        _lastRegisteredToken = token;
      });
    }
  }

  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _registeredSub;
  String? _lastRegisteredToken;

  bool get _isPlatformSupported {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  /// Último identificador FCM emitido na sessão atual (se disponível).
  String? get currentToken => _lastRegisteredToken;

  /// Stream de registros/atualizações de identificador FCM nas plataformas suportadas.
  Stream<String> get onRegistered {
    if (!_isPlatformSupported) {
      return const Stream<String>.empty();
    }
    return _messaging.onRegistered;
  }

  /// Solicita registro no FCM sem bloquear ou falhar caso permissões/APNS
  /// ainda não estejam ativos no dispositivo.
  Future<String?> registerAndGetTokenSafely() async {
    if (!_isPlatformSupported) return null;
    if (_lastRegisteredToken != null) return _lastRegisteredToken;

    try {
      final nextTokenFuture = _messaging.onRegistered.first.timeout(
        const Duration(seconds: 2),
      );
      await _messaging.register();
      final token = await nextTokenFuture;
      _lastRegisteredToken = token;
      return token;
    } catch (_) {
      return _lastRegisteredToken;
    }
  }

  /// Cancela o registro local de FCM ao sair da conta.
  Future<void> unregisterSafely() async {
    final previous = _lastRegisteredToken;
    _lastRegisteredToken = null;
    if (!_isPlatformSupported || previous == null) return;
    try {
      await _messaging.unregister();
    } catch (_) {
      // Silencioso para nunca impedir o logout.
    }
  }

  void dispose() {
    _registeredSub?.cancel();
  }
}
