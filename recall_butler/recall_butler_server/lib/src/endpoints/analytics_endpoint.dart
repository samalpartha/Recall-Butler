import 'package:serverpod/serverpod.dart';

/// Analytics endpoint for usage statistics and insights
class AnalyticsEndpoint extends Endpoint {
  /// Get overall analytics summary
  Future<Map<String, dynamic>> getSummary(Session session) async {
    // Get document counts from database
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // Query documents stats
    final totalDocuments = await session.db.query(
      'SELECT COUNT(*) as count FROM documents',
    );
    final documentsThisWeek = await session.db.query(
      'SELECT COUNT(*) as count FROM documents WHERE created_at >= \$1',
      parameters: [sevenDaysAgo],
    );
    final documentsThisMonth = await session.db.query(
      'SELECT COUNT(*) as count FROM documents WHERE created_at >= \$1',
      parameters: [thirtyDaysAgo],
    );
    
    // Query suggestions stats
    final totalSuggestions = await session.db.query(
      'SELECT COUNT(*) as count FROM suggestions',
    );
    final acceptedSuggestions = await session.db.query(
      'SELECT COUNT(*) as count FROM suggestions WHERE status = \'accepted\'',
    );
    final pendingSuggestions = await session.db.query(
      'SELECT COUNT(*) as count FROM suggestions WHERE status = \'pending\'',
    );
    
    // Query search stats
    final totalSearches = await session.db.query(
      'SELECT COUNT(*) as count FROM search_logs',
    );
    final searchesThisWeek = await session.db.query(
      'SELECT COUNT(*) as count FROM search_logs WHERE created_at >= \$1',
      parameters: [sevenDaysAgo],
    );
    
    return {
      'documents': {
        'total': _extractCount(totalDocuments),
        'thisWeek': _extractCount(documentsThisWeek),
        'thisMonth': _extractCount(documentsThisMonth),
        'growth': _calculateGrowth(
          _extractCount(documentsThisMonth),
          _extractCount(totalDocuments),
        ),
      },
      'suggestions': {
        'total': _extractCount(totalSuggestions),
        'accepted': _extractCount(acceptedSuggestions),
        'pending': _extractCount(pendingSuggestions),
        'acceptanceRate': _calculateRate(
          _extractCount(acceptedSuggestions),
          _extractCount(totalSuggestions),
        ),
      },
      'searches': {
        'total': _extractCount(totalSearches),
        'thisWeek': _extractCount(searchesThisWeek),
      },
      'timestamp': now.toIso8601String(),
    };
  }

  /// Get document activity over time (last 30 days)
  Future<List<Map<String, dynamic>>> getActivityTimeline(Session session) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final result = await session.db.query('''
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as documents_added,
        SUM(CASE WHEN status = 'ready' THEN 1 ELSE 0 END) as processed
      FROM documents
      WHERE created_at >= \$1
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    ''', parameters: [thirtyDaysAgo]);
    
