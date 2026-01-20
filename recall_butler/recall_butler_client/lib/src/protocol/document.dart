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

abstract class Document implements _i1.SerializableModel {
  Document._({
    this.id,
    required this.userId,
    required this.sourceType,
    required this.title,
    this.sourceUrl,
    this.mimeType,
    this.extractedText,
    this.summary,
    this.keyFieldsJson,
    required this.status,
    this.errorMessage,
  });

  factory Document({
    int? id,
    required int userId,
    required String sourceType,
    required String title,
    String? sourceUrl,
    String? mimeType,
    String? extractedText,
    String? summary,
    String? keyFieldsJson,
    required String status,
    String? errorMessage,
  }) = _DocumentImpl;

  factory Document.fromJson(Map<String, dynamic> jsonSerialization) {
    return Document(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      sourceType: jsonSerialization['sourceType'] as String,
      title: jsonSerialization['title'] as String,
      sourceUrl: jsonSerialization['sourceUrl'] as String?,
      mimeType: jsonSerialization['mimeType'] as String?,
      extractedText: jsonSerialization['extractedText'] as String?,
      summary: jsonSerialization['summary'] as String?,
      keyFieldsJson: jsonSerialization['keyFieldsJson'] as String?,
      status: jsonSerialization['status'] as String,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String sourceType;

  String title;

  String? sourceUrl;

  String? mimeType;

  String? extractedText;

  String? summary;

  String? keyFieldsJson;

  String status;

  String? errorMessage;

  /// Returns a shallow copy of this [Document]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Document copyWith({
    int? id,
    int? userId,
    String? sourceType,
    String? title,
    String? sourceUrl,
    String? mimeType,
    String? extractedText,
    String? summary,
    String? keyFieldsJson,
    String? status,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Document',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceType': sourceType,
      'title': title,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (mimeType != null) 'mimeType': mimeType,
      if (extractedText != null) 'extractedText': extractedText,
      if (summary != null) 'summary': summary,
      if (keyFieldsJson != null) 'keyFieldsJson': keyFieldsJson,
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentImpl extends Document {
  _DocumentImpl({
    int? id,
    required int userId,
    required String sourceType,
    required String title,
    String? sourceUrl,
    String? mimeType,
    String? extractedText,
    String? summary,
    String? keyFieldsJson,
    required String status,
    String? errorMessage,
  }) : super._(
         id: id,
         userId: userId,
         sourceType: sourceType,
         title: title,
         sourceUrl: sourceUrl,
         mimeType: mimeType,
         extractedText: extractedText,
         summary: summary,
         keyFieldsJson: keyFieldsJson,
         status: status,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [Document]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Document copyWith({
    Object? id = _Undefined,
    int? userId,
    String? sourceType,
    String? title,
    Object? sourceUrl = _Undefined,
    Object? mimeType = _Undefined,
    Object? extractedText = _Undefined,
    Object? summary = _Undefined,
    Object? keyFieldsJson = _Undefined,
    String? status,
    Object? errorMessage = _Undefined,
  }) {
    return Document(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      sourceUrl: sourceUrl is String? ? sourceUrl : this.sourceUrl,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      extractedText: extractedText is String?
          ? extractedText
          : this.extractedText,
      summary: summary is String? ? summary : this.summary,
      keyFieldsJson: keyFieldsJson is String?
          ? keyFieldsJson
          : this.keyFieldsJson,
      status: status ?? this.status,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
