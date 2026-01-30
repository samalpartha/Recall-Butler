import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

class CommandPalette extends ConsumerStatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final Function(String) onCommandSelected;

  const CommandPalette({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.onCommandSelected,
  });

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<CommandItem> _filteredCommands = [];

  final List<CommandItem> _allCommands = [
    CommandItem(
      id: 'search',
      label: 'Search Memories',
      icon: LucideIcons.search,
      shortcut: 'S',
      type: CommandType.action,
    ),
    CommandItem(
      id: 'note',
      label: 'Create Note',
      icon: LucideIcons.stickyNote,
      shortcut: 'N',
      type: CommandType.action,
    ),
    CommandItem(
      id: 'voice',
      label: 'Voice Note',
      icon: LucideIcons.mic,
      shortcut: 'V',
      type: CommandType.action,
    ),
    CommandItem(
      id: 'scan',
      label: 'Scan Document',
      icon: LucideIcons.scan,
      shortcut: 'D',
      type: CommandType.action,
    ),
    CommandItem(
      id: 'chat',
      label: 'Chat with Butler',
      icon: LucideIcons.messageSquare,
      shortcut: 'C',
      type: CommandType.navigation,
    ),
    CommandItem(
      id: 'analytics',
      label: 'View Analytics',
      icon: LucideIcons.barChart2,
      shortcut: 'A',
      type: CommandType.navigation,
    ),
    CommandItem(
      id: 'settings',
      label: 'Settings',
      icon: LucideIcons.settings,
      shortcut: ',',
      type: CommandType.navigation,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredCommands = _allCommands;
    _controller.addListener(_filterCommands);
  }

  @override
  void didUpdateWidget(CommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      // Small delay to allow the modal to build before focusing
      Future.delayed(const Duration(milliseconds: 50), () {
        _focusNode.requestFocus();
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterCommands() {
    final query = _controller.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = _allCommands;
      } else {
        _filteredCommands = _allCommands.where((cmd) {
          return cmd.label.toLowerCase().contains(query);
        }).toList();
        
        // Add "Ask Butler" option if query is not empty
        _filteredCommands.add(CommandItem(
          id: 'action:$query',
          label: 'Ask Butler: "$query"',
          icon: LucideIcons.sparkles,
          type: CommandType.action,
        ));
      }
    });
  }

  void _handleSelection(CommandItem item) {
    widget.onCommandSelected(item.id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Backdrop tap to close
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Palette
          Center(
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 500),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Field
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a command or search...',
                      hintStyle: TextStyle(color: AppTheme.textMutedDark),
                      prefixIcon: const Icon(
                        LucideIcons.command, 
                        color: AppTheme.accentGold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      suffixIcon: _controller.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: _controller.clear,
                          )
                        : null,
                    ),
                  ),
                  
                  const Divider(height: 1, color: Colors.white10),

                  // Results
                  Flexible(
                    child: _filteredCommands.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No commands found',
                              style: TextStyle(color: AppTheme.textMutedDark),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredCommands.length,
                            itemBuilder: (context, index) {
                              final item = _filteredCommands[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGold.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 18,
                                    color: AppTheme.accentGold,
                                  ),
                                ),
                                title: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: item.shortcut != null
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.shortcut!,
                                          style: TextStyle(
                                            color: AppTheme.textMutedDark,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : null,
                                hoverColor: Colors.white.withOpacity(0.05),
                                onTap: () => _handleSelection(item),
                              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                            },
                          ),
                  ),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _FooterKey(icon: LucideIcons.arrowUp),
                        const SizedBox(width: 4),
                        _FooterKey(icon: LucideIcons.arrowDown),
                        const SizedBox(width: 8),
                        Text('to navigate', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
                        const SizedBox(width: 16),
                        _FooterKey(icon: LucideIcons.cornerDownLeft),
                        const SizedBox(width: 8),
                        Text('to select', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }
}

class _FooterKey extends StatelessWidget {
  final IconData icon;

  const _FooterKey({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: AppTheme.textMutedDark),
    );
  }
}

enum CommandType { action, navigation }

class CommandItem {
  final String id;
  final String label;
  final IconData icon;
  final String? shortcut;
  final CommandType type;

  CommandItem({
    required this.id,
    required this.label,
    required this.icon,
    this.shortcut,
    required this.type,
  });
}
