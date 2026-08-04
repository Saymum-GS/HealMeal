import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils.dart';

import '../../../core/services.dart';
import '../../../core/config.dart';
import '../../../core/repositories.dart';
import '../../../core/widgets.dart';
import '../auth/auth_cubit.dart';
import '../cart/cart_cubit.dart';

import 'models/chat_message.dart';
import 'models/chat_session.dart';
import 'ai_chat_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInit = false;
  bool _isSending = false;

  List<AiChatSession> _sessions = [];
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  AiChatMessage _getGreeting() {
    return AiChatMessage(
      id: 'greeting',
      role: AiChatRole.assistant,
      text:
          "Hi! I'm HealMeal AI Assistant 🏥\nTell me your symptoms or what you're looking for, and I'll find the best medicines and lab tests for you.",
    );
  }

  Future<void> _initChat() async {
    final authState = context.read<AuthCubit>().state;
    final uid = authState is AuthAuthenticated ? authState.userId : null;
    await _loadSessions(uid);
    setState(() => _isInit = true);

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      if (_messages.length <= 1) {
        // Only greeting
        _controller.text = widget.initialQuery!;
        _sendMessage();
      }
    }
  }

  Future<void> _loadSessions(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    _messages.clear();
    _messages.add(_getGreeting());

    if (uid == null) {
      _activeSessionId = 'guest';
      final raw = prefs.getString('hm_ai_chat_guest');
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _messages.addAll(
          list.map((e) => AiChatMessage.fromJson(e as Map<String, dynamic>)),
        );
      }
    } else {
      final sessionsRaw = prefs.getString('hm_ai_sessions_$uid');
      if (sessionsRaw != null) {
        final list = jsonDecode(sessionsRaw) as List<dynamic>;
        _sessions = list
            .map((e) => AiChatSession.fromJson(e as Map<String, dynamic>))
            .toList();
        _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      if (_sessions.isNotEmpty) {
        await _switchToSession(_sessions.first.id, uid);
      } else {
        _startNewSession(uid);
      }
    }
  }

  void _startNewSession(String? uid) {
    _messages.clear();
    _messages.add(_getGreeting());
    if (uid == null) {
      _activeSessionId = 'guest';
      _saveMessages();
    } else {
      _activeSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final newSession = AiChatSession(
        id: _activeSessionId!,
        name: 'New Chat',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _sessions.insert(0, newSession);
      _saveSessionsMeta(uid);
      _saveMessages();
    }
    if (mounted) setState(() {});
  }

  Future<void> _switchToSession(String sessionId, String uid) async {
    _activeSessionId = sessionId;
    _messages.clear();
    _messages.add(_getGreeting());
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('hm_ai_chat_${uid}_$sessionId');
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _messages.addAll(
        list.map((e) => AiChatMessage.fromJson(e as Map<String, dynamic>)),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveSessionsMeta(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = _sessions.map((s) => s.toJson()).toList();
    await prefs.setString('hm_ai_sessions_$uid', jsonEncode(toSave));
  }

  Future<void> _saveMessages() async {
    final authState = context.read<AuthCubit>().state;
    final uid = authState is AuthAuthenticated ? authState.userId : null;
    final prefs = await SharedPreferences.getInstance();

    final toSave = _messages.skip(1).map((m) => m.toJson()).toList();

    if (uid == null) {
      if (toSave.isEmpty) {
        await prefs.remove('hm_ai_chat_guest');
      } else {
        await prefs.setString('hm_ai_chat_guest', jsonEncode(toSave));
      }
    } else {
      if (_activeSessionId != null) {
        if (toSave.isEmpty) {
          await prefs.remove('hm_ai_chat_${uid}_$_activeSessionId');
        } else {
          await prefs.setString(
            'hm_ai_chat_${uid}_$_activeSessionId',
            jsonEncode(toSave),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _isSending = true;
    try {
      _controller.clear();
      final authState = context.read<AuthCubit>().state;
      final uid = authState is AuthAuthenticated ? authState.userId : null;

      final userMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiChatRole.user,
        text: text,
      );
      setState(() {
        _messages.add(userMsg);
        _isLoading = true;
      });
      _scrollToBottom();
      _saveMessages();

      if (uid != null && _activeSessionId != null) {
        final sessionIndex = _sessions.indexWhere(
          (s) => s.id == _activeSessionId,
        );
        if (sessionIndex != -1) {
          if (_messages.length == 2) {
            _sessions[sessionIndex].name = text.length > 30
                ? '${text.substring(0, 30)}...'
                : text;
          }
          _sessions[sessionIndex].updatedAt = DateTime.now();
          _saveSessionsMeta(uid);
        }
      }

      final repo = getIt<ProductRepository>();
      final historyForApi = _messages
          .skip(1)
          .where((m) => m != userMsg)
          .toList();

      final reply = await AiChatService.sendMessage(
        userMessage: text,
        history: historyForApi,
        productRepository: repo,
      );

      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isLoading = false;
        });
        _scrollToBottom();
        _saveMessages();
      }
    } finally {
      _isSending = false;
    }
  }

  void _showSessionsSheet(String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chat History', style: AppTextStyles.h2),
                        IconButton.filledTonal(
                          onPressed: () {
                            context.pop();
                            _startNewSession(uid);
                          },
                          icon: Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 1),
                  Expanded(
                    child: _sessions.isEmpty
                        ? Center(child: Text('No previous sessions.'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _sessions.length,
                            itemBuilder: (context, i) {
                              final session = _sessions[i];
                              final isActive = session.id == _activeSessionId;
                              return ListTile(
                                leading: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                                title: Text(
                                  session.name,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  AppFormatters.shortDate(session.updatedAt),
                                  style: AppTextStyles.bodySmall,
                                ),
                                trailing: isActive
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 20.w,
                                      )
                                    : null,
                                onTap: () {
                                  context.pop();
                                  _switchToSession(session.id, uid);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) return Center(child: CircularProgressIndicator());

    final authState = context.read<AuthCubit>().state;
    final uid = authState is AuthAuthenticated ? authState.userId : null;

    return Column(
      children: [
        if (uid != null || _messages.length > 1)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (uid != null)
                  TextButton.icon(
                    icon: Icon(Icons.history_rounded, size: 18.w),
                    label: Text('History'),
                    onPressed: () => _showSessionsSheet(uid),
                  ),
                if (_messages.length > 1)
                  TextButton.icon(
                    icon: Icon(Icons.delete_sweep_rounded, size: 18.w),
                    label: Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _messages.removeRange(1, _messages.length);
                      });
                      _saveMessages();
                    },
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return const _TypingIndicator();
              }

              final msg = _messages[index];
              if (msg.role == AiChatRole.user) {
                return _UserBubble(text: msg.text);
              } else {
                return _AssistantBubble(message: msg);
              }
            },
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 12.w,
            right: 12.w,
            top: 12.h,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: context.colorSurface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Ask about medicines...',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.xl,
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: context.colorBg,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              SizedBox(width: 10.w),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: Icon(Icons.send_rounded, size: 20.w),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(48, 48),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 20.w,
          height: 10.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_Dot(), _Dot(), _Dot()],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        width: 4.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 48.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final AiChatMessage message;
  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 12.h, right: 48.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ),
          if (message.products.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'Recommended Medicines',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(
              height: 240.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(bottom: 16.h),
                itemCount: message.products.length,
                separatorBuilder: (context, index) => SizedBox(width: 12.w),
                itemBuilder: (context, i) {
                  final product = message.products[i];
                  return SizedBox(
                    width: 150.w,
                    child: ProductCard(
                      product: product,
                      onTap: () => context.push('/product/${product.id}'),
                      onAddToCart: () {
                        context.read<CartCubit>().addItem(product);
                        AppToast.show(
                          context,
                          '${product.drugName} added to cart',
                          type: ToastType.success,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
