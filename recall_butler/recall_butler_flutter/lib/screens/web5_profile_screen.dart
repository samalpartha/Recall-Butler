import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../providers/connectivity_provider.dart';

/// Provider for Web5 identity state
final web5IdentityProvider = StateNotifierProvider<Web5IdentityNotifier, Web5IdentityState>((ref) {
  return Web5IdentityNotifier();
});

class Web5IdentityState {
  final String? did;
  final String? name;
  final bool isConnected;
  final bool isLoading;
  final List<String> dwnEndpoints;
  final int memoriesInDwn;
  final int sharedCredentials;

  Web5IdentityState({
    this.did,
    this.name,
    this.isConnected = false,
    this.isLoading = false,
    this.dwnEndpoints = const [],
    this.memoriesInDwn = 0,
    this.sharedCredentials = 0,
  });

  Web5IdentityState copyWith({
    String? did,
    String? name,
    bool? isConnected,
    bool? isLoading,
    List<String>? dwnEndpoints,
    int? memoriesInDwn,
    int? sharedCredentials,
  }) {
    return Web5IdentityState(
      did: did ?? this.did,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      dwnEndpoints: dwnEndpoints ?? this.dwnEndpoints,
      memoriesInDwn: memoriesInDwn ?? this.memoriesInDwn,
      sharedCredentials: sharedCredentials ?? this.sharedCredentials,
    );
  }
}

class Web5IdentityNotifier extends StateNotifier<Web5IdentityState> {
  Web5IdentityNotifier() : super(Web5IdentityState());

  Future<void> createIdentity(String name) async {
    state = state.copyWith(isLoading: true);
    
    // Simulate API call to create Web5 identity
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate a mock DID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final did = 'did:key:z6Mk${_generateKeyId(timestamp)}';
    
    state = Web5IdentityState(
      did: did,
      name: name,
      isConnected: true,
      isLoading: false,
      dwnEndpoints: ['https://dwn.recall-butler.app'],
      memoriesInDwn: 0,
      sharedCredentials: 0,
    );
  }

  Future<void> connectIdentity(String did) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    
    state = Web5IdentityState(
      did: did,
      isConnected: true,
      isLoading: false,
      dwnEndpoints: ['https://dwn.recall-butler.app'],
    );
  }

  void disconnect() {
    state = Web5IdentityState();
  }

  String _generateKeyId(int seed) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    var current = seed;
    for (var i = 0; i < 24; i++) {
      buffer.write(chars[current % chars.length]);
      current = (current * 31 + i) % 1000000007;
    }
    return buffer.toString();
  }
}

/// Provider for real-time connection state
final realtimeConnectionProvider = StateProvider<RealtimeConnectionState>((ref) {
  return RealtimeConnectionState();
});

class RealtimeConnectionState {
  final bool sseConnected;
  final bool wsConnected;
  final int eventsReceived;
  final DateTime? lastEventAt;
  final List<String> subscribedEvents;

  RealtimeConnectionState({
    this.sseConnected = false,
    this.wsConnected = false,
    this.eventsReceived = 0,
    this.lastEventAt,
    this.subscribedEvents = const [],
  });
}

/// Web5 Profile & Real-time Settings Screen
class Web5ProfileScreen extends ConsumerStatefulWidget {
  const Web5ProfileScreen({super.key});

  @override
  ConsumerState<Web5ProfileScreen> createState() => _Web5ProfileScreenState();
}

