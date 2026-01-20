import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../mcp/mcp_server.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// 🧠 RECALL BUTLER - MCP HTTP ENDPOINT
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// Exposes MCP functionality via HTTP for web-based integrations
/// ═══════════════════════════════════════════════════════════════════════════════

class McpEndpoint extends Endpoint {
  final _mcpServer = RecallButlerMCPServer();

  /// Get MCP server manifest
  /// Returns the full MCP manifest with tools, resources, and prompts
  Future<Map<String, dynamic>> getManifest(Session session) async {
    return _mcpServer.getManifest();
  }

  /// List available MCP tools
  Future<List<Map<String, dynamic>>> listTools(Session session) async {
    return _mcpServer.tools;
  }

  /// List available MCP resources
  Future<List<Map<String, dynamic>>> listResources(Session session) async {
    return _mcpServer.resources;
  }

  /// List available MCP prompts
  Future<List<Map<String, dynamic>>> listPrompts(Session session) async {
    return _mcpServer.prompts;
  }

  /// Execute an MCP tool
  Future<Map<String, dynamic>> executeTool(
    Session session,
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final request = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': 'tools/call',
      'params': {
        'name': toolName,
        'arguments': arguments,
      },
    };
    
    return await _mcpServer.handleRequest(request);
  }

  /// Read an MCP resource
  Future<Map<String, dynamic>> readResource(
    Session session,
    String uri,
  ) async {
    final request = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': 'resources/read',
      'params': {
        'uri': uri,
      },
    };
    
    return await _mcpServer.handleRequest(request);
  }

  /// Get an MCP prompt
  Future<Map<String, dynamic>> getPrompt(
    Session session,
    String promptName,
    Map<String, dynamic> arguments,
  ) async {
    final request = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': 'prompts/get',
      'params': {
        'name': promptName,
        'arguments': arguments,
      },
    };
    
    return await _mcpServer.handleRequest(request);
  }

  /// Handle raw MCP JSON-RPC request
  Future<Map<String, dynamic>> handleJsonRpc(
    Session session,
    Map<String, dynamic> request,
  ) async {
    return await _mcpServer.handleRequest(request);
  }
}
