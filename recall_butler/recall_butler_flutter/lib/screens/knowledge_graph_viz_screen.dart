import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

/// Interactive Knowledge Graph Visualization
class KnowledgeGraphVizScreen extends StatefulWidget {
  const KnowledgeGraphVizScreen({super.key});

  @override
  State<KnowledgeGraphVizScreen> createState() => _KnowledgeGraphVizScreenState();
}

class _KnowledgeGraphVizScreenState extends State<KnowledgeGraphVizScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedNode;
  final _transformationController = TransformationController();
  
  // Sample graph data
  final List<GraphNode> _nodes = [
    GraphNode(id: 'project-alpha', label: 'Project Alpha', type: 'project', x: 0.5, y: 0.3),
    GraphNode(id: 'meeting-notes', label: 'Meeting Notes', type: 'document', x: 0.3, y: 0.5),
    GraphNode(id: 'budget', label: 'Budget Planning', type: 'document', x: 0.7, y: 0.5),
    GraphNode(id: 'team', label: 'Team Resources', type: 'concept', x: 0.2, y: 0.7),
    GraphNode(id: 'deadline', label: 'Q1 Deadline', type: 'date', x: 0.8, y: 0.3),
    GraphNode(id: 'john', label: 'John Smith', type: 'person', x: 0.4, y: 0.8),
    GraphNode(id: 'tech-specs', label: 'Tech Specs', type: 'document', x: 0.6, y: 0.7),
    GraphNode(id: 'client', label: 'Client XYZ', type: 'organization', x: 0.15, y: 0.35),
  ];

  final List<GraphEdge> _edges = [
    GraphEdge(from: 'project-alpha', to: 'meeting-notes', label: 'discussed in'),
    GraphEdge(from: 'project-alpha', to: 'budget', label: 'requires'),
    GraphEdge(from: 'project-alpha', to: 'deadline', label: 'due by'),
    GraphEdge(from: 'meeting-notes', to: 'john', label: 'attended by'),
    GraphEdge(from: 'meeting-notes', to: 'team', label: 'involves'),
    GraphEdge(from: 'budget', to: 'tech-specs', label: 'includes'),
    GraphEdge(from: 'team', to: 'john', label: 'includes'),
    GraphEdge(from: 'project-alpha', to: 'client', label: 'for'),
    GraphEdge(from: 'tech-specs', to: 'deadline', label: 'due by'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'project':
        return AppTheme.accentGold;
      case 'document':
        return AppTheme.accentTeal;
      case 'concept':
        return Colors.purple;
      case 'person':
        return Colors.pink;
      case 'organization':
        return Colors.blue;
      case 'date':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNodeIcon(String type) {
    switch (type) {
      case 'project':
        return LucideIcons.folder;
      case 'document':
        return LucideIcons.fileText;
      case 'concept':
        return LucideIcons.lightbulb;
      case 'person':
        return LucideIcons.user;
      case 'organization':
        return LucideIcons.building2;
      case 'date':
        return LucideIcons.calendar;
      default:
        return LucideIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  AppTheme.accentGold.withOpacity(0.05),
                  AppTheme.primaryDark,
                ],
              ),
            ),
          ),
          
          // Graph visualization
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 3.0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 2,
              height: MediaQuery.of(context).size.height * 2,
              child: CustomPaint(
                painter: GraphPainter(
                  nodes: _nodes,
                  edges: _edges,
                  selectedNode: _selectedNode,
                  pulseValue: _pulseController.value,
                  getNodeColor: _getNodeColor,
                ),
                child: Stack(
                  children: _nodes.map((node) {
                    final size = MediaQuery.of(context).size;
                    final x = node.x * size.width * 2;
                    final y = node.y * size.height * 2;
                    
                    return Positioned(
                      left: x - 35,
                      top: y - 35,
                      child: _buildNode(node),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          // Top bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Knowledge Graph',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_nodes.length} nodes • ${_edges.length} connections',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFilterButton(),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.maximize2),
                    onPressed: _resetView,
                    tooltip: 'Reset View',
                  ),
                ],
              ),
            ),
          ),
          
          // Legend
          Positioned(
            left: 16,
            bottom: 100,
            child: _buildLegend(),
          ),
          
          // Selected node details
          if (_selectedNode != null)
            Positioned(
              right: 16,
              bottom: 100,
              child: _buildNodeDetails(),
            ),
          
          // Search FAB
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.extended(
              onPressed: _showSearchDialog,
              backgroundColor: AppTheme.accentGold,
              icon: const Icon(LucideIcons.search, color: Colors.black),
              label: const Text('Search', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(GraphNode node) {
    final isSelected = _selectedNode == node.id;
    final color = _getNodeColor(node.type);
    final icon = _getNodeIcon(node.type);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedNode = isSelected ? null : node.id),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isSelected ? 1.0 + (_pulseController.value * 0.1) : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(isSelected ? 0.3 : 0.15),
                    border: Border.all(
                      color: color,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.surfaceDark.withOpacity(0.9),
                  ),
                  child: Text(
                    node.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().scale(
      duration: 500.ms,
      curve: Curves.elasticOut,
    );
  }

  Widget _buildLegend() {
    final types = [
      {'type': 'project', 'label': 'Project'},
      {'type': 'document', 'label': 'Document'},
      {'type': 'concept', 'label': 'Concept'},
      {'type': 'person', 'label': 'Person'},
      {'type': 'organization', 'label': 'Organization'},
      {'type': 'date', 'label': 'Date'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surfaceDark.withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...types.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getNodeColor(t['type']!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t['label']!,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2);
  }

  Widget _buildNodeDetails() {
    final node = _nodes.firstWhere((n) => n.id == _selectedNode);
    final connections = _edges.where(
      (e) => e.from == _selectedNode || e.to == _selectedNode
    ).toList();

    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceDark.withOpacity(0.95),
        border: Border.all(color: _getNodeColor(node.type).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _getNodeColor(node.type).withOpacity(0.2),
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
                  shape: BoxShape.circle,
                  color: _getNodeColor(node.type).withOpacity(0.2),
                ),
                child: Icon(
                  _getNodeIcon(node.type),
                  color: _getNodeColor(node.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      node.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getNodeColor(node.type),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => setState(() => _selectedNode = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            'Connections (${connections.length})',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMutedDark,
            ),
          ),
          const SizedBox(height: 8),
          ...connections.take(5).map((edge) {
            final targetId = edge.from == _selectedNode ? edge.to : edge.from;
            final targetNode = _nodes.firstWhere((n) => n.id == targetId);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _getNodeIcon(targetNode.type),
                    size: 14,
                    color: _getNodeColor(targetNode.type),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      targetNode.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    edge.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMutedDark,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getNodeColor(node.type),
                side: BorderSide(color: _getNodeColor(node.type)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.filter),
      tooltip: 'Filter',
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('All Types')),
        const PopupMenuItem(value: 'project', child: Text('Projects')),
        const PopupMenuItem(value: 'document', child: Text('Documents')),
        const PopupMenuItem(value: 'person', child: Text('People')),
      ],
      onSelected: (value) {
        // Filter logic
      },
    );
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Search Graph'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search nodes...',
            prefixIcon: const Icon(LucideIcons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

// Graph data models
class GraphNode {
  final String id;
  final String label;
  final String type;
  final double x;
  final double y;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.x,
    required this.y,
  });
}

class GraphEdge {
  final String from;
  final String to;
  final String label;

  GraphEdge({
    required this.from,
    required this.to,
    required this.label,
  });
}

// Custom painter for graph edges
class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final String? selectedNode;
  final double pulseValue;
  final Color Function(String) getNodeColor;

  GraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNode,
    required this.pulseValue,
    required this.getNodeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final fromNode = nodes.firstWhere((n) => n.id == edge.from);
      final toNode = nodes.firstWhere((n) => n.id == edge.to);
      
      final fromPoint = Offset(fromNode.x * size.width, fromNode.y * size.height);
      final toPoint = Offset(toNode.x * size.width, toNode.y * size.height);
      
      final isHighlighted = selectedNode == edge.from || selectedNode == edge.to;
      
      final paint = Paint()
        ..color = isHighlighted 
          ? getNodeColor(fromNode.type).withOpacity(0.8)
          : Colors.white.withOpacity(0.15)
        ..strokeWidth = isHighlighted ? 2 : 1
        ..style = PaintingStyle.stroke;

      // Draw curved line
      final controlPoint = Offset(
        (fromPoint.dx + toPoint.dx) / 2,
        (fromPoint.dy + toPoint.dy) / 2 - 30,
      );
      
      final path = Path()
        ..moveTo(fromPoint.dx, fromPoint.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, toPoint.dx, toPoint.dy);
      
      canvas.drawPath(path, paint);
      
      // Draw arrow
      if (isHighlighted) {
        final angle = math.atan2(toPoint.dy - controlPoint.dy, toPoint.dx - controlPoint.dx);
        final arrowSize = 10.0;
        
        final arrowPath = Path()
          ..moveTo(toPoint.dx, toPoint.dy)
          ..lineTo(
            toPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
            toPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
          )
          ..moveTo(toPoint.dx, toPoint.dy)
          ..lineTo(
            toPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
            toPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
          );
        
        canvas.drawPath(arrowPath, paint..strokeWidth = 2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
