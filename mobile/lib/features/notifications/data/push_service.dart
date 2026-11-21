import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_bootstrap.dart';

/// Firebase Cloud Messaging for admin-sent announcements. Prayer and reminder
/// notifications are scheduled locally (see NotificationService) for reliability.
class PushService {
  static Future<void> sync(String uid) async {
    if (!Fb.ready || kIsWeb) return;
    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      await m.subscribeToTopic('all');
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final type = (snap.data()?['accountType'] as String?) == 'public' ? 'public' : 'personal';
      final other = type == 'public' ? 'personal' : 'public';
      await m.subscribeToTopic('type_$type');
      await m.unsubscribeFromTopic('type_$other');
    } catch (_) {}
  }
}
