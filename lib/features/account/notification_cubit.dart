import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/notification.dart';
import '../../core/services.dart';
import '../auth/auth_cubit.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({required this.authCubit}) : super(NotificationState()) {
    _authSubscription = authCubit.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _listenToNotifications(authState.userId);
      } else {
        _notificationSubscription?.cancel();
        emit(NotificationState());
      }
    });

    if (authCubit.state is AuthAuthenticated) {
      _listenToNotifications((authCubit.state as AuthAuthenticated).userId);
    }
  }

  final AuthCubit authCubit;
  late final StreamSubscription<AuthState> _authSubscription;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  void _listenToNotifications(String uid) {
    _notificationSubscription?.cancel();
    emit(state.copyWith(isLoading: true));

    bool isFirstLoad = true;
    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            if (!isFirstLoad) {
              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final data = change.doc.data();
                  if (data != null && data['read'] == false) {
                    NotificationService.showLocalNotification(
                      title: data['title'] ?? 'New Notification',
                      body: data['body'] ?? data['message'] ?? '',
                    );
                  }
                }
              }
            }
            isFirstLoad = false;

            final notifications = snapshot.docs.map((doc) {
              return AppNotification.fromMap(doc.data(), doc.id);
            }).toList();

            emit(
              state.copyWith(notifications: notifications, isLoading: false),
            );
          },
          onError: (e) {
            emit(state.copyWith(error: e.toString(), isLoading: false));
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    if (authCubit.state is! AuthAuthenticated) return;
    final uid = (authCubit.state as AuthAuthenticated).userId;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      // Ignored for now
    }
  }

  Future<void> markAllAsRead() async {
    if (authCubit.state is! AuthAuthenticated) return;
    final uid = (authCubit.state as AuthAuthenticated).userId;

    final unreadList = state.notifications.where((n) => !n.read).toList();
    if (unreadList.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in unreadList) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(n.id);
        batch.update(ref, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      // Ignored
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _notificationSubscription?.cancel();
    return super.close();
  }
}
