import 'dart:math';
import 'package:serverpod/serverpod.dart';
import 'ai_service.dart';
import 'vector_search_service.dart';
import 'logger_service.dart';

/// Smart Document Linking Service
/// Automatically discovers and creates connections between related documents
class SmartLinkingService {
  static final SmartLinkingService _instance = SmartLinkingService._internal();
  factory SmartLinkingService() => _instance;
  SmartLinkingService._internal();

  final _aiService = AiService();
  final _vectorSearch = VectorSearchService();

  // Knowledge graph: entity -> related entities with relationship type
  final Map<String, List<EntityRelation>> _knowledgeGraph = {};
  
  // Document links: documentId -> linked documents with link type
  final Map<int, List<DocumentLink>> _documentLinks = {};
  
  // Extracted entities: documentId -> entities
  final Map<int, List<ExtractedEntity>> _documentEntities = {};

  /// Process a document and extract entities/links
  Future<DocumentAnalysis> analyzeDocument({
    required Session session,
    required int documentId,
    required String title,
    required String content,
    int userId = 1,
  }) async {
    logger.info('Analyzing document for smart linking', context: {
      'documentId': documentId,
    });

    // Extract entities using AI
    final entities = await _extractEntities(content, title);
    _documentEntities[documentId] = entities;

    // Find related documents
    final relatedDocs = await _findRelatedDocuments(session, documentId, content);
    _documentLinks[documentId] = relatedDocs;

    // Build knowledge graph connections
    for (final entity in entities) {
      _addToKnowledgeGraph(entity, documentId);
    }

    // Generate insights about the document
    final insights = await _generateInsights(entities, relatedDocs);

    logger.info('Document analysis complete', context: {
      'documentId': documentId,
      'entitiesFound': entities.length,
      'relatedDocs': relatedDocs.length,
    });

    return DocumentAnalysis(
      documentId: documentId,
      entities: entities,
      relatedDocuments: relatedDocs,
      insights: insights,
      analyzedAt: DateTime.now(),
    );
  }

  /// Get knowledge graph for visualization
  KnowledgeGraph getKnowledgeGraph({int? userId, int maxNodes = 100}) {
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];
    final addedNodes = <String>{};

    var nodeCount = 0;
    for (final entry in _knowledgeGraph.entries) {
      if (nodeCount >= maxNodes) break;

      final entityKey = entry.key;
      if (!addedNodes.contains(entityKey)) {
        nodes.add(GraphNode(
          id: entityKey,
          label: entityKey,
          type: _getEntityType(entityKey),
          weight: entry.value.length.toDouble(),
        ));
        addedNodes.add(entityKey);
        nodeCount++;
      }

      for (final relation in entry.value) {
        if (!addedNodes.contains(relation.targetEntity) && nodeCount < maxNodes) {
          nodes.add(GraphNode(
            id: relation.targetEntity,
            label: relation.targetEntity,
            type: _getEntityType(relation.targetEntity),
            weight: 1,
          ));
          addedNodes.add(relation.targetEntity);
          nodeCount++;
        }

        if (addedNodes.contains(relation.targetEntity)) {
          edges.add(GraphEdge(
            source: entityKey,
            target: relation.targetEntity,
            relationship: relation.relationship,
            weight: relation.strength,
          ));
        }
      }
    }

