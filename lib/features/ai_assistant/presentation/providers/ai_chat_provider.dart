import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/ai_remote_datasource.dart';
import '../../domain/entities/ai_reply.dart';

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSource(ref.watch(dioClientProvider));
});

/// عناصر المحادثة كما تُعرض في الشاشة.
sealed class ChatEntry {
  const ChatEntry();
}

class UserEntry extends ChatEntry {
  final String text;
  const UserEntry(this.text);
}

/// ردّ المساعد. [reply] = null لرسالة الترحيب المحلية (لا تُرسَل للخادم).
class AssistantEntry extends ChatEntry {
  final String text;
  final AiReply? reply;
  const AssistantEntry(this.text, {this.reply});
}

/// فشل الإرسال. [retryable] = انقطاع شبكة / مهلة / المساعد غير متاح.
class ErrorEntry extends ChatEntry {
  final String message;
  final bool retryable;
  final String pendingMessage;
  const ErrorEntry(this.message,
      {required this.retryable, required this.pendingMessage});
}

class AiChatState {
  final List<ChatEntry> entries;
  final String? conversationId;
  final bool isSending;

  const AiChatState({
    required this.entries,
    this.conversationId,
    this.isSending = false,
  });

  AiChatState copyWith({
    List<ChatEntry>? entries,
    String? conversationId,
    bool? isSending,
  }) =>
      AiChatState(
        entries: entries ?? this.entries,
        conversationId: conversationId ?? this.conversationId,
        isSending: isSending ?? this.isSending,
      );
}

const aiWelcomeMessage =
    'أهلاً! أنا مساعد CarHub. اسألني عن أي قطعة لسيارتك، أو احكيلي عن '
    'العطل، وبساعدك تلاقي القطعة أو تطلب عروض من الورش.';

const int aiMaxMessageLength = 500;

/// المحادثة مع المساعد. ليست autoDispose: تبقى المحادثة و[conversationId]
/// محفوظتين إذا أُغلقت الشاشة وفُتحت من جديد خلال نفس الجلسة.
final aiChatProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
  return AiChatController(ref.watch(aiRemoteDataSourceProvider));
});

class AiChatController extends StateNotifier<AiChatState> {
  final AiRemoteDataSource _remote;

  AiChatController(this._remote) : super(_initial());

  static AiChatState _initial() =>
      const AiChatState(entries: [AssistantEntry(aiWelcomeMessage)]);

  /// يرسل [text] (من الحقل أو من زر اقتراح).
  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.isSending) return;
    if (message.length > aiMaxMessageLength) return;
    await _ask(message, addUserEntry: true);
  }

  /// يعيد إرسال الرسالة التي فشلت، دون تكرار فقاعة المستخدم.
  Future<void> retry() async {
    final last = state.entries.isNotEmpty ? state.entries.last : null;
    if (last is! ErrorEntry || state.isSending) return;
    await _ask(last.pendingMessage, addUserEntry: false);
  }

  /// محادثة جديدة: تمسح الشاشة و[conversationId].
  void newConversation() {
    if (state.isSending) return;
    state = _initial();
  }

  Future<void> _ask(String message, {required bool addUserEntry}) async {
    final entries = [
      ...state.entries.where((e) => e is! ErrorEntry),
      if (addUserEntry) UserEntry(message),
    ];
    state = state.copyWith(entries: entries, isSending: true);

    try {
      final reply = await _remote.ask(
        message: message,
        conversationId: state.conversationId,
      );
      state = AiChatState(
        entries: [...state.entries, AssistantEntry(reply.answer, reply: reply)],
        conversationId: reply.conversationId.isEmpty
            ? state.conversationId
            : reply.conversationId,
      );
    } on Failure catch (f) {
      state = state.copyWith(
        isSending: false,
        entries: [
          ...state.entries,
          ErrorEntry(
            f.message,
            retryable: f is NetworkFailure || f is ServerFailure,
            pendingMessage: message,
          ),
        ],
      );
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        entries: [
          ...state.entries,
          ErrorEntry(const UnknownFailure().message,
              retryable: true, pendingMessage: message),
        ],
      );
    }
  }
}
