import 'dart:convert';
import 'dart:io';

import 'package:recall_butler_server/src/mcp/mcp_server.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// 🧠 RECALL BUTLER - MCP Server Entry Point
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// Run this to start the MCP server for integration with AI assistants.
/// 
/// Usage:
///   dart run bin/mcp_server.dart
///   
/// Or via stdio for MCP clients:
///   dart run bin/mcp_server.dart --stdio
/// ═══════════════════════════════════════════════════════════════════════════════

void main(List<String> args) async {
  final server = RecallButlerMCPServer();
  
  if (args.contains('--stdio')) {
    // Run in stdio mode for MCP clients
    await runStdioMode(server);
  } else if (args.contains('--manifest')) {
    // Print the manifest
    print(JsonEncoder.withIndent('  ').convert(server.getManifest()));
  } else {
    // Print info
    print('''
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║        🧠 RECALL BUTLER - MCP SERVER                                        ║
║           Model Context Protocol Implementation                              ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  This server implements MCP (Model Context Protocol) to expose               ║
║  Recall Butler's capabilities to AI assistants.                              ║
║                                                                              ║
║  Usage:                                                                      ║
║    dart run bin/mcp_server.dart --stdio    # Run in stdio mode               ║
║    dart run bin/mcp_server.dart --manifest # Print server manifest           ║
║                                                                              ║
║  Available Tools:                                                            ║
║    • recall_butler_search        - Semantic search through memories          ║
║    • recall_butler_add_memory    - Add new memories                          ║
║    • recall_butler_list_memories - List stored memories                      ║
║    • recall_butler_get_suggestions - Get AI suggestions                      ║
║    • recall_butler_accept_suggestion - Accept a suggestion                   ║
║    • recall_butler_create_reminder - Create reminders                        ║
║    • recall_butler_get_stats     - Get vault statistics                      ║
║    • recall_butler_delete_memory - Delete memories                           ║
║                                                                              ║
║  Resources:                                                                  ║
║    • recall-butler://memories    - All stored memories                       ║
║    • recall-butler://suggestions - AI suggestions                            ║
║    • recall-butler://stats       - Vault statistics                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
''');
    
    print('\nServer manifest:');
    print(JsonEncoder.withIndent('  ').convert(server.getManifest()));
  }
}

/// Run MCP server in stdio mode
Future<void> runStdioMode(RecallButlerMCPServer server) async {
  stderr.writeln('Recall Butler MCP Server started in stdio mode');
  
  // Read JSON-RPC requests from stdin, write responses to stdout
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    try {
      final request = json.decode(line) as Map<String, dynamic>;
      final response = await server.handleRequest(request);
      stdout.writeln(json.encode(response));
    } catch (e) {
      final errorResponse = {
        'jsonrpc': '2.0',
        'id': null,
        'error': {
          'code': -32700,
          'message': 'Parse error: $e',
        },
      };
      stdout.writeln(json.encode(errorResponse));
    }
  }
}