    return KnowledgeGraph(
      nodes: nodes,
      edges: edges,
      generatedAt: DateTime.now(),
    );
  }

  /// Get related documents for a given document
  List<DocumentLink> getRelatedDocuments(int documentId) {
    return _documentLinks[documentId] ?? [];
  }

  /// Get documents related to an entity
  List<int> getDocumentsByEntity(String entity) {
    final normalizedEntity = entity.toLowerCase();
    final documents = <int>[];

    for (final entry in _documentEntities.entries) {
      if (entry.value.any((e) => e.name.toLowerCase().contains(normalizedEntity))) {
        documents.add(entry.key);
      }
    }

    return documents;
  }

  /// Suggest new connections based on patterns
  Future<List<SuggestedConnection>> suggestConnections({
    required Session session,
    required int userId,
    int limit = 5,
  }) async {
    final suggestions = <SuggestedConnection>[];

    // Find documents that share entities but aren't linked
    final docPairs = <String, double>{};

    for (final doc1 in _documentEntities.keys) {
      for (final doc2 in _documentEntities.keys) {
        if (doc1 >= doc2) continue;

        final entities1 = _documentEntities[doc1]!.map((e) => e.name.toLowerCase()).toSet();
        final entities2 = _documentEntities[doc2]!.map((e) => e.name.toLowerCase()).toSet();

        final shared = entities1.intersection(entities2);
        if (shared.isNotEmpty) {
          final score = shared.length / max(entities1.length, entities2.length);
          docPairs['$doc1-$doc2'] = score;
        }
      }
    }

    // Sort by score and take top suggestions
    final sortedPairs = docPairs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final pair in sortedPairs.take(limit)) {
      final ids = pair.key.split('-').map(int.parse).toList();
      
      // Skip if already linked
      if (_documentLinks[ids[0]]?.any((l) => l.targetDocumentId == ids[1]) ?? false) {
        continue;
      }

      final sharedEntities = _documentEntities[ids[0]]!
          .where((e1) => _documentEntities[ids[1]]!.any(
              (e2) => e1.name.toLowerCase() == e2.name.toLowerCase()))
          .map((e) => e.name)
          .toList();

      suggestions.add(SuggestedConnection(
        sourceDocumentId: ids[0],
        targetDocumentId: ids[1],
        confidence: pair.value,
        reason: 'Shared concepts: ${sharedEntities.join(", ")}',
        sharedEntities: sharedEntities,
      ));
    }

    return suggestions;
  }

  /// Search within knowledge graph
  Future<List<GraphSearchResult>> searchGraph({
    required String query,
    int limit = 10,
  }) async {
    final results = <GraphSearchResult>[];
    final queryLower = query.toLowerCase();

    for (final entry in _knowledgeGraph.entries) {
      if (entry.key.toLowerCase().contains(queryLower)) {
        final documentIds = _getDocumentsByEntity(entry.key);
        
        results.add(GraphSearchResult(
          entity: entry.key,
          type: _getEntityType(entry.key),
          connectionCount: entry.value.length,
          documentCount: documentIds.length,
          relatedEntities: entry.value.map((r) => r.targetEntity).take(5).toList(),
        ));
      }
    }

    results.sort((a, b) => b.connectionCount.compareTo(a.connectionCount));
    return results.take(limit).toList();
  }

  // Private helper methods

  Future<List<ExtractedEntity>> _extractEntities(String content, String title) async {
    try {
      final prompt = '''
Extract key entities from this document. For each entity, identify:
1. The entity name
2. The entity type (person, organization, concept, date, location, project, technology)
3. Importance score (0.0-1.0)

Document title: $title

Content:
${content.substring(0, min(2000, content.length))}

Respond in this exact JSON format:
{
  "entities": [
    {"name": "Entity Name", "type": "concept", "importance": 0.8},
    ...
  ]
}
''';

      final response = await _aiService.chat([
        {'role': 'system', 'content': 'You are an entity extraction expert. Extract entities in the exact JSON format requested.'},
        {'role': 'user', 'content': prompt},
      ]);

      // Parse response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        final entitiesList = json['entities'] as List;
        
        return entitiesList.map((e) => ExtractedEntity(
          name: e['name'] ?? 'Unknown',
          type: EntityType.values.firstWhere(
            (t) => t.name == (e['type'] ?? 'concept'),
            orElse: () => EntityType.concept,
          ),
          importance: (e['importance'] ?? 0.5).toDouble(),
        )).toList();
      }
    } catch (e) {
      logger.error('Entity extraction failed', error: e);
    }

    // Fallback: extract simple keywords
    return _extractKeywords(content, title);
  }

  List<ExtractedEntity> _extractKeywords(String content, String title) {
    final words = '$title $content'.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toList();

    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }

    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(10).map((e) => ExtractedEntity(
      name: e.key,
      type: EntityType.concept,
      importance: min(1.0, e.value / 10),
    )).toList();
  }

  Future<List<DocumentLink>> _findRelatedDocuments(
    Session session,
    int documentId,
    String content,
  ) async {
    final results = await _vectorSearch.findSimilar(
      session: session,
      documentId: documentId,
      limit: 5,
    );

    return results.map((r) => DocumentLink(
      targetDocumentId: r.documentId,
      linkType: LinkType.semantic,
      strength: r.score,
      reason: 'Content similarity: ${(r.score * 100).toStringAsFixed(1)}%',
    )).toList();
  }

  void _addToKnowledgeGraph(ExtractedEntity entity, int documentId) {
    final key = entity.name.toLowerCase();
    _knowledgeGraph[key] ??= [];

    // Find other entities in the same document to create relations
    final docEntities = _documentEntities[documentId] ?? [];
    for (final other in docEntities) {
      if (other.name.toLowerCase() != key) {
        _knowledgeGraph[key]!.add(EntityRelation(
          targetEntity: other.name.toLowerCase(),
          relationship: 'co-occurs with',
          strength: (entity.importance + other.importance) / 2,
          documentId: documentId,
        ));
      }
    }
  }

  Future<List<String>> _generateInsights(
    List<ExtractedEntity> entities,
    List<DocumentLink> relatedDocs,
  ) async {
    final insights = <String>[];

    // Top entities insight
    final topEntities = entities.where((e) => e.importance > 0.6).toList();
    if (topEntities.isNotEmpty) {
      insights.add('Key concepts: ${topEntities.map((e) => e.name).join(", ")}');
    }

    // Related documents insight
    if (relatedDocs.isNotEmpty) {
      insights.add('Found ${relatedDocs.length} related documents');
    }

    // Entity diversity insight
    final entityTypes = entities.map((e) => e.type).toSet();
    if (entityTypes.length > 2) {
      insights.add('This document spans multiple domains: ${entityTypes.map((t) => t.name).join(", ")}');
    }

    return insights;
  }

  List<int> _getDocumentsByEntity(String entity) {
    final documents = <int>[];
    for (final entry in _documentEntities.entries) {
      if (entry.value.any((e) => e.name.toLowerCase() == entity.toLowerCase())) {
        documents.add(entry.key);
      }
    }
    return documents;
  }

  String _getEntityType(String entity) {
    // Check if we have type info
    for (final docs in _documentEntities.values) {
      for (final e in docs) {
        if (e.name.toLowerCase() == entity.toLowerCase()) {
          return e.type.name;
        }
      }
    }
    return 'concept';
  }
}

