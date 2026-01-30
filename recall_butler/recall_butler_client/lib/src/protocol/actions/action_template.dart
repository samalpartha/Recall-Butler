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
import 'package:recall_butler_client/src/protocol/protocol.dart' as _i2;

abstract class ActionTemplate implements _i1.SerializableModel {
  ActionTemplate._({
    required this.type,
    required this.description,
    required this.requiredFields,
    required this.example,
  });

  factory ActionTemplate({
    required String type,
    required String description,
    required List<String> requiredFields,
    required String example,
  }) = _ActionTemplateImpl;

  factory ActionTemplate.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionTemplate(
      type: jsonSerialization['type'] as String,
      description: jsonSerialization['description'] as String,
      requiredFields: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['requiredFields'],
      ),
      example: jsonSerialization['example'] as String,
    );
  }

  String type;

  String description;

  List<String> requiredFields;

  String example;

  /// Returns a shallow copy of this [ActionTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ActionTemplate copyWith({
    String? type,
    String? description,
    List<String>? requiredFields,
    String? example,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionTemplate',
      'type': type,
      'description': description,
      'requiredFields': requiredFields.toJson(),
      'example': example,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ActionTemplateImpl extends ActionTemplate {
  _ActionTemplateImpl({
    required String type,
    required String description,
    required List<String> requiredFields,
    required String example,
  }) : super._(
         type: type,
         description: description,
         requiredFields: requiredFields,
         example: example,
       );

  /// Returns a shallow copy of this [ActionTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ActionTemplate copyWith({
    String? type,
    String? description,
    List<String>? requiredFields,
    String? example,
  }) {
    return ActionTemplate(
      type: type ?? this.type,
      description: description ?? this.description,
      requiredFields:
          requiredFields ?? this.requiredFields.map((e0) => e0).toList(),
      example: example ?? this.example,
    );
  }
}
