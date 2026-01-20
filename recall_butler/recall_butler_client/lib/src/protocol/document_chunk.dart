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

abstract class DocumentChunk implements _i1.SerializableModel {
  DocumentChunk._({
    this.id,
    required this.documentId,
    required this.chunkIndex,
    required this.text,
    this.embeddingJson,
  });

  factory DocumentChunk({
    int? id,
    required int documentId,
    required int chunkIndex,
    required String text,
    String? embeddingJson,
  }) = _DocumentChunkImpl;

  factory DocumentChunk.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentChunk(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      chunkIndex: jsonSerialization['chunkIndex'] as int,
      text: jsonSerialization['text'] as String,
      embeddingJson: jsonSerialization['embeddingJson'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int documentId;

  int chunkIndex;

  String text;

  String? embeddingJson;

  /// Returns a shallow copy of this [DocumentChunk]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DocumentChunk copyWith({
    int? id,
    int? documentId,
    int? chunkIndex,
    String? text,
    String? embeddingJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentChunk',
      if (id != null) 'id': id,
      'documentId': documentId,
      'chunkIndex': chunkIndex,
      'text': text,
      if (embeddingJson != null) 'embeddingJson': embeddingJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentChunkImpl extends DocumentChunk {
  _DocumentChunkImpl({
    int? id,
    required int documentId,
    required int chunkIndex,
    required String text,
    String? embeddingJson,
  }) : super._(
         id: id,
         documentId: documentId,
         chunkIndex: chunkIndex,
         text: text,
         embeddingJson: embeddingJson,
       );

  /// Returns a shallow copy of this [DocumentChunk]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DocumentChunk copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? chunkIndex,
    String? text,
    Object? embeddingJson = _Undefined,
  }) {
    return DocumentChunk(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      text: text ?? this.text,
      embeddingJson: embeddingJson is String?
          ? embeddingJson
          : this.embeddingJson,
    );
  }
}
