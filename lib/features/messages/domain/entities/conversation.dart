import '../../../../shared/models/json_utils.dart';
import '../../../../shared/models/user_brief.dart';

/// محادثة كما تعود من GET /messages:
/// ```json
/// { "id": 1, "sender": {...}, "receiver": {...},
///   "last_message_at": "...", "created_at": "..." }
/// ```
class Conversation {
  final int id;
  final UserBrief? sender;
  final UserBrief? receiver;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const Conversation({
    required this.id,
    this.sender,
    this.receiver,
    this.lastMessageAt,
    this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: asInt(json['id']),
        sender: json['sender'] is Map
            ? UserBrief.fromJson(Map<String, dynamic>.from(json['sender'] as Map))
            : null,
        receiver: json['receiver'] is Map
            ? UserBrief.fromJson(
                Map<String, dynamic>.from(json['receiver'] as Map))
            : null,
        lastMessageAt: asDateOrNull(json['last_message_at']),
        createdAt: asDateOrNull(json['created_at']),
      );

  /// الطرف الآخر بالنسبة للمستخدم الحالي [myId].
  UserBrief? counterpart(int myId) {
    if (sender?.id == myId) return receiver;
    if (receiver?.id == myId) return sender;
    return receiver ?? sender;
  }
}
