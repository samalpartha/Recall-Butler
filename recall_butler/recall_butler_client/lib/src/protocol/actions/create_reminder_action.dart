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

abstract class CreateReminderAction extends _i1.ButlerAction
    implements _i2.SerializableModel {
  CreateReminderAction._({
    required super.userId,
    required super.description,
    required super.confidence,
    required super.status,
    required super.createdAt,
    required this.title,
    required this.dueAt,
    this.priority,
  });

  factory CreateReminderAction({
    required int userId,
    required String description,
    required double confidence,
    required _i3.ActionStatus status,
    required DateTime createdAt,
    required String title,
    required DateTime dueAt,
    String? priority,
  }) = _CreateReminderActionImpl;

  factory CreateReminderAction.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateReminderAction(
      userId: jsonSerialization['userId'] as int,
      description: jsonSerialization['description'] as String,
      confidence: (jsonSerialization['confidence'] as num).toDouble(),
      status: _i3.ActionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      createdAt: _i2.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      title: jsonSerialization['title'] as String,
      dueAt: _i2.DateTimeJsonExtension.fromJson(jsonSerialization['dueAt']),
      priority: jsonSerialization['priority'] as String?,
    );
  }

  String title;

  DateTime dueAt;

  String? priority;

  /// Returns a shallow copy of this [CreateReminderAction]
  /// with some or all fields replaced by the given arguments.
  @override
  @_i2.useResult
  CreateReminderAction copyWith({
    int? userId,
    String? description,
    double? confidence,
    _i3.ActionStatus? status,
    DateTime? createdAt,
    String? title,
    DateTime? dueAt,
    String? priority,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateReminderAction',
      'userId': userId,
      'description': description,
      'confidence': confidence,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      'title': title,
      'dueAt': dueAt.toJson(),
      if (priority != null) 'priority': priority,
    };
  }

  @override
  String toString() {
    return _i2.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CreateReminderActionImpl extends CreateReminderAction {
  _CreateReminderActionImpl({
    required int userId,
    required String description,
    required double confidence,
    required _i3.ActionStatus status,
    required DateTime createdAt,
    required String title,
    required DateTime dueAt,
    String? priority,
  }) : super._(
         userId: userId,
         description: description,
         confidence: confidence,
         status: status,
         createdAt: createdAt,
         title: title,
         dueAt: dueAt,
         priority: priority,
       );

  /// Returns a shallow copy of this [CreateReminderAction]
  /// with some or all fields replaced by the given arguments.
  @_i2.useResult
  @override
  CreateReminderAction copyWith({
    int? userId,
    String? description,
    double? confidence,
    _i3.ActionStatus? status,
    DateTime? createdAt,
    String? title,
    DateTime? dueAt,
    Object? priority = _Undefined,
  }) {
    return CreateReminderAction(
      userId: userId ?? this.userId,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      priority: priority is String? ? priority : this.priority,
    );
  }
}
