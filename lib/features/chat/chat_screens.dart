import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/repositories.dart';
import '../../core/localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../core/services.dart';
import 'chat_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<ChatRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.strings.chatConversations,
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: repo.allConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return EmptyStateWidget(
              type: EmptyStateType.chat,
              customTitle: context.strings.chatNoConversations,
              customBody: 'When users send messages, they will appear here.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Dismissible(
                key: Key(conv.userId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.w),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete Chat?'),
                      content: Text(
                        'Are you sure you want to delete this conversation entirely?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  repo.deleteConversation(conv.userId);
                },
                child: _ConversationTile(
                  conversation: conv,
                  isDark: isDark,
                  onTap: () {
                    final encodedName = Uri.encodeComponent(conv.userName);
                    context.push(
                      '/admin/chat/${conv.userId}?name=$encodedName',
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isDark,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool isDark;
  final VoidCallback onTap;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('d MMM').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final initials = conversation.userName.isNotEmpty
        ? conversation.userName
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary,
        child: Text(
          initials,
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.userName.isNotEmpty
                  ? conversation.userName
                  : 'Unknown User',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: conversation.unreadByAdmin > 0
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: conversation.unreadByAdmin > 0
                  ? AppColors.primary
                  : Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ),
          if (conversation.unreadByAdmin > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentRed,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                '${conversation.unreadByAdmin}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.isAdmin = false,
  });

  final String userId;
  final String userName;
  final bool isAdmin;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ChatCubit>();
    Future.microtask(() {
      cubit.markRead(byAdmin: widget.isAdmin);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final senderId = widget.isAdmin ? 'admin' : widget.userId;
    final senderName = widget.isAdmin ? 'HealMeal Support' : widget.userName;

    final lowerText = text.toLowerCase();
    final orderKeywords = ['order', 'buy', 'purchase', 'delivery', 'cart'];
    if (!widget.isAdmin && orderKeywords.any((kw) => lowerText.contains(kw))) {
      final userMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        senderName: senderName,
        text: text,
        createdAt: DateTime.now(),
        isRead: true,
      );
      context.read<ChatCubit>().addLocalMessage(userMsg);

      final sysMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        senderId: 'admin',
        senderName: 'System',
        text:
            "I'm a virtual assistant. To order medicines, please browse our catalog, add items to your cart, and checkout. [Tap here to view medicines]",
        createdAt: DateTime.now().add(Duration(milliseconds: 100)),
        isRead: true,
      );
      context.read<ChatCubit>().addLocalMessage(sysMsg);
      return;
    }

    await context.read<ChatCubit>().sendTextMessage(
      senderId: senderId,
      senderName: senderName,
      text: text,
    );
  }

  Future<void> _pickAndSendImage() async {
    final url = await ImageUploadUtil.pickImageAsBase64();
    if (url == null) return;

    if (url == 'TOO_LARGE') {
      if (mounted) {
        AppToast.show(
          context,
          context.strings.imageTooLarge,
          type: ToastType.error,
        );
      }
      return;
    }

    final senderId = widget.isAdmin ? 'admin' : widget.userId;
    final senderName = widget.isAdmin ? 'HealMeal Support' : widget.userName;

    if (mounted) {
      await context.read<ChatCubit>().sendImageMessage(
        senderId: senderId,
        senderName: senderName,
        imageUrl: url,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdmin ? widget.userName : 'HealMeal Support',
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  widget.isAdmin
                      ? 'User is Online'
                      : context.strings.chatOnlineStatus,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              tooltip: 'Clear Conversation',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Clear Conversation?'),
                    content: Text(
                      'This will permanently delete this entire chat history for both you and the user.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Delete All',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  try {
                    await context.read<ChatCubit>().deleteConversation();
                    if (context.mounted) {
                      Navigator.pop(context); // Close the chat screen on success
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to clear conversation: $e')));
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Persistent info banner per spec Section 7.2 - always visible
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            color: Color(0xFFE3F2FD),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 18.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Chat is for information and medicine queries only. To place an order, use the Order section.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state is ChatLoaded) {
                  _scrollToBottom();
                  // Mark as read whenever new messages arrive
                  context.read<ChatCubit>().markRead(byAdmin: widget.isAdmin);
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (state is ChatError) {
                  return Center(child: Text(state.message));
                }

                final messages = state is ChatLoaded
                    ? state.messages
                    : state is ChatSending
                    ? state.messages
                    : <ChatMessage>[];

                if (messages.isEmpty) {
                  return EmptyStateWidget(
                    type: EmptyStateType.chat,
                    customTitle: context.strings.chatEmptyTitle,
                    customBody: context.strings.chatEmptySubtitle,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = widget.isAdmin
                        ? msg.senderId == 'admin'
                        : msg.senderId != 'admin';

                    // Date separator
                    Widget? dateSeparator;
                    if (index == 0 ||
                        !_isSameDay(
                          messages[index - 1].createdAt,
                          msg.createdAt,
                        )) {
                      dateSeparator = _DateSeparator(date: msg.createdAt);
                    }

                    final canDelete = widget.isAdmin || isMe;

                    return GestureDetector(
                      onLongPress: canDelete
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Delete Message?'),
                                  content: Text(
                                    'Remove this message permanently?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                context.read<ChatCubit>().deleteMessage(msg.id);
                              }
                            }
                          : null,
                      child: Column(
                        children: [
                          if (dateSeparator != null) dateSeparator,
                          _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input row
          Container(
            padding: EdgeInsets.only(
              left: 12.w,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                // Image picker button
                IconButton(
                  onPressed: _pickAndSendImage,
                  icon: Icon(Icons.image_outlined, color: AppColors.primary),
                  tooltip: context.strings.chatSendImage,
                ),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: context.strings.chatInputHint,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.pill,
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : context.colorSurface,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendText,
                    icon: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// -- Date Separator ----------------------------------------------------------

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppRadius.pill,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(
            _formatDate(date),
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// -- Message Bubble ----------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? AppColors.primary
        : (isDark ? context.colorCard : context.colorSurface);
    final textColor = isMe
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final timeColor = isMe
        ? Colors.white.withOpacity(0.7)
        : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
            bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Image
            if (message.hasImage) ...[
              GestureDetector(
                onTap: () => _showFullImage(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildChatImage(context),
                ),
              ),
              if (message.hasText) SizedBox(height: 8.h),
            ],
            // Text
            if (message.hasText)
              if (message.text.contains('[Tap here to view medicines]'))
                RichText(
                  text: TextSpan(
                    text: message.text.split('[Tap here to view medicines]')[0],
                    style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => context.go('/products'),
                          child: Text(
                            'Tap here to view medicines',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isMe ? Colors.white : AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text:
                            message.text
                                    .split('[Tap here to view medicines]')
                                    .length >
                                1
                            ? message.text.split(
                                '[Tap here to view medicines]',
                              )[1]
                            : '',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  message.text,
                  style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                ),
            SizedBox(height: 4.h),
            // Time + read receipt
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: timeColor,
                    fontSize: 10.sp,
                  ),
                ),
                if (isMe && message.isRead) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.done_all,
                    size: 14.w,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.primary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatImage(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      final imageWidth = (screenWidth * 0.55).clamp(150.0, 280.0);
      final url = message.imageUrl ?? '';

      return Image(
        image: ImageBase64Util.resolveProvider(url),
        width: imageWidth,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 150.w,
          height: 100.h,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } catch (e) {
      return Container(
        width: 150.w,
        height: 100.h,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  void _showFullImage(BuildContext context) {
    if (!message.hasImage) return;
    try {
      final url = message.imageUrl ?? '';
      Widget imageWidget = Image(
        image: ImageBase64Util.resolveProvider(url),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image, color: Colors.grey, size: 50),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: Center(child: InteractiveViewer(child: imageWidget)),
          ),
        ),
      );
    } catch (_) {}
  }
}
