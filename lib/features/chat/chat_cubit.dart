import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import 'package:equatable/equatable.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repo;
  final String _userId;
  StreamSubscription<List<ChatMessage>>? _sub;

  ChatCubit(this._repo, this._userId) : super(ChatInitial()) {
    _loadMessages();
  }

  final List<ChatMessage> _localMessages = [];

  void _loadMessages() {
    emit(ChatLoading());
    _sub = _repo.messagesStream(_userId).listen((messages) {
      final all = List<ChatMessage>.from(messages)..addAll(_localMessages);
      all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(ChatLoaded(all));
    }, onError: (e) => emit(ChatError(e.toString())));
  }

  void addLocalMessage(ChatMessage msg) {
    _localMessages.add(msg);
    if (state is ChatLoaded) {
      final all = List<ChatMessage>.from((state as ChatLoaded).messages)
        ..add(msg);
      all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(ChatLoaded(all));
    }
  }

  Future<void> sendTextMessage({
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final currentMessages = state is ChatLoaded
        ? (state as ChatLoaded).messages
        : <ChatMessage>[];
    emit(ChatSending(currentMessages));
    final msg = ChatMessage(
      id: '',
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      createdAt: DateTime.now(),
      isRead: false,
    );
    await _repo.sendMessage(_userId, msg);
  }

  Future<void> sendImageMessage({
    required String senderId,
    required String senderName,
    required String imageUrl,
    String text = '',
  }) async {
    final currentMessages = state is ChatLoaded
        ? (state as ChatLoaded).messages
        : <ChatMessage>[];
    emit(ChatSending(currentMessages));
    final msg = ChatMessage(
      id: '',
      senderId: senderId,
      senderName: senderName,
      text: text,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await _repo.sendMessage(_userId, msg);
  }

  Future<void> markRead({required bool byAdmin}) async {
    try {
      await _repo.markMessagesRead(_userId, byAdmin: byAdmin);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _repo.deleteMessage(_userId, messageId);
      // Local state is updated via the stream
    } catch (e) {
      if (state is ChatLoaded) {
        emit(ChatError('Failed to delete message: $e'));
      }
      rethrow;
    }
  }

  Future<void> deleteConversation() async {
    try {
      await _repo.deleteConversation(_userId);
      // Local state is updated via the stream, which should empty out
    } catch (e) {
      if (state is ChatLoaded) {
        emit(ChatError('Failed to clear conversation: $e'));
      }
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  const ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatSending extends ChatState {
  final List<ChatMessage> messages;
  const ChatSending(this.messages);

  @override
  List<Object?> get props => [messages];
}
