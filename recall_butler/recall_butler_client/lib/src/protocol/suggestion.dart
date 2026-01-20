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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Suggestion implements _i1.SerializableModel {
  Suggestion._({
    this.id,
    required this.documentId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.payloadJson,
    required this.state,
    this.scheduledAt,
    this.executedAt,
  });

  factory Suggestion({
    int? id,
    required int documentId,
    required int userId,
    required String type,
    required String title,
    required String description,
    required String payloadJson,
    required String state,
    DateTime? scheduledAt,
    DateTime? executedAt,
  }) = _SuggestionImpl;

  factory Suggestion.fromJson(Map<String, dynamic> jsonSerialization) {
    return Suggestion(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      userId: jsonSerialization['userId'] as int,
      type: jsonSerialization['type'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String,
      state: jsonSerialization['state'] as String,
      scheduledAt: jsonSerialization['scheduledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['scheduledAt'],
            ),
      executedAt: jsonSerialization['executedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['executedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int documentId;

  int userId;

  String type;

  String title;

  String description;

  String payloadJson;

  String state;

  DateTime? scheduledAt;

  DateTime? executedAt;

  /// Returns a shallow copy of this [Suggestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Suggestion copyWith({
    int? id,
    int? documentId,
    int? userId,
    String? type,
    String? title,
    String? description,
    String? payloadJson,
    String? state,
    DateTime? scheduledAt,
    DateTime? executedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Suggestion',
      if (id != null) 'id': id,
      'documentId': documentId,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'payloadJson': payloadJson,
      'state': state,
      if (scheduledAt != null) 'scheduledAt': scheduledAt?.toJson(),
      if (executedAt != null) 'executedAt': executedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SuggestionImpl extends Suggestion {
  _SuggestionImpl({
    int? id,
    required int documentId,
    required int userId,
    required String type,
    required String title,
    required String description,
    required String payloadJson,
    required String state,
    DateTime? scheduledAt,
    DateTime? executedAt,
  }) : super._(
         id: id,
         documentId: documentId,
         userId: userId,
         type: type,
         title: title,
         description: description,
         payloadJson: payloadJson,
         state: state,
         scheduledAt: scheduledAt,
         executedAt: executedAt,
       );

  /// Returns a shallow copy of this [Suggestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Suggestion copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? userId,
    String? type,
    String? title,
    String? description,
    String? payloadJson,
    String? state,
    Object? scheduledAt = _Undefined,
    Object? executedAt = _Undefined,
  }) {
    return Suggestion(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      payloadJson: payloadJson ?? this.payloadJson,
      state: state ?? this.state,
      scheduledAt: scheduledAt is DateTime? ? scheduledAt : this.scheduledAt,
      executedAt: executedAt is DateTime? ? executedAt : this.executedAt,
    );
  }
}
