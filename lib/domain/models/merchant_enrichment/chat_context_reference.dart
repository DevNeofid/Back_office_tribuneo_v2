/// Only opaque references go from BO to API; never row fields or candidate data.
class ChatContextReference {
  final int batchId, rowId, expectedVersion;
  final String proposalId;
  const ChatContextReference(
      {required this.batchId,
      required this.rowId,
      required this.proposalId,
      required this.expectedVersion});
  Map<String, dynamic> toJson() => {
        'batch_id': batchId,
        'row_id': rowId,
        'proposal_id': proposalId,
        'expected_version': expectedVersion
      };
  static final uuid =
      RegExp(r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$');
  static ChatContextReference? parse(Map json) {
    if (json['batch_id'] is! int ||
        json['row_id'] is! int ||
        json['expected_version'] is! int ||
        json['proposal_id'] is! String ||
        json['batch_id'] <= 0 ||
        json['row_id'] <= 0 ||
        json['expected_version'] <= 0 ||
        !uuid.hasMatch(json['proposal_id'])) return null;
    return ChatContextReference(
        batchId: json['batch_id'],
        rowId: json['row_id'],
        proposalId: json['proposal_id'],
        expectedVersion: json['expected_version']);
  }

  bool same(ChatContextReference other) =>
      batchId == other.batchId &&
      rowId == other.rowId &&
      proposalId == other.proposalId &&
      expectedVersion == other.expectedVersion;
}
