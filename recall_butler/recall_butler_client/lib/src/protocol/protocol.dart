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
import 'actions/action_status.dart' as _i2;
import 'actions/action_template.dart' as _i3;
import 'actions/create_reminder_action.dart' as _i4;
import 'actions/send_email_action.dart' as _i5;
import 'actions/butler_action.dart' as _i6;
import 'document.dart' as _i7;
import 'document_chunk.dart' as _i8;
import 'greetings/greeting.dart' as _i9;
import 'reminder.dart' as _i10;
import 'search_response.dart' as _i11;
import 'search_result.dart' as _i12;
import 'suggestion.dart' as _i13;
import 'package:recall_butler_client/src/protocol/document.dart' as _i14;
import 'package:recall_butler_client/src/protocol/reminder.dart' as _i15;
import 'package:recall_butler_client/src/protocol/search_result.dart' as _i16;
import 'package:recall_butler_client/src/protocol/suggestion.dart' as _i17;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i18;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i19;
export 'actions/action_status.dart';
export 'actions/action_template.dart';
export 'actions/create_reminder_action.dart';
export 'actions/send_email_action.dart';
export 'actions/butler_action.dart';
export 'document.dart';
export 'document_chunk.dart';
export 'greetings/greeting.dart';
export 'reminder.dart';
export 'search_response.dart';
export 'search_result.dart';
export 'suggestion.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.ActionStatus) {
      return _i2.ActionStatus.fromJson(data) as T;
    }
    if (t == _i3.ActionTemplate) {
      return _i3.ActionTemplate.fromJson(data) as T;
    }
    if (t == _i4.CreateReminderAction) {
      return _i4.CreateReminderAction.fromJson(data) as T;
    }
    if (t == _i5.SendEmailAction) {
      return _i5.SendEmailAction.fromJson(data) as T;
    }
    if (t == _i6.ButlerAction) {
      return _i6.ButlerAction.fromJson(data) as T;
    }
    if (t == _i7.Document) {
      return _i7.Document.fromJson(data) as T;
    }
    if (t == _i8.DocumentChunk) {
      return _i8.DocumentChunk.fromJson(data) as T;
    }
    if (t == _i9.Greeting) {
      return _i9.Greeting.fromJson(data) as T;
    }
    if (t == _i10.Reminder) {
      return _i10.Reminder.fromJson(data) as T;
    }
    if (t == _i11.SearchResponse) {
      return _i11.SearchResponse.fromJson(data) as T;
    }
    if (t == _i12.SearchResult) {
      return _i12.SearchResult.fromJson(data) as T;
    }
    if (t == _i13.Suggestion) {
      return _i13.Suggestion.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.ActionStatus?>()) {
      return (data != null ? _i2.ActionStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.ActionTemplate?>()) {
      return (data != null ? _i3.ActionTemplate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.CreateReminderAction?>()) {
      return (data != null ? _i4.CreateReminderAction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.SendEmailAction?>()) {
      return (data != null ? _i5.SendEmailAction.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ButlerAction?>()) {
      return (data != null ? _i6.ButlerAction.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Document?>()) {
      return (data != null ? _i7.Document.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.DocumentChunk?>()) {
      return (data != null ? _i8.DocumentChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Greeting?>()) {
      return (data != null ? _i9.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Reminder?>()) {
      return (data != null ? _i10.Reminder.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SearchResponse?>()) {
      return (data != null ? _i11.SearchResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.SearchResult?>()) {
      return (data != null ? _i12.SearchResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Suggestion?>()) {
      return (data != null ? _i13.Suggestion.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i12.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i12.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == List<Map<String, dynamic>>) {
      return (data as List)
              .map((e) => deserialize<Map<String, dynamic>>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.Document>) {
      return (data as List).map((e) => deserialize<_i14.Document>(e)).toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
                )
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i15.Reminder>) {
      return (data as List).map((e) => deserialize<_i15.Reminder>(e)).toList()
          as T;
    }
    if (t == List<_i16.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i16.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i17.Suggestion>) {
      return (data as List).map((e) => deserialize<_i17.Suggestion>(e)).toList()
          as T;
    }
    try {
      return _i18.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i19.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.ActionStatus => 'ActionStatus',
      _i3.ActionTemplate => 'ActionTemplate',
      _i4.CreateReminderAction => 'CreateReminderAction',
      _i5.SendEmailAction => 'SendEmailAction',
      _i6.ButlerAction => 'ButlerAction',
      _i7.Document => 'Document',
      _i8.DocumentChunk => 'DocumentChunk',
      _i9.Greeting => 'Greeting',
      _i10.Reminder => 'Reminder',
      _i11.SearchResponse => 'SearchResponse',
      _i12.SearchResult => 'SearchResult',
      _i13.Suggestion => 'Suggestion',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'recall_butler.',
        '',
      );
    }

    switch (data) {
      case _i2.ActionStatus():
        return 'ActionStatus';
      case _i3.ActionTemplate():
        return 'ActionTemplate';
      case _i4.CreateReminderAction():
        return 'CreateReminderAction';
      case _i5.SendEmailAction():
        return 'SendEmailAction';
      case _i6.ButlerAction():
        return 'ButlerAction';
      case _i7.Document():
        return 'Document';
      case _i8.DocumentChunk():
        return 'DocumentChunk';
      case _i9.Greeting():
        return 'Greeting';
      case _i10.Reminder():
        return 'Reminder';
      case _i11.SearchResponse():
        return 'SearchResponse';
      case _i12.SearchResult():
        return 'SearchResult';
      case _i13.Suggestion():
        return 'Suggestion';
    }
    className = _i18.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i19.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ActionStatus') {
      return deserialize<_i2.ActionStatus>(data['data']);
    }
    if (dataClassName == 'ActionTemplate') {
      return deserialize<_i3.ActionTemplate>(data['data']);
    }
    if (dataClassName == 'CreateReminderAction') {
      return deserialize<_i4.CreateReminderAction>(data['data']);
    }
    if (dataClassName == 'SendEmailAction') {
      return deserialize<_i5.SendEmailAction>(data['data']);
    }
    if (dataClassName == 'ButlerAction') {
      return deserialize<_i6.ButlerAction>(data['data']);
    }
    if (dataClassName == 'Document') {
      return deserialize<_i7.Document>(data['data']);
    }
    if (dataClassName == 'DocumentChunk') {
      return deserialize<_i8.DocumentChunk>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i9.Greeting>(data['data']);
    }
    if (dataClassName == 'Reminder') {
      return deserialize<_i10.Reminder>(data['data']);
    }
    if (dataClassName == 'SearchResponse') {
      return deserialize<_i11.SearchResponse>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i12.SearchResult>(data['data']);
    }
    if (dataClassName == 'Suggestion') {
      return deserialize<_i13.Suggestion>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i18.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i19.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i18.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i19.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
