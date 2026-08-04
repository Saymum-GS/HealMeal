import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories.dart';
import 'utils.dart';
import 'services/groq_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);

  // Repositories
  getIt.registerLazySingleton(() => ProductRepository());
  getIt.registerLazySingleton(() => OrderRepository());
  getIt.registerLazySingleton(() => UserRepository());

  getIt.registerLazySingleton(() => SuggestionRepository());
  getIt.registerLazySingleton(() => LabRepository());
  getIt.registerLazySingleton(() => LabTestRepository());
  getIt.registerLazySingleton(() => ChatRepository());
  getIt.registerLazySingleton(() => SettingsRepository());
  getIt.registerLazySingleton(() => ReviewRepository());
  getIt.registerLazySingleton(() => SupportRepository());
  getIt.registerLazySingleton(() => CategoryRepository());
  getIt.registerLazySingleton(() => AddressRepository());
  getIt.registerLazySingleton(() => SearchHistoryRepository());
  getIt.registerLazySingleton(() => ArticleRepository());

  getIt.registerLazySingleton(() => PrescriptionRepository());

  // Services
  getIt.registerLazySingleton(() => GroqService());
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      // Local Notifications Init
      const androidInit = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications.initialize(settings: initSettings);

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');

        String? token = await _messaging.getToken();
        if (token != null) {
          if (kDebugMode) debugPrint('FCM Token: $token');
          final userId = AppSession.userId;
          if (userId != null) {
            final prefs = await SharedPreferences.getInstance();
            final cachedToken = prefs.getString('fcm_token');

            if (cachedToken != token) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'fcmToken': token});
              await prefs.setString('fcm_token', token);
            }
          }
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'Received foreground message: ${message.notification?.title}',
          );
          if (message.notification != null) {
            showLocalNotification(
              title: message.notification!.title ?? 'New Message',
              body: message.notification!.body ?? '',
            );
          }
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint(
            'App opened from notification: ${message.notification?.title}',
          );
        });
      } else {
        debugPrint('User declined notification permission');
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'healmeal_channel_id',
        'HealMeal Notifications',
        channelDescription: 'Notifications for orders and updates',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}
