import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghanaserve/services/api_client.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };
}

final appNotificationsProvider =
    AsyncNotifierProvider<AppNotificationsNotifier, List<AppNotification>>(
  AppNotificationsNotifier.new,
);

class AppNotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  String? _userId;
  final ApiClient _api = ApiClient();

  @override
  Future<List<AppNotification>> build() async => const [];

  Future<void> loadForUser(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _userId == userId && state.hasValue) return;
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    final local = raw == null
        ? <AppNotification>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((item) =>
                AppNotification.fromJson(item as Map<String, dynamic>))
            .where((item) => !_sampleIds.contains(item.id))
            .toList();
    var decoded = local;
    try {
      final response = await _api.dio.get('/applications/notifications/');
      final payload = response.data is Map
          ? (response.data['results'] as List<dynamic>? ?? const [])
          : response.data as List<dynamic>;
      final remote = payload
          .map((item) =>
              AppNotification.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      final byId = {
        for (final item in [...local, ...remote]) item.id: item
      };
      decoded = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
    state = AsyncData(decoded);
    await _save(decoded);
  }

  Future<void> addNotification({
    required String userId,
    required String id,
    required String title,
    required String message,
  }) async {
    await loadForUser(userId);
    final next = [
      AppNotification(
        id: id,
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
      ..._current.where((item) => item.id != id),
    ];
    await _commit(next);
  }

  Future<void> markAsRead(String id) async {
    final remoteId = int.tryParse(id);
    if (remoteId != null) {
      try {
        await _api.dio.patch(
          '/applications/notifications/$remoteId/',
          data: {'is_read': true},
        );
      } catch (_) {
        return;
      }
    }
    final next = _current
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    await _commit(next);
  }

  Future<void> markAllAsRead() async {
    final failedRemoteIds = <String>{};
    for (final notification in _current) {
      final remoteId = int.tryParse(notification.id);
      if (remoteId == null) continue;
      try {
        await _api.dio.patch(
          '/applications/notifications/$remoteId/',
          data: {'is_read': true},
        );
      } catch (_) {
        failedRemoteIds.add(notification.id);
      }
    }
    await _commit(_current
        .map((item) => failedRemoteIds.contains(item.id)
            ? item
            : item.copyWith(isRead: true))
        .toList());
  }

  Future<void> clear(String id) async {
    final remoteId = int.tryParse(id);
    if (remoteId != null) {
      try {
        await _api.dio.delete('/applications/notifications/$remoteId/');
      } catch (_) {
        return;
      }
    }
    await _commit(_current.where((item) => item.id != id).toList());
  }

  Future<void> clearAll() async {
    final remaining = <AppNotification>[];
    for (final notification in _current) {
      final id = int.tryParse(notification.id);
      if (id == null) continue;
      try {
        await _api.dio.delete('/applications/notifications/$id/');
      } catch (_) {
        remaining.add(notification);
      }
    }
    await _commit(remaining);
  }

  List<AppNotification> get _current => state.valueOrNull ?? const [];

  Future<void> _commit(List<AppNotification> next) async {
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> _save(List<AppNotification> notifications) async {
    final userId = _userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId),
      jsonEncode(notifications.map((item) => item.toJson()).toList()),
    );
  }

  static const _sampleIds = {
    'passport-approved',
    'roadworthiness-expiring',
    'documents-required',
  };

  String _key(String userId) => 'app_notifications_$userId';
}

class NotificationPreferences {
  final bool sms;
  final bool email;

  const NotificationPreferences({this.sms = true, this.email = true});

  NotificationPreferences copyWith({bool? sms, bool? email}) =>
      NotificationPreferences(
        sms: sms ?? this.sms,
        email: email ?? this.email,
      );
}

final notificationPreferencesProvider = AsyncNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  String? _userId;

  @override
  Future<NotificationPreferences> build() async =>
      const NotificationPreferences();

  Future<void> loadForUser(String userId) async {
    if (_userId == userId && state.hasValue) return;
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    state = AsyncData(NotificationPreferences(
      sms: prefs.getBool(_key(userId, 'sms')) ?? true,
      email: prefs.getBool(_key(userId, 'email')) ?? true,
    ));
  }

  Future<void> setSms(bool enabled) => _update(sms: enabled);

  Future<void> setEmail(bool enabled) => _update(email: enabled);

  Future<void> _update({bool? sms, bool? email}) async {
    final userId = _userId;
    final current = state.valueOrNull ?? const NotificationPreferences();
    final next = current.copyWith(sms: sms, email: email);
    state = AsyncData(next);
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId, 'sms'), next.sms);
    await prefs.setBool(_key(userId, 'email'), next.email);
  }

  String _key(String userId, String channel) =>
      'notifications_${userId}_$channel';
}
