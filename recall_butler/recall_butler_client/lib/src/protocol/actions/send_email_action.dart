/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import '../protocol.dart' as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import '../actions/action_status.dart' as _i3;

abstract class SendEmailAction extends _i1.ButlerAction
    implements _i2.SerializableModel {
  SendEmailAction._({
    required super.userId,
    required super.description,
    required super.confidence,
    required super.status,
    required super.createdAt,
    required this.recipient,
    required this.subject,
    required this.body,
  });

  factory SendEmailAction({
    required int userId,
    required String description,
    required double confidence,
    required _i3.ActionStatus status,
    required DateTime createdAt,
    required String recipient,
    required String subject,
    required String body,
  }) = _SendEmailActionImpl;

  factory SendEmailAction.fromJson(Map<String, dynamic> jsonSerialization) {
    return SendEmailAction(
      userId: jsonSerialization['userId'] as int,
      description: jsonSerialization['description'] as String,
      confidence: (jsonSerialization['confidence'] as num).toDouble(),
      status: _i3.ActionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      createdAt: _i2.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      recipient: jsonSerialization['recipient'] as String,
      subject: jsonSerialization['subject'] as String,
      body: jsonSerialization['body'] as String,
    );
  }

  String recipient;

  String subject;

  String body;

  /// Returns a shallow copy of this [SendEmailAction]
  /// with some or all fields replaced by the given arguments.
  @override
  @_i2.useResult
  SendEmailAction copyWith({
    int? userId,
    String? description,
    double? confidence,
    _i3.ActionStatus? status,
    DateTime? createdAt,
    String? recipient,
    String? subject,
    String? body,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SendEmailAction',
      'userId': userId,
      'description': description,
      'confidence': confidence,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      'recipient': recipient,
      'subject': subject,
      'body': body,
    };
  }

  @override
  String toString() {
    return _i2.SerializationManager.encode(this);
  }
}

class _SendEmailActionImpl extends SendEmailAction {
  _SendEmailActionImpl({
    required int userId,
    required String description,
    required double confidence,
    required _i3.ActionStatus status,
    required DateTime createdAt,
    required String recipient,
    required String subject,
    required String body,
  }) : super._(
         userId: userId,
         description: description,
         confidence: confidence,
         status: status,
         createdAt: createdAt,
         recipient: recipient,
         subject: subject,
         body: body,
       );

  /// Returns a shallow copy of this [SendEmailAction]
  /// with some or all fields replaced by the given arguments.
  @_i2.useResult
  @override
  SendEmailAction copyWith({
    int? userId,
    String? description,
    double? confidence,
    _i3.ActionStatus? status,
    DateTime? createdAt,
    String? recipient,
    String? subject,
    String? body,
  }) {
    return SendEmailAction(
      userId: userId ?? this.userId,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      recipient: recipient ?? this.recipient,
      subject: subject ?? this.subject,
      body: body ?? this.body,
    );
  }
}
