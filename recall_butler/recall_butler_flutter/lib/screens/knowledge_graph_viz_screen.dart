import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

/// Interactive Knowledge Graph Visualization with Force-Directed Layout
class KnowledgeGraphVizScreen extends StatefulWidget {
  const KnowledgeGraphVizScreen({super.key});

  @override
  State<KnowledgeGraphVizScreen> createState() => _KnowledgeGraphVizScreenState();
}

class _KnowledgeGraphVizScreenState extends State<KnowledgeGraphVizScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Ticker _simulationTicker;
  
  String? _selectedNode;
  final _transformationController = TransformationController();
  
  // Simulation State
  final List<GraphNode> _nodes = [];
  final List<GraphEdge> _edges = [];
  bool _isSimulationRunning = true;
  
  // Physics Parameters
  final double _repulsionForce = 8000.0;
  final double _springLength = 150.0;
  final double _springK = 0.05; // Spring constant
  final double _damping = 0.90; // Velocity damping per frame
  final double _centerForce = 0.05; // Pull to center

  Size _canvasSize = const Size(2000, 2000);

  @override
  void initState() {
    super.initState();
    _initializeGraphData();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Start physics simulation loop
    _simulationTicker = createTicker(_runSimulationStep);
    _simulationTicker.start();
    
    // Auto-center view initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _centerView();
    });
  }

  void _initializeGraphData() {
    // Initial random positions near center
    final random = math.Random(42);
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    
    _nodes.addAll([
      GraphNode(id: 'project-alpha', label: 'Project Alpha', type: 'project', position: center + _randomOffset(random)),
      GraphNode(id: 'meeting-notes', label: 'Meeting Notes', type: 'document', position: center + _randomOffset(random)),
      GraphNode(id: 'budget', label: 'Budget Planning', type: 'document', position: center + _randomOffset(random)),
      GraphNode(id: 'team', label: 'Team Resources', type: 'concept', position: center + _randomOffset(random)),
      GraphNode(id: 'deadline', label: 'Q1 Deadline', type: 'date', position: center + _randomOffset(random)),
      GraphNode(id: 'john', label: 'John Smith', type: 'person', position: center + _randomOffset(random)),
      GraphNode(id: 'tech-specs', label: 'Tech Specs', type: 'document', position: center + _randomOffset(random)),
      GraphNode(id: 'client', label: 'Client XYZ', type: 'organization', position: center + _randomOffset(random)),
      // Additional nodes for richness
      GraphNode(id: 'mobile-app', label: 'Mobile App', type: 'project', position: center + _randomOffset(random)),
      GraphNode(id: 'ux-design', label: 'UX Design', type: 'concept', position: center + _randomOffset(random)),
    ]);

    _edges.addAll([
      GraphEdge(from: 'project-alpha', to: 'meeting-notes', label: 'discussed in'),
      GraphEdge(from: 'project-alpha', to: 'budget', label: 'requires'),
      GraphEdge(from: 'project-alpha', to: 'deadline', label: 'due by'),
      GraphEdge(from: 'meeting-notes', to: 'john', label: 'attended by'),
      GraphEdge(from: 'meeting-notes', to: 'team', label: 'involves'),
      GraphEdge(from: 'budget', to: 'tech-specs', label: 'includes'),
      GraphEdge(from: 'team', to: 'john', label: 'includes'),
      GraphEdge(from: 'project-alpha', to: 'client', label: 'for'),
      GraphEdge(from: 'tech-specs', to: 'deadline', label: 'due by'),
      GraphEdge(from: 'client', to: 'mobile-app', label: 'requested'),
      GraphEdge(from: 'mobile-app', to: 'ux-design', label: 'needs'),
      GraphEdge(from: 'john', to: 'ux-design', label: 'leads'),
    ]);
  }
  
  Offset _randomOffset(math.Random random) {
    return Offset(
      (random.nextDouble() - 0.5) * 100,
      (random.nextDouble() - 0.5) * 100,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulationTicker.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  
  void _runSimulationStep(Duration elapsed) {
    if (!_isSimulationRunning) return;
    
    // Physics Sub-steps
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    
    // 1. Apply Repulsion (Coulomb's Law-ish)
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final nodeA = _nodes[i];
        final nodeB = _nodes[j];
        
        final delta = nodeA.position - nodeB.position;
        final distance = delta.distance;
        if (distance == 0) continue; // Avoid division by zero
        
        final force = _repulsionForce / (distance * distance);
        final direction = delta / distance;
        
        final repulsion = direction * force;
        
        nodeA.velocity += repulsion;
        nodeB.velocity -= repulsion;
      }
    }
    
    // 2. Apply Attraction (Hooke's Law)
    for (final edge in _edges) {
      final nodeA = _nodes.firstWhere((n) => n.id == edge.from);
      final nodeB = _nodes.firstWhere((n) => n.id == edge.to);
      
      final delta = nodeB.position - nodeA.position;
      final distance = delta.distance;
      if (distance == 0) continue;
      
      final displacement = distance - _springLength;
      final force = displacement * _springK;
      final direction = delta / distance;
      
      final attraction = direction * force;
      
      nodeA.velocity += attraction;
      nodeB.velocity -= attraction;
    }
    
    // 3. Center Gravity & Update Position
    bool isStable = true;
    for (final node in _nodes) {
      if (node.isDragging) {
        node.velocity = Offset.zero;
        continue;
      }

      // Pull to center to prevent drifting away
      final toCenter = center - node.position;
      node.velocity += toCenter * _centerForce * 0.1;

      // Apply damping
      node.velocity *= _damping;
      
      // Update position
      node.position += node.velocity;
      
      // Check stability threshold (if everything is moving very slowly)
      if (node.velocity.distance > 0.1) {
        isStable = false;
      }
      
      // Keep within bounds (soft clamping)
      // _clampNode(node); 
    }
    
    // Stop simulation if stable to save battery, restart if interaction happens
    // setState(() {}); // Trigger repaint
    // Optimization: Just mark paint needed? No, standard setState for now.
    setState(() {});
  }
  
  void _centerView() {
    final matrix = Matrix4.identity();
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    
    // Scale down a bit to see more
    matrix.translate(-center.dx + MediaQuery.of(context).size.width / 2, -center.dy + MediaQuery.of(context).size.height / 2);
    // matrix.scale(0.8); 
    
    _transformationController.value = matrix;
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'project': return AppTheme.accentGold;
      case 'document': return AppTheme.accentTeal;
      case 'concept': return Colors.purpleAccent;
      case 'person': return Colors.pinkAccent;
      case 'organization': return Colors.blueAccent;
      case 'date': return Colors.orangeAccent;
      default: return Colors.grey;
    }
  }

  IconData _getNodeIcon(String type) {
    switch (type) {
      case 'project': return LucideIcons.folder;
      case 'document': return LucideIcons.fileText;
      case 'concept': return LucideIcons.lightbulb;
      case 'person': return LucideIcons.user;
      case 'organization': return LucideIcons.building2;
      case 'date': return LucideIcons.calendar;
      default: return LucideIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // Background visualization
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
          
          // Graph Visualization Layer
          GestureDetector(
            onScaleStart: (_) {
               // Optional: pause simulation during pan/zoom? 
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(2000), // Huge margin for panning
              minScale: 0.1,
              maxScale: 4.0,
              constrained: false, // Infinite canvas
              child: SizedBox(
                width: _canvasSize.width,
                height: _canvasSize.height,
                child: Stack(
                  children: [
                    // Edges & Nodes Painter (Custom Paint)
                    RepaintBoundary(
                      child: CustomPaint(
                        size: _canvasSize,
                        painter: GraphPainter(
                          nodes: _nodes,
                          edges: _edges,
                          selectedNode: _selectedNode,
                          pulseValue: _pulseController.value,
                          getNodeColor: _getNodeColor,
                        ),
                      ),
                    ),
                    
                    // Touch targets for nodes (Invisible interactive layer)
                    ..._nodes.map((node) => Positioned(
                      left: node.position.dx - 30, // Center the 60x60 target
                      top: node.position.dy - 30,
                      child: GestureDetector(
                        onPanStart: (_) {
                          node.isDragging = true;
                          _isSimulationRunning = true; // Wake up physics
                          _simulationTicker.start();
                        },
                        onPanUpdate: (details) {
                          node.position += details.delta; // TODO: Adjust for scale
                          setState(() {});
                        },
                        onPanEnd: (_) {
                          node.isDragging = false;
                        },
                        onTap: () {
                           setState(() {
                             _selectedNode = (_selectedNode == node.id) ? null : node.id;
                           });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.transparent, // Invisible hit target
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ),
          
          // Debug/Center Overlay (Optional)
          /*
          Center(
            child: Container(width: 4, height: 4, color: Colors.white.withOpacity(0.2)),
          ),
          */

          // Top bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
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
                            color: Colors.white,
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
                  IconButton(
                    icon: const Icon(LucideIcons.plus, color: AppTheme.accentTeal),
                    onPressed: _showAddConnectionDialog,
                    tooltip: 'Add Connection',
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                    onPressed: () {
                       // Jiggle nodes to restart simulation
                       for(var n in _nodes) {
                         n.velocity += Offset(math.Random().nextDouble() * 2, math.Random().nextDouble() * 2);
                       }
                       _isSimulationRunning = true;
                    },
                    tooltip: 'Jiggle Graph',
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.maximize2, color: Colors.white),
                    onPressed: _centerView,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...types.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getNodeColor(t['type']!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t['label']!,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
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
    
    final color = _getNodeColor(node.type);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceDark.withOpacity(0.95),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                ),
                child: Icon(
                  _getNodeIcon(node.type),
                  color: color,
                  size: 22,
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
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      node.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18, color: Colors.white54),
                onPressed: () => setState(() => _selectedNode = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
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
            final targetColor = _getNodeColor(targetNode.type);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    _getNodeIcon(targetNode.type),
                    size: 14,
                    color: targetColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      targetNode.label,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  Text(
                    edge.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMutedDark,
                      fontStyle: FontStyle.italic,
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
              onPressed: () => _showNodeDetailSheet(node),
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: const Text('Explore Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Search Graph', style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search nodes...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: const Icon(LucideIcons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            final node = _nodes.where((n) => n.label.toLowerCase().contains(value.toLowerCase())).firstOrNull;
            if (node != null) {
              setState(() => _selectedNode = node.id);
              // Pan to node?
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
  void _showAddConnectionDialog() {
    String? fromNodeId;
    String? toNodeId;
    String label = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Add Connection', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: fromNodeId,
                dropdownColor: AppTheme.cardDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'From Node',
                  labelStyle: TextStyle(color: AppTheme.textMutedDark),
                ),
                items: _nodes.map((n) => DropdownMenuItem(
                  value: n.id,
                  child: Text(n.label),
                )).toList(),
                onChanged: (v) => setState(() => fromNodeId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: toNodeId,
                dropdownColor: AppTheme.cardDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'To Node',
                  labelStyle: TextStyle(color: AppTheme.textMutedDark),
                ),
                items: _nodes.map((n) => DropdownMenuItem(
                  value: n.id,
                  child: Text(n.label),
                )).toList(),
                onChanged: (v) => setState(() => toNodeId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Relationship Label',
                  labelStyle: TextStyle(color: AppTheme.textMutedDark),
                  hintText: 'e.g. relates to, owns, part of',
                ),
                onChanged: (v) => label = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (fromNodeId != null && toNodeId != null && fromNodeId != toNodeId) 
                ? () {
                    this.setState(() {
                      _edges.add(GraphEdge(
                        from: fromNodeId!,
                        to: toNodeId!,
                        label: label.isEmpty ? 'connected' : label,
                      ));
                      _isSimulationRunning = true;
                    });
                    Navigator.pop(context);
                  }
                : null,
              child: const Text('Add Link'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNodeDetailSheet(GraphNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _getNodeColor(node.type).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: _getNodeColor(node.type).withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Icon(_getNodeIcon(node.type), color: _getNodeColor(node.type), size: 32),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               node.label,
                               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                             ),
                             Text(
                               node.type.toUpperCase(),
                               style: TextStyle(color: _getNodeColor(node.type), fontWeight: FontWeight.bold, letterSpacing: 1),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 24),
                   const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 8),
                   Text(
                     'Detailed information about "${node.label}" and its relationships within the Knowledge Graph. This reflects the semantic understanding of your Personal Cloud Vault.',
                     style: TextStyle(color: AppTheme.textSecondaryDark, height: 1.5),
                   ),
                   const SizedBox(height: 24),
                   const Text('Connections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 16),
                   ..._edges.where((e) => e.from == node.id || e.to == node.id).map((e) {
                      final otherId = e.from == node.id ? e.to : e.from;
                      final other = _nodes.firstWhere((n) => n.id == otherId);
                      return ListTile(
                        leading: Icon(_getNodeIcon(other.type), color: _getNodeColor(other.type)),
                        title: Text(other.label, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(e.label, style: TextStyle(color: AppTheme.textMutedDark)),
                        trailing: const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white54),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedNode = other.id);
                        },
                      );
                   }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Graph Data Models with Physics Properties
class GraphNode {
  final String id;
  final String label;
  final String type;
  
  // Physics properties
  Offset position;
  Offset velocity;
  bool isDragging;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.position,
    this.velocity = Offset.zero,
    this.isDragging = false,
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

// Optimized Custom Painter
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
    // 1. Draw Edges
    for (final edge in edges) {
      final fromNode = nodes.firstWhere((n) => n.id == edge.from);
      final toNode = nodes.firstWhere((n) => n.id == edge.to);
      
      final isHighlighted = selectedNode == edge.from || selectedNode == edge.to;
      
      // Edge color
      final edgeColor = isHighlighted 
          ? getNodeColor(fromNode.type).withOpacity(0.6)
          : Colors.white.withOpacity(0.08); // Subtle lines

      final paint = Paint()
        ..color = edgeColor
        ..strokeWidth = isHighlighted ? 2.5 : 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(fromNode.position, toNode.position, paint);
      
      // Optional: Draw edge label if highlighted
      // if (isHighlighted) ...
    }
    
    // 2. Draw Nodes
    for (final node in nodes) {
        final isSelected = selectedNode == node.id;
        final color = getNodeColor(node.type);
        
        // Glow effect for selected
        if (isSelected) {
          final glowPaint = Paint()
            ..color = color.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
          canvas.drawCircle(node.position, 35 + pulseValue * 5, glowPaint);
        }

        // Node circle
        final bgPaint = Paint()..color = AppTheme.surfaceDark;
        canvas.drawCircle(node.position, 20, bgPaint); // Background to hide lines behind

        final nodePaint = Paint()
          ..color = isSelected ? color : color.withOpacity(0.8)
          ..style = PaintingStyle.fill;
        
        // Draw main circle
        canvas.drawCircle(node.position, isSelected ? 22 : 18, nodePaint);
        
        // Border
        final borderPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2 : 1.5;
        canvas.drawCircle(node.position, isSelected ? 22 : 18, borderPaint);
        
        // Label
        if (isSelected || size.width < 3000) { // Always show labels or LOD
          final textSpan = TextSpan(
            text: node.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          textPainter.layout();
          textPainter.paint(
            canvas, 
            node.position + Offset(-textPainter.width / 2, 28)
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Always repaint for animation
}
