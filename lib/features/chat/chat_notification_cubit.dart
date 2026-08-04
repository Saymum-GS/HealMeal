import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories.dart';

class ChatNotificationCubit extends Cubit<int> {
  final ChatRepository _chatRepository;
  final String _userId;
  StreamSubscription? _subscription;

  ChatNotificationCubit(this._chatRepository, this._userId) : super(0) {
    if (_userId.isNotEmpty) {
      _startListening();
    }
  }

  void _startListening() {
    _subscription = _chatRepository
        .unreadCountForUser(_userId)
        .listen(
          (unreadCount) {
            if (!isClosed) emit(unreadCount);
          },
          onError: (_) {
            if (!isClosed) emit(0);
          },
        );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
