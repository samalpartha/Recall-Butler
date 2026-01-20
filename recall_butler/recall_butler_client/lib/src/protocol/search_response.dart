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
import 'search_result.dart' as _i2;
import 'package:recall_butler_client/src/protocol/protocol.dart' as _i3;

abstract class SearchResponse implements _i1.SerializableModel {
  SearchResponse._({
    required this.query,
    required this.answer,
    required this.results,
    required this.totalResults,
  });

  factory SearchResponse({
    required String query,
    required String answer,
    required List<_i2.SearchResult> results,
    required int totalResults,
  }) = _SearchResponseImpl;

  factory SearchResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchResponse(
      query: jsonSerialization['query'] as String,
      answer: jsonSerialization['answer'] as String,
      results: _i3.Protocol().deserialize<List<_i2.SearchResult>>(
        jsonSerialization['results'],
      ),
      totalResults: jsonSerialization['totalResults'] as int,
    );
  }

  String query;

  String answer;

  List<_i2.SearchResult> results;

  int totalResults;

  /// Returns a shallow copy of this [SearchResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchResponse copyWith({
    String? query,
    String? answer,
    List<_i2.SearchResult>? results,
    int? totalResults,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchResponse',
      'query': query,
      'answer': answer,
      'results': results.toJson(valueToJson: (v) => v.toJson()),
      'totalResults': totalResults,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SearchResponseImpl extends SearchResponse {
  _SearchResponseImpl({
    required String query,
    required String answer,
    required List<_i2.SearchResult> results,
    required int totalResults,
  }) : super._(
         query: query,
         answer: answer,
         results: results,
         totalResults: totalResults,
       );

  /// Returns a shallow copy of this [SearchResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchResponse copyWith({
    String? query,
    String? answer,
    List<_i2.SearchResult>? results,
    int? totalResults,
  }) {
    return SearchResponse(
      query: query ?? this.query,
      answer: answer ?? this.answer,
      results: results ?? this.results.map((e0) => e0.copyWith()).toList(),
      totalResults: totalResults ?? this.totalResults,
    );
  }
}
