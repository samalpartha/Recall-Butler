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

abstract class Reminder implements _i1.SerializableModel {
  Reminder._({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dueAt,
    required this.isCompleted,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  factory Reminder({
    int? id,
    required int userId,
    required String title,
    String? description,
    DateTime? dueAt,
    required bool isCompleted,
    required int priority,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ReminderImpl;

  factory Reminder.fromJson(Map<String, dynamic> jsonSerialization) {
    return Reminder(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      dueAt: jsonSerialization['dueAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dueAt']),
      isCompleted: jsonSerialization['isCompleted'] as bool,
      priority: jsonSerialization['priority'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String title;

  String? description;

  DateTime? dueAt;

  bool isCompleted;

  int priority;

  DateTime createdAt;

  DateTime? updatedAt;

  /// Returns a shallow copy of this [Reminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Reminder copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    DateTime? dueAt,
    bool? isCompleted,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Reminder',
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      if (description != null) 'description': description,
      if (dueAt != null) 'dueAt': dueAt?.toJson(),
      'isCompleted': isCompleted,
      'priority': priority,
      'createdAt': createdAt.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReminderImpl extends Reminder {
  _ReminderImpl({
    int? id,
    required int userId,
    required String title,
    String? description,
    DateTime? dueAt,
    required bool isCompleted,
    required int priority,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         title: title,
         description: description,
         dueAt: dueAt,
         isCompleted: isCompleted,
         priority: priority,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Reminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Reminder copyWith({
    Object? id = _Undefined,
    int? userId,
    String? title,
    Object? description = _Undefined,
    Object? dueAt = _Undefined,
    bool? isCompleted,
    int? priority,
    DateTime? createdAt,
    Object? updatedAt = _Undefined,
  }) {
    return Reminder(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description is String? ? description : this.description,
      dueAt: dueAt is DateTime? ? dueAt : this.dueAt,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }
}
