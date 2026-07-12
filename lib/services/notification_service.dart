import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ─── Başlat ──────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onTap,
    );

    _initialized = true;
  }

  // ─── İzin iste ───────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final android = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (ios ?? false) || (android ?? false);
  }

  // ─── Eşleşme bildirimi ────────────────────────────────────────
  static Future<void> showMatchNotification({
    required String matchedUserName,
    required String matchId,
  }) async {
    await _plugin.show(
      _notifId('match', matchId),
      'Yeni eşleşme!',
      '$matchedUserName ile eşleştin, ilk mesajı gönder!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'match_channel',
          'Eşleşmeler',
          channelDescription: 'Yeni eşleşme bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          color: kPrimary,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'match',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'match:$matchId',
    );
  }

  // ─── Mesaj bildirimi ──────────────────────────────────────────
  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String matchId,
  }) async {
    await _plugin.show(
      _notifId('msg', matchId),
      senderName,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'message_channel',
          'Mesajlar',
          channelDescription: 'Yeni mesaj bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          color: kSuccess,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(message),
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'message',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'messages',
        ),
      ),
      payload: 'message:$matchId',
    );
  }

  // ─── Beğeni bildirimi ─────────────────────────────────────────
  static Future<void> showLikeNotification() async {
    await _plugin.show(
      1000,
      'Birisi seni beğendi',
      'Profilini beğenen biri var, keşfet!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'like_channel',
          'Beğeniler',
          channelDescription: 'Beğeni bildirimleri',
          importance: Importance.defaultImportance,
          color: const Color(0xFFD4537E),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'like',
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: 'like',
    );
  }

  // ─── Tüm bildirimleri temizle ─────────────────────────────────
  static Future<void> clearAll() async {
    await _plugin.cancelAll();
  }

  // ─── Badge sayacını sıfırla (iOS) ────────────────────────────
  static Future<void> resetBadge() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.getActiveNotifications()
        .then((_) async {
      await _plugin.cancelAll();
    });
  }

  // ─── Supabase Realtime ile otomatik bildirim ──────────────────
  static void listenForNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Yeni eşleşme dinle
    Supabase.instance.client
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('matched_at')
        .listen((matches) async {
      for (final match in matches) {
        final isNew = _isRecentlyCreated(match['matched_at']);
        if (!isNew) continue;
        final otherId = match['user1_id'] == userId
            ? match['user2_id']
            : match['user1_id'];
        final other = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', otherId)
            .single();
        await showMatchNotification(
          matchedUserName: other['name'] ?? 'Birisi',
          matchId: match['id'],
        );
      }
    });

    // Yeni mesaj dinle
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('sent_at')
        .listen((messages) async {
      for (final msg in messages) {
        if (msg['sender_id'] == userId) continue;
        if (!_isRecentlyCreated(msg['sent_at'])) continue;
        if (msg['is_read'] == true) continue;

        final sender = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', msg['sender_id'])
            .single();

        await showMessageNotification(
          senderName: sender['name'] ?? 'Birisi',
          message: msg['content'] ?? '',
          matchId: msg['match_id'],
        );
      }
    });
  }

  // ─── Bildirime dokunulduğunda ─────────────────────────────────
  static void _onTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    debugPrint('Bildirime tıklandı: $payload');
    // TODO: navigatorKey ile ilgili ekrana yönlendir
    // payload 'match:ID' veya 'message:ID' formatında
  }

  static bool _isRecentlyCreated(String? dateStr) {
    if (dateStr == null) return false;
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inSeconds < 5;
  }

  static int _notifId(String type, String id) {
    return ('${type}_$id'.hashCode).abs() % 100000;
  }
}
