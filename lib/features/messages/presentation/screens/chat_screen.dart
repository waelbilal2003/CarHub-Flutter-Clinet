import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/message.dart';
import '../providers/message_provider.dart';

/// محادثة واحدة — GET /messages/{id} و POST /messages
///
/// ⚠️ ملاحظة عن الـ Backend: [chatId] هو ما يعود في قائمة المحادثات.
/// يحتاج تأكيد إسراء هل هو معرّف المحادثة أم معرّف الطرف الآخر،
/// لأن الإرسال يتطلب receiver_id وليس conversation_id.
class ChatScreen extends ConsumerStatefulWidget {
  final int chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(int receiverId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final ok = await ref.read(sendMessageProvider.notifier).send(
          receiverId: receiverId,
          content: text,
          refreshChatId: widget.chatId,
        );

    if (!mounted) return;
    if (ok) {
      _controller.clear();
    } else {
      final err = ref.read(sendMessageProvider).error ?? 'تعذّر إرسال الرسالة.';
      AppSnackBar.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatProvider(widget.chatId));
    final myId = ref.watch(authProvider).user?.id ?? 0;
    final isSending = ref.watch(sendMessageProvider).isSending;

    return ClientScaffold(
      appBar: AppBar(title: const Text('المحادثة')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  child: Text(e.toString(), textAlign: TextAlign.center),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('ابدأ المحادثة برسالة.'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[messages.length - 1 - i];
                    return _Bubble(message: m, isMine: m.isMine(myId));
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            isSending: isSending,
            onSend: () {
              // نستنتج المستلم من أول رسالة ليست من المستخدم الحالي.
              final messages = messagesAsync.valueOrNull ?? const <Message>[];
              final other = messages
                  .map((m) => m.sender)
                  .firstWhere((s) => s != null && s.id != myId,
                      orElse: () => null);
              final receiverId = other?.id ?? widget.chatId;
              _send(receiverId);
            },
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM, vertical: AppDimensions.spaceS),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          boxShadow: AppDimensions.cardShadow,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: AppTextStyles.body.copyWith(
                color: isMine ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            if (message.createdAt != null)
              Text(
                '${message.createdAt!.hour.toString().padLeft(2, '0')}:'
                '${message.createdAt!.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.caption.copyWith(
                  color: isMine
                      ? AppColors.white.withValues(alpha: 0.8)
                      : AppColors.textHint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceS),
        color: AppColors.surface,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
