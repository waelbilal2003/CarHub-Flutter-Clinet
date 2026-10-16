import '../../../../shared/models/json_utils.dart';
import '../../../../shared/models/user_brief.dart';

/// رسالة كما تعود من GET /messages/{id} و POST /messages:
/// ```json
/// { "id": 1, "conversation_id": 1, "tender_id": 1, "body": "...",
///   "read_at": null, "sender": {...}, "created_at": "...",
///   "attachments": [] }
/// ```
/// انتبه: tender_id يعود نصاً ("1") عند الإرسال ورقماً (1) عند القراءة.
class Message {
  final int id;
  final int? conversationId;
  final int? tenderId;
  final String body;
  final DateTime? readAt;
  final UserBrief? sender;
  final DateTime? createdAt;
  final List<String> attachments;

  const Message({
    required this.id,
    this.conversationId,
    this.tenderId,
    required this.body,
    this.readAt,
    this.sender,
    this.createdAt,
    this.attachments = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: asInt(json['id']),
        conversationId: asIntOrNull(json['conversation_id']),
        tenderId: asIntOrNull(json['tender_id']),
        body: asString(json['body']),
        readAt: asDateOrNull(json['read_at']),
        sender: json['sender'] is Map
            ? UserBrief.fromJson(Map<String, dynamic>.from(json['sender'] as Map))
            : null,
        createdAt: asDateOrNull(json['created_at']),
        attachments: asStringList(json['attachments']),
      );

  bool get isRead => readAt != null;

  /// هل أرسلها المستخدم الحالي؟ (لتحديد جهة الفقاعة في المحادثة)
  bool isMine(int myId) => sender?.id == myId;
}