    return result.map((row) => {
      'date': row[0]?.toString() ?? '',
      'documentsAdded': row[1] ?? 0,
      'processed': row[2] ?? 0,
    }).toList();
  }

  /// Get document type distribution
  Future<List<Map<String, dynamic>>> getDocumentTypes(Session session) async {
    final result = await session.db.query('''
      SELECT 
        COALESCE(content_type, 'unknown') as type,
        COUNT(*) as count
      FROM documents
      GROUP BY content_type
      ORDER BY count DESC
    ''');
    
    return result.map((row) => {
      'type': row[0]?.toString() ?? 'unknown',
      'count': row[1] ?? 0,
    }).toList();
  }

  /// Get top search queries
  Future<List<Map<String, dynamic>>> getTopSearches(Session session, {int limit = 10}) async {
    final result = await session.db.query('''
      SELECT 
        query,
        COUNT(*) as count,
        AVG(results_count) as avg_results
      FROM search_logs
      GROUP BY query
      ORDER BY count DESC
      LIMIT \$1
    ''', parameters: [limit]);
    
    return result.map((row) => {
      'query': row[0]?.toString() ?? '',
      'count': row[1] ?? 0,
      'avgResults': (row[2] as num?)?.toDouble() ?? 0.0,
    }).toList();
  }

  /// Get memory insights (AI-generated observations)
  Future<Map<String, dynamic>> getInsights(Session session) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // Get recent activity metrics
    final recentDocs = await session.db.query(
      'SELECT COUNT(*) FROM documents WHERE created_at >= \$1',
      parameters: [sevenDaysAgo],
    );
    final recentSearches = await session.db.query(
      'SELECT COUNT(*) FROM search_logs WHERE created_at >= \$1',
      parameters: [sevenDaysAgo],
    );
    final pendingSuggestions = await session.db.query(
      'SELECT COUNT(*) FROM suggestions WHERE status = \'pending\'',
    );
    
    final docCount = _extractCount(recentDocs);
    final searchCount = _extractCount(recentSearches);
    final pendingCount = _extractCount(pendingSuggestions);
    
    // Generate insights based on activity
    final insights = <Map<String, dynamic>>[];
    
    if (docCount > 10) {
      insights.add({
        'type': 'productivity',
        'icon': '🚀',
        'title': 'High Activity Week!',
        'description': 'You added $docCount memories this week. Keep up the great work!',
        'priority': 'high',
      });
    } else if (docCount == 0) {
      insights.add({
        'type': 'engagement',
        'icon': '💡',
        'title': 'Time to capture memories',
        'description': 'No new memories this week. Try adding some notes or documents!',
        'priority': 'medium',
      });
    }
    
    if (pendingCount > 5) {
      insights.add({
        'type': 'action',
        'icon': '⏰',
        'title': 'Pending Reminders',
        'description': 'You have $pendingCount suggestions waiting for your review.',
        'priority': 'high',
      });
    }
    
    if (searchCount > 20) {
      insights.add({
        'type': 'usage',
        'icon': '🔍',
        'title': 'Power Searcher',
        'description': 'You\'ve searched $searchCount times this week. Your memory is well organized!',
        'priority': 'low',
      });
    }
    
    // Add a default insight if none were generated
    if (insights.isEmpty) {
      insights.add({
        'type': 'welcome',
        'icon': '✨',
        'title': 'Your Memory Dashboard',
        'description': 'Track your memory patterns and discover insights here.',
        'priority': 'low',
      });
    }
    
    return {
      'insights': insights,
      'metrics': {
        'recentDocuments': docCount,
        'recentSearches': searchCount,
        'pendingSuggestions': pendingCount,
      },
      'generatedAt': now.toIso8601String(),
    };
  }

  /// Get knowledge graph data (connections between documents)
  Future<Map<String, dynamic>> getKnowledgeGraph(Session session) async {
    // Get documents with their key fields for node generation
    final documents = await session.db.query('''
      SELECT id, title, key_fields, created_at
      FROM documents
      WHERE status = 'ready'
      ORDER BY created_at DESC
      LIMIT 100
    ''');
    
    // Build nodes
    final nodes = <Map<String, dynamic>>[];
    final edges = <Map<String, dynamic>>[];
    final keyFieldsMap = <String, List<int>>{}; // keyword -> document indices
    
    for (var i = 0; i < documents.length; i++) {
      final row = documents[i];
      final docId = row[0];
      final title = row[1]?.toString() ?? 'Untitled';
      final keyFieldsJson = row[2]?.toString();
      
      nodes.add({
        'id': 'doc_$docId',
        'label': title.length > 30 ? '${title.substring(0, 30)}...' : title,
        'type': 'document',
        'size': 20,
      });
      
      // Parse key fields to find connections
      if (keyFieldsJson != null && keyFieldsJson.isNotEmpty) {
        try {
          // Extract keywords from key_fields (simplified)
          final keywords = _extractKeywords(keyFieldsJson);
          for (final keyword in keywords) {
            keyFieldsMap.putIfAbsent(keyword, () => []);
            keyFieldsMap[keyword]!.add(i);
          }
        } catch (_) {}
      }
    }
    
    // Create edges based on shared keywords
    keyFieldsMap.forEach((keyword, docIndices) {
      if (docIndices.length > 1 && docIndices.length <= 5) {
        // Add keyword node
        final keywordNodeId = 'kw_$keyword';
        nodes.add({
          'id': keywordNodeId,
          'label': keyword,
          'type': 'keyword',
          'size': 10,
        });
        
        // Connect documents to keyword
        for (final docIndex in docIndices) {
          edges.add({
            'source': 'doc_${documents[docIndex][0]}',
            'target': keywordNodeId,
            'weight': 1,
          });
        }
      }
    });
    
    return {
      'nodes': nodes,
      'edges': edges,
      'stats': {
        'totalNodes': nodes.length,
        'totalEdges': edges.length,
        'documents': documents.length,
      },
    };
  }

  // Helper methods
  int _extractCount(List<List<dynamic>> result) {
    if (result.isEmpty || result[0].isEmpty) return 0;
    return (result[0][0] as num?)?.toInt() ?? 0;
  }
  
  double _calculateGrowth(int recent, int total) {
    if (total == 0) return 0.0;
    return (recent / total * 100).clamp(0, 100);
  }
  
  double _calculateRate(int numerator, int denominator) {
    if (denominator == 0) return 0.0;
    return (numerator / denominator * 100).clamp(0, 100);
  }
  
  List<String> _extractKeywords(String jsonStr) {
    // Simple keyword extraction from JSON string
    final keywords = <String>[];
    final regex = RegExp(r'"([^"]+)"');
    final matches = regex.allMatches(jsonStr);
    for (final match in matches) {
      final word = match.group(1)?.toLowerCase();
      if (word != null && word.length > 3 && word.length < 20) {
        keywords.add(word);
      }
    }
    return keywords.take(5).toList();
  }
}
