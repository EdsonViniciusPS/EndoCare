import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/app.dart';
import 'package:endocare/firebase_options.dart';

/// Handler em segundo plano para mensagens push do Firebase Cloud Messaging.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ativa cache offline do Firestore para resiliência e privacidade local.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (_) {
    // Algumas plataformas/ambientes web podem já ter inicializado settings.
  }

  // Configura listener de background do FCM nas plataformas móveis suportadas.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Ignora caso o serviço nativo não esteja disponível no simulador.
    }
  }

  runApp(
    const ProviderScope(
      child: EndoCareApp(),
    ),
  );
}