class _Web5ProfileScreenState extends ConsumerState<Web5ProfileScreen> {
  final _nameController = TextEditingController();
  final _didController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _didController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final web5State = ref.watch(web5IdentityProvider);
    final realtimeState = ref.watch(realtimeConnectionProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Web5 Identity & Real-time'),
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (web5State.isConnected)
            IconButton(
              icon: const Icon(LucideIcons.share2),
              onPressed: _showShareDialog,
              tooltip: 'Share Memories',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web5 Identity Section
            _buildSectionHeader(
              icon: LucideIcons.fingerprint,
              title: 'Decentralized Identity',
              subtitle: 'Self-sovereign identity with Web5',
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 16),

            if (web5State.isConnected)
              _buildConnectedIdentity(web5State)
            else
              _buildCreateIdentity(web5State),

            const SizedBox(height: 32),

            // Real-time Connection Section
            _buildSectionHeader(
              icon: LucideIcons.radio,
              title: 'Real-time Connection',
              subtitle: 'SSE & WebSocket live updates',
            ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

            const SizedBox(height: 16),

            _buildRealtimeStatus(realtimeState, isOnline),

            const SizedBox(height: 32),

            // DWN Storage Section
            if (web5State.isConnected) ...[
              _buildSectionHeader(
                icon: LucideIcons.database,
                title: 'Decentralized Web Node',
                subtitle: 'Your data, your control',
              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),

              const SizedBox(height: 16),

              _buildDwnStats(web5State),
            ],

            const SizedBox(height: 32),

            // Innovation Features
            _buildSectionHeader(
              icon: LucideIcons.sparkles,
              title: 'Innovation Features',
              subtitle: 'Cutting-edge technology stack',
            ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1),

            const SizedBox(height: 16),

            _buildInnovationFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.accentGold, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textMutedDark,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedIdentity(Web5IdentityState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.1),
            AppTheme.accentCopper.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Identity Avatar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accentGold, AppTheme.accentCopper],
              ),
            ),
            child: Icon(
              LucideIcons.userCheck,
              color: Colors.black,
              size: 32,
            ),
          ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2000.ms, delay: 3000.ms),

          const SizedBox(height: 16),

          // Name
          if (state.name != null)
            Text(
              state.name!,
              style: TextStyle(
                color: AppTheme.textPrimaryDark,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 8),

          // DID
          GestureDetector(
            onTap: () => _copyToClipboard(state.did!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.key, size: 14, color: AppTheme.textMutedDark),
                  const SizedBox(width: 8),
                  Text(
                    _truncateDid(state.did!),
                    style: TextStyle(
                      color: AppTheme.textMutedDark,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.copy, size: 14, color: AppTheme.textMutedDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Status badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _StatusBadge(
                icon: LucideIcons.checkCircle,
                label: 'Verified',
                color: AppTheme.statusReady,
              ),
              _StatusBadge(
                icon: LucideIcons.shield,
                label: 'Self-Sovereign',
                color: AppTheme.accentGold,
              ),
              _StatusBadge(
                icon: LucideIcons.globe,
                label: 'Portable',
                color: AppTheme.statusProcessing,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Disconnect button
          TextButton.icon(
            onPressed: () {
              ref.read(web5IdentityProvider.notifier).disconnect();
            },
            icon: Icon(LucideIcons.logOut, size: 18),
            label: const Text('Disconnect Identity'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.statusFailed,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCreateIdentity(Web5IdentityState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D4A5C)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.userPlus,
            size: 48,
            color: AppTheme.textMutedDark,
          ),
          const SizedBox(height: 16),
          Text(
            'Create Your Decentralized Identity',
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Own your data with Web5. No vendor lock-in.',
            style: TextStyle(
              color: AppTheme.textMutedDark,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Name input
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Your name',
              prefixIcon: const Icon(LucideIcons.user),
              filled: true,
              fillColor: AppTheme.primaryDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () {
                      if (_nameController.text.isNotEmpty) {
                        ref
                            .read(web5IdentityProvider.notifier)
                            .createIdentity(_nameController.text);
                      }
                    },
              icon: state.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(LucideIcons.sparkles),
              label: Text(state.isLoading ? 'Creating...' : 'Create Identity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Or connect existing
          Row(
            children: [
              Expanded(child: Divider(color: const Color(0xFF3D4A5C))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: TextStyle(color: AppTheme.textMutedDark),
                ),
              ),
              Expanded(child: Divider(color: const Color(0xFF3D4A5C))),
            ],
          ),

          const SizedBox(height: 16),

          // Connect existing DID
          TextField(
            controller: _didController,
            decoration: InputDecoration(
              hintText: 'Paste existing DID',
              prefixIcon: const Icon(LucideIcons.key),
              filled: true,
              fillColor: AppTheme.primaryDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () {
              if (_didController.text.startsWith('did:')) {
                ref
                    .read(web5IdentityProvider.notifier)
                    .connectIdentity(_didController.text);
              }
            },
            icon: const Icon(LucideIcons.link, size: 18),
            label: const Text('Connect Existing Identity'),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildRealtimeStatus(RealtimeConnectionState state, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D4A5C)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ConnectionTile(
                  icon: LucideIcons.radio,
                  title: 'SSE',
                  subtitle: 'Server-Sent Events',
                  isConnected: isOnline,
                  onToggle: () {
                    // Toggle SSE connection
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ConnectionTile(
                  icon: LucideIcons.plug,
                  title: 'WebSocket',
                  subtitle: 'Bidirectional',
                  isConnected: isOnline,
                  onToggle: () {
                    // Toggle WebSocket connection
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Event subscriptions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscribed Events',
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _EventChip('documentCreated', true),
                    _EventChip('documentUpdated', true),
                    _EventChip('suggestionCreated', true),
                    _EventChip('aiResponse', true),
                    _EventChip('syncCompleted', true),
                    _EventChip('reminderTriggered', false),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: '0',
                label: 'Events Today',
                icon: LucideIcons.activity,
              ),
              _StatItem(
                value: '< 50ms',
                label: 'Latency',
                icon: LucideIcons.zap,
              ),
              _StatItem(
                value: isOnline ? 'Live' : 'Offline',
                label: 'Status',
                icon: isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
                color: isOnline ? AppTheme.statusReady : AppTheme.statusFailed,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildDwnStats(Web5IdentityState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D4A5C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: '${state.memoriesInDwn}',
                label: 'Memories in DWN',
                icon: LucideIcons.brain,
              ),
              _StatItem(
                value: '${state.sharedCredentials}',
                label: 'Shared VCs',
                icon: LucideIcons.share2,
              ),
              _StatItem(
                value: '${state.dwnEndpoints.length}',
                label: 'DWN Nodes',
                icon: LucideIcons.server,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // DWN endpoints
          ...state.dwnEndpoints.map((endpoint) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.server,
                      size: 16,
                      color: AppTheme.statusReady,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        endpoint,
                        style: TextStyle(
                          color: AppTheme.textPrimaryDark,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.checkCircle,
                      size: 16,
                      color: AppTheme.statusReady,
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.upload, size: 18),
                  label: const Text('Sync to DWN'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGold,
                    side: BorderSide(color: AppTheme.accentGold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMutedDark,
                    side: BorderSide(color: const Color(0xFF3D4A5C)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildInnovationFeatures() {
    final features = [
      _FeatureItem(
        icon: LucideIcons.link,
        title: 'MCP Protocol',
        description: '13 AI tools exposed via Model Context Protocol',
        color: AppTheme.accentGold,
      ),
      _FeatureItem(
        icon: LucideIcons.globe,
        title: 'Web5 Identity',
        description: 'Decentralized identity with verifiable credentials',
        color: Colors.blue,
      ),
      _FeatureItem(
        icon: LucideIcons.zap,
        title: 'Real-time APIs',
        description: 'SSE & WebSocket for instant updates',
        color: Colors.green,
      ),
      _FeatureItem(
        icon: LucideIcons.workflow,
        title: 'n8n Integration',
        description: 'Connect to 400+ apps with workflow automation',
        color: Colors.orange,
      ),
      _FeatureItem(
        icon: LucideIcons.brain,
        title: 'OpenRouter AI',
        description: 'Multi-model AI with Claude, GPT-4, Llama',
        color: Colors.purple,
      ),
      _FeatureItem(
        icon: LucideIcons.wifiOff,
        title: 'Offline Mode',
        description: 'Full functionality without internet',
        color: Colors.teal,
      ),
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3D4A5C)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: entry.value.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  entry.value.icon,
                  color: entry.value.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value.title,
                      style: TextStyle(
                        color: AppTheme.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      entry.value.description,
                      style: TextStyle(
                        color: AppTheme.textMutedDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.checkCircle,
                color: AppTheme.statusReady,
                size: 20,
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 300 + entry.key * 50)).slideX(begin: 0.1);
      }).toList(),
    );
  }

  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.share2, size: 48, color: AppTheme.accentGold),
            const SizedBox(height: 16),
            Text(
              'Share Memories',
              style: TextStyle(
                color: AppTheme.textPrimaryDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a Verifiable Credential to securely share memories with another Web5 identity.',
              style: TextStyle(color: AppTheme.textMutedDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Recipient DID (did:key:...)',
                prefixIcon: const Icon(LucideIcons.user),
                filled: true,
                fillColor: AppTheme.primaryDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Share credential created!'),
                      backgroundColor: AppTheme.statusReady,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.send),
                label: const Text('Create Share Credential'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('DID copied to clipboard'),
        backgroundColor: AppTheme.statusReady,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _truncateDid(String did) {
    if (did.length <= 24) return did;
    return '${did.substring(0, 16)}...${did.substring(did.length - 8)}';
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isConnected;
  final VoidCallback onToggle;

  const _ConnectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isConnected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected
            ? AppTheme.statusReady.withOpacity(0.1)
            : AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? AppTheme.statusReady.withOpacity(0.3)
              : const Color(0xFF3D4A5C),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isConnected ? AppTheme.statusReady : AppTheme.textMutedDark,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textMutedDark,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.statusReady : AppTheme.textMutedDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isConnected ? 'Connected' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  final String label;
  final bool isSubscribed;

  const _EventChip(this.label, this.isSubscribed);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSubscribed
            ? AppTheme.accentGold.withOpacity(0.1)
            : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed
              ? AppTheme.accentGold.withOpacity(0.3)
              : const Color(0xFF3D4A5C),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSubscribed ? AppTheme.accentGold : AppTheme.textMutedDark,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.textMutedDark, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppTheme.textPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMutedDark,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
