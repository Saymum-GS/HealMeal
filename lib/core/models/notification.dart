import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String type;
  final bool read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      type: type,
      read: read ?? this.read,
    );
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AppNotification(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      time: map['time'] is DateTime
          ? map['time']
          : (map['time'] != null
                ? (map['time'] as dynamic).toDate()
                : DateTime.now()),
      type: map['type'] ?? 'general',
      read: map['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time,
      'type': type,
      'read': read,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, title, time, type, read];
}
