import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import '../providers/connectivity_provider.dart';

/// Provider for knowledge graph data
final knowledgeGraphProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getKnowledgeGraph();
});

/// Interactive Knowledge Graph Visualization
class KnowledgeGraphScreen extends ConsumerStatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  ConsumerState<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends ConsumerState<KnowledgeGraphScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  String? _selectedNodeId;
  Map<String, Offset> _nodePositions = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializePositions(List<dynamic> nodes) {
    if (_isInitialized) return;
    
    final random = math.Random(42); // Fixed seed for consistent layout
    final docNodes = nodes.where((n) => n['type'] == 'document').toList();
    final kwNodes = nodes.where((n) => n['type'] == 'keyword').toList();
    
    // Position document nodes in a circle
    for (var i = 0; i < docNodes.length; i++) {
      final angle = (i / docNodes.length) * 2 * math.pi;
      final radius = 200.0;
      _nodePositions[docNodes[i]['id']] = Offset(
        radius * math.cos(angle),
        radius * math.sin(angle),
      );
    }
    
    // Position keyword nodes in inner circle
    for (var i = 0; i < kwNodes.length; i++) {
      final angle = (i / kwNodes.length) * 2 * math.pi + math.pi / 4;
      final radius = 100.0 + random.nextDouble() * 50;
      _nodePositions[kwNodes[i]['id']] = Offset(
        radius * math.cos(angle),
        radius * math.sin(angle),
      );
    }
    
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final graphData = ref.watch(knowledgeGraphProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.network, color: AppTheme.accentTeal, size: 24),
            const SizedBox(width: 12),
            const Text('Knowledge Graph'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              _isInitialized = false;
              _nodePositions.clear();
              ref.invalidate(knowledgeGraphProvider);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.zoomIn),
            onPressed: () => setState(() => _scale = (_scale * 1.2).clamp(0.5, 3.0)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.zoomOut),
            onPressed: () => setState(() => _scale = (_scale / 1.2).clamp(0.5, 3.0)),
          ),
        ],
      ),
      body: graphData.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err.toString()),
        data: (data) => _buildGraph(data),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppTheme.accentTeal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Building knowledge graph...',
            style: TextStyle(color: AppTheme.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertTriangle, size: 64, color: AppTheme.statusFailed),
          const SizedBox(height: 16),
          Text('Failed to load graph', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: AppTheme.textMutedDark)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(knowledgeGraphProvider),
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(Map<String, dynamic> data) {
    final nodes = (data['nodes'] as List?) ?? [];
    final edges = (data['edges'] as List?) ?? [];
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    if (nodes.isEmpty) {
      return _buildEmptyState();
    }

    _initializePositions(nodes);

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                AppTheme.surfaceDark,
                AppTheme.primaryDark,
              ],
            ),
          ),
        ),

        // Graph canvas
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _panOffset += details.delta;
            });
          },
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_scale * details.scale).clamp(0.5, 3.0);
            });
          },
          child: ClipRect(
            child: CustomPaint(
              painter: _GraphPainter(
                nodes: nodes,
                edges: edges,
                nodePositions: _nodePositions,
                panOffset: _panOffset,
                scale: _scale,
                selectedNodeId: _selectedNodeId,
              ),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // Interactive node hit areas
                    ...nodes.map((node) {
                      final pos = _nodePositions[node['id']];
                      if (pos == null) return const SizedBox.shrink();
                      
                      final screenPos = _toScreenPosition(pos);
                      final isDocument = node['type'] == 'document';
                      final size = isDocument ? 40.0 : 24.0;
                      
                      return Positioned(
                        left: screenPos.dx - size / 2,
                        top: screenPos.dy - size / 2,
                        child: GestureDetector(
                          onTap: () => _selectNode(node),
                          child: Container(
                            width: size,
                            height: size,
                            color: Colors.transparent,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Stats overlay
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentTeal.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(icon: LucideIcons.fileText, label: 'Documents', value: '${stats['documents'] ?? 0}'),
                const SizedBox(height: 8),
                _StatRow(icon: LucideIcons.tag, label: 'Keywords', value: '${stats['keywords'] ?? 0}'),
                const SizedBox(height: 8),
                _StatRow(icon: LucideIcons.link, label: 'Connections', value: '${stats['connections'] ?? 0}'),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
        ),

        // Legend
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendItem(color: AppTheme.accentGold, label: 'Document'),
                const SizedBox(width: 16),
                _LegendItem(color: AppTheme.accentTeal, label: 'Keyword'),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ),

        // Selected node info
        if (_selectedNodeId != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildNodeInfo(nodes.firstWhere(
              (n) => n['id'] == _selectedNodeId,
              orElse: () => {},
            )),
          ),

        // Instructions
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.move, size: 14, color: AppTheme.textMutedDark),
                    const SizedBox(width: 6),
                    Text('Drag to pan', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.mousePointer, size: 14, color: AppTheme.textMutedDark),
                    const SizedBox(width: 6),
                    Text('Tap node for details', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.network,
            size: 80,
            color: AppTheme.textMutedDark,
          ),
          const SizedBox(height: 24),
          Text(
            'No connections yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Add more memories to see how they connect!',
            style: TextStyle(color: AppTheme.textSecondaryDark),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildNodeInfo(Map<String, dynamic> node) {
    if (node.isEmpty) return const SizedBox.shrink();
    
    final isDocument = node['type'] == 'document';
    final color = isDocument ? AppTheme.accentGold : AppTheme.accentTeal;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDocument ? LucideIcons.fileText : LucideIcons.tag,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDocument ? 'Document' : 'Keyword',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      node['label'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => setState(() => _selectedNodeId = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (isDocument && node['sourceType'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Source: ${node['sourceType']}',
                style: TextStyle(
                  color: AppTheme.textMutedDark,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1);
  }

  Offset _toScreenPosition(Offset graphPos) {
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    return center + (graphPos * _scale) + _panOffset;
  }

  void _selectNode(Map<String, dynamic> node) {
    setState(() {
      _selectedNodeId = _selectedNodeId == node['id'] ? null : node['id'];
    });
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.accentTeal),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(color: AppTheme.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<dynamic> nodes;
  final List<dynamic> edges;
  final Map<String, Offset> nodePositions;
  final Offset panOffset;
  final double scale;
  final String? selectedNodeId;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.panOffset,
    required this.scale,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw edges
    final edgePaint = Paint()
      ..color = AppTheme.textMutedDark.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final sourcePos = nodePositions[edge['source']];
      final targetPos = nodePositions[edge['target']];
      
      if (sourcePos != null && targetPos != null) {
        final start = center + (sourcePos * scale) + panOffset;
        final end = center + (targetPos * scale) + panOffset;
        
        // Highlight edges connected to selected node
        if (selectedNodeId != null && 
            (edge['source'] == selectedNodeId || edge['target'] == selectedNodeId)) {
          edgePaint.color = AppTheme.accentTeal.withOpacity(0.6);
          edgePaint.strokeWidth = 2.5;
        } else {
          edgePaint.color = AppTheme.textMutedDark.withOpacity(0.3);
          edgePaint.strokeWidth = 1.5;
        }
        
        canvas.drawLine(start, end, edgePaint);
      }
    }

    // Draw nodes
    for (final node in nodes) {
      final pos = nodePositions[node['id']];
      if (pos == null) continue;
      
      final screenPos = center + (pos * scale) + panOffset;
      final isDocument = node['type'] == 'document';
      final isSelected = node['id'] == selectedNodeId;
      
      final nodeColor = isDocument ? AppTheme.accentGold : AppTheme.accentTeal;
      final radius = (isDocument ? 18.0 : 10.0) * scale;
      
      // Glow effect for selected node
      if (isSelected) {
        final glowPaint = Paint()
          ..color = nodeColor.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        canvas.drawCircle(screenPos, radius * 1.5, glowPaint);
      }
      
      // Node fill
      final fillPaint = Paint()
        ..color = isSelected ? nodeColor : nodeColor.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(screenPos, radius, fillPaint);
      
      // Node border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : nodeColor
        ..strokeWidth = isSelected ? 3 : 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(screenPos, radius, borderPaint);
      
      // Draw icon placeholder (simplified)
      if (isDocument && scale > 0.7) {
        final iconPaint = Paint()
          ..color = AppTheme.primaryDark
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        
        // Simple file icon
        final iconSize = radius * 0.6;
        canvas.drawRect(
          Rect.fromCenter(center: screenPos, width: iconSize, height: iconSize * 1.2),
          iconPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.panOffset != panOffset ||
           oldDelegate.scale != scale ||
           oldDelegate.selectedNodeId != selectedNodeId;
  }
}
