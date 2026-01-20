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

abstract class SearchResult implements _i1.SerializableModel {
  SearchResult._({
    required this.documentId,
    required this.chunkId,
    required this.title,
    required this.snippet,
    required this.sourceType,
    required this.similarity,
  });

  factory SearchResult({
    required int documentId,
    required int chunkId,
    required String title,
    required String snippet,
    required String sourceType,
    required double similarity,
  }) = _SearchResultImpl;

  factory SearchResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchResult(
      documentId: jsonSerialization['documentId'] as int,
      chunkId: jsonSerialization['chunkId'] as int,
      title: jsonSerialization['title'] as String,
      snippet: jsonSerialization['snippet'] as String,
      sourceType: jsonSerialization['sourceType'] as String,
      similarity: (jsonSerialization['similarity'] as num).toDouble(),
    );
  }

  int documentId;

  int chunkId;

  String title;

  String snippet;

  String sourceType;

  double similarity;

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchResult copyWith({
    int? documentId,
    int? chunkId,
    String? title,
    String? snippet,
    String? sourceType,
    double? similarity,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchResult',
      'documentId': documentId,
      'chunkId': chunkId,
      'title': title,
      'snippet': snippet,
      'sourceType': sourceType,
      'similarity': similarity,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SearchResultImpl extends SearchResult {
  _SearchResultImpl({
    required int documentId,
    required int chunkId,
    required String title,
    required String snippet,
    required String sourceType,
    required double similarity,
  }) : super._(
         documentId: documentId,
         chunkId: chunkId,
         title: title,
         snippet: snippet,
         sourceType: sourceType,
         similarity: similarity,
       );

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchResult copyWith({
    int? documentId,
    int? chunkId,
    String? title,
    String? snippet,
    String? sourceType,
    double? similarity,
  }) {
    return SearchResult(
      documentId: documentId ?? this.documentId,
      chunkId: chunkId ?? this.chunkId,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      sourceType: sourceType ?? this.sourceType,
      similarity: similarity ?? this.similarity,
    );
  }
}