/// Entity types
enum EntityType {
  person,
  organization,
  concept,
  date,
  location,
  project,
  technology,
}

/// Extracted entity
class ExtractedEntity {
  final String name;
  final EntityType type;
  final double importance;

  ExtractedEntity({
    required this.name,
    required this.type,
    required this.importance,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'importance': importance,
  };
}

/// Entity relation in knowledge graph
class EntityRelation {
  final String targetEntity;
  final String relationship;
  final double strength;
  final int documentId;

  EntityRelation({
    required this.targetEntity,
    required this.relationship,
    required this.strength,
    required this.documentId,
  });
}

/// Link types between documents
enum LinkType {
  semantic,
  explicit,
  temporal,
  entity,
  hierarchical,
}

/// Document link
class DocumentLink {
  final int targetDocumentId;
  final LinkType linkType;
  final double strength;
  final String reason;

  DocumentLink({
    required this.targetDocumentId,
    required this.linkType,
    required this.strength,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'targetDocumentId': targetDocumentId,
    'linkType': linkType.name,
    'strength': strength,
    'reason': reason,
  };
}

/// Document analysis result
class DocumentAnalysis {
  final int documentId;
  final List<ExtractedEntity> entities;
  final List<DocumentLink> relatedDocuments;
  final List<String> insights;
  final DateTime analyzedAt;

  DocumentAnalysis({
    required this.documentId,
    required this.entities,
    required this.relatedDocuments,
    required this.insights,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'entities': entities.map((e) => e.toJson()).toList(),
    'relatedDocuments': relatedDocuments.map((d) => d.toJson()).toList(),
    'insights': insights,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}

/// Knowledge graph for visualization
class KnowledgeGraph {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final DateTime generatedAt;

  KnowledgeGraph({
    required this.nodes,
    required this.edges,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
  };
}

/// Graph node
class GraphNode {
  final String id;
  final String label;
  final String type;
  final double weight;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type,
    'weight': weight,
  };
}

/// Graph edge
class GraphEdge {
  final String source;
  final String target;
  final String relationship;
  final double weight;

  GraphEdge({
    required this.source,
    required this.target,
    required this.relationship,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'source': source,
    'target': target,
    'relationship': relationship,
    'weight': weight,
  };
}

/// Suggested connection
class SuggestedConnection {
  final int sourceDocumentId;
  final int targetDocumentId;
  final double confidence;
  final String reason;
  final List<String> sharedEntities;

  SuggestedConnection({
    required this.sourceDocumentId,
    required this.targetDocumentId,
    required this.confidence,
    required this.reason,
    required this.sharedEntities,
  });

  Map<String, dynamic> toJson() => {
    'sourceDocumentId': sourceDocumentId,
    'targetDocumentId': targetDocumentId,
    'confidence': confidence,
    'reason': reason,
    'sharedEntities': sharedEntities,
  };
}

/// Graph search result
class GraphSearchResult {
  final String entity;
  final String type;
  final int connectionCount;
  final int documentCount;
  final List<String> relatedEntities;

  GraphSearchResult({
    required this.entity,
    required this.type,
    required this.connectionCount,
    required this.documentCount,
    required this.relatedEntities,
  });

  Map<String, dynamic> toJson() => {
    'entity': entity,
    'type': type,
    'connectionCount': connectionCount,
    'documentCount': documentCount,
    'relatedEntities': relatedEntities,
  };
}
