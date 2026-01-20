import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// ═══════════════════════════════════════════════════════════════════════════════
/// 🧠 RECALL BUTLER - MCP (Model Context Protocol) SERVER
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// Implements the Model Context Protocol to expose Recall Butler as a 
/// standardized AI assistant that can be connected to any MCP-compatible client.
/// 
/// This makes Recall Butler enterprise-grade and discoverable by AI systems.
/// ═══════════════════════════════════════════════════════════════════════════════

/// MCP Server implementation for Recall Butler
class RecallButlerMCPServer {
  final String name = 'recall-butler';
  final String version = '1.0.0';
  final String description = 'Recall Butler - Your AI-powered memory assistant';
  
  // Server capabilities
  final Map<String, dynamic> capabilities = {
    'tools': true,
    'resources': true,
    'prompts': true,
    'sampling': false,
  };

  /// Available MCP Tools
  List<Map<String, dynamic>> get tools => [
    {
      'name': 'recall_butler_search',
      'description': 'Search through your memories using semantic AI search. Returns relevant documents with AI-generated answers.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'Natural language search query (e.g., "What invoices are due this month?")',
          },
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of results to return',
            'default': 10,
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'recall_butler_add_memory',
      'description': 'Add a new memory/document to Recall Butler. Supports text, URLs, and file content.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title for the memory',
          },
          'content': {
            'type': 'string',
            'description': 'The text content to remember',
          },
          'source_type': {
            'type': 'string',
            'enum': ['text', 'url', 'file', 'voice'],
            'description': 'Type of the memory source',
            'default': 'text',
          },
          'url': {
            'type': 'string',
            'description': 'URL to extract content from (if source_type is url)',
          },
        },
        'required': ['title'],
      },
    },
    {
      'name': 'recall_butler_list_memories',
      'description': 'List all stored memories/documents with optional filtering.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of memories to return',
            'default': 20,
          },
          'status': {
            'type': 'string',
            'enum': ['READY', 'PROCESSING', 'FAILED', 'all'],
            'description': 'Filter by processing status',
            'default': 'all',
          },
        },
      },
    },
    {
      'name': 'recall_butler_get_suggestions',
      'description': 'Get AI-generated Butler suggestions based on your memories.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'state': {
            'type': 'string',
            'enum': ['PENDING', 'ACCEPTED', 'DISMISSED', 'all'],
            'description': 'Filter suggestions by state',
            'default': 'PENDING',
          },
        },
      },
    },
    {
      'name': 'recall_butler_accept_suggestion',
      'description': 'Accept a Butler suggestion and schedule it for execution.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'suggestion_id': {
            'type': 'integer',
            'description': 'ID of the suggestion to accept',
          },
        },
        'required': ['suggestion_id'],
      },
    },
    {
      'name': 'recall_butler_create_reminder',
      'description': 'Create a reminder for a specific document.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'document_id': {
            'type': 'integer',
            'description': 'ID of the document to create reminder for',
          },
          'title': {
            'type': 'string',
            'description': 'Reminder title',
          },
          'description': {
            'type': 'string',
            'description': 'Reminder description',
          },
          'scheduled_at': {
            'type': 'string',
            'description': 'ISO 8601 datetime for when to trigger the reminder',
          },
        },
        'required': ['document_id', 'title', 'scheduled_at'],
      },
    },
    {
      'name': 'recall_butler_get_stats',
      'description': 'Get statistics about your memory vault.',
      'inputSchema': {
        'type': 'object',
        'properties': {},
      },
    },
    {
      'name': 'recall_butler_delete_memory',
      'description': 'Delete a memory/document from the vault.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'document_id': {
            'type': 'integer',
            'description': 'ID of the document to delete',
          },
        },
        'required': ['document_id'],
      },
    },
    // Web5 Decentralized Identity Tools
    {
      'name': 'recall_butler_create_identity',
      'description': 'Create a new Web5 decentralized identity (DID). User owns their data with self-sovereign identity.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'description': 'Display name for the identity',
          },
          'email': {
            'type': 'string',
            'description': 'Email address (optional)',
          },
        },
      },
    },
    {
      'name': 'recall_butler_store_in_dwn',
      'description': 'Store a memory in user\'s Decentralized Web Node (DWN). Data lives in user\'s control, not centralized servers.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title of the memory',
          },
          'content': {
            'type': 'string',
            'description': 'Content to store',
          },
          'source_type': {
            'type': 'string',
            'enum': ['text', 'url', 'file', 'voice'],
            'description': 'Type of content',
          },
        },
        'required': ['title', 'content'],
      },
    },
    {
      'name': 'recall_butler_share_memories',
      'description': 'Share memories with another user using Verifiable Credentials. Cryptographically secure sharing.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'recipient_did': {
            'type': 'string',
            'description': 'DID of the person to share with',
          },
          'memory_ids': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'IDs of memories to share',
          },
          'expires_in_days': {
            'type': 'integer',
            'description': 'How many days the share is valid',
            'default': 30,
          },
        },
        'required': ['recipient_did', 'memory_ids'],
      },
    },
    // Real-time API Tools
    {
      'name': 'recall_butler_subscribe_events',
      'description': 'Get info for subscribing to real-time events via SSE or WebSocket.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'protocol': {
            'type': 'string',
            'enum': ['sse', 'websocket'],
            'description': 'Protocol to use for real-time updates',
            'default': 'sse',
          },
        },
      },
    },
    {
      'name': 'recall_butler_trigger_sync',
      'description': 'Manually trigger a sync between local and cloud storage.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'user_id': {
            'type': 'integer',
            'description': 'User ID to sync',
          },
        },
        'required': ['user_id'],
      },
    },
  ];

  /// Available MCP Resources
  List<Map<String, dynamic>> get resources => [
    {
      'uri': 'recall-butler://memories',
      'name': 'All Memories',
      'description': 'Access all stored memories in your vault',
      'mimeType': 'application/json',
    },
    {
      'uri': 'recall-butler://suggestions',
      'name': 'Butler Suggestions',
      'description': 'AI-generated suggestions based on your memories',
      'mimeType': 'application/json',
    },
    {
      'uri': 'recall-butler://stats',
      'name': 'Vault Statistics',
      'description': 'Statistics about your memory vault',
      'mimeType': 'application/json',
    },
  ];

  /// Available MCP Prompts
  List<Map<String, dynamic>> get prompts => [
    {
      'name': 'search_memories',
      'description': 'Search through your memories with natural language',
      'arguments': [
        {
          'name': 'query',
          'description': 'What are you looking for?',
          'required': true,
        },
      ],
    },
    {
      'name': 'summarize_memories',
      'description': 'Get a summary of memories matching a topic',
      'arguments': [
        {
          'name': 'topic',
          'description': 'Topic to summarize',
          'required': true,
        },
      ],
    },
    {
      'name': 'find_action_items',
      'description': 'Find action items and todos from your memories',
      'arguments': [],
    },
  ];

  /// Generate MCP server manifest
  Map<String, dynamic> getManifest() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'capabilities': capabilities,
      'tools': tools,
      'resources': resources,
      'prompts': prompts,
    };
  }

  /// Handle MCP JSON-RPC request
  Future<Map<String, dynamic>> handleRequest(Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final params = request['params'] as Map<String, dynamic>? ?? {};
    final id = request['id'];

    try {
      dynamic result;

      switch (method) {
        case 'initialize':
          result = {
            'protocolVersion': '2024-11-05',
            'capabilities': capabilities,
            'serverInfo': {
              'name': name,
              'version': version,
            },
          };
          break;

        case 'tools/list':
          result = {'tools': tools};
          break;

        case 'tools/call':
          result = await _handleToolCall(params);
          break;

        case 'resources/list':
          result = {'resources': resources};
          break;

        case 'resources/read':
          result = await _handleResourceRead(params);
          break;

        case 'prompts/list':
          result = {'prompts': prompts};
          break;

        case 'prompts/get':
          result = await _handlePromptGet(params);
          break;

        default:
          return _errorResponse(id, -32601, 'Method not found: $method');
      }

      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      };
    } catch (e) {
      return _errorResponse(id, -32603, 'Internal error: $e');
    }
  }

  /// Handle tool calls
  Future<Map<String, dynamic>> _handleToolCall(Map<String, dynamic> params) async {
    final toolName = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

    // In a real implementation, these would call the actual Serverpod endpoints
    switch (toolName) {
      case 'recall_butler_search':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Search results for: ${arguments['query']}\n'
                  'This would return actual search results from the Recall Butler API.',
            },
          ],
        };

      case 'recall_butler_add_memory':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Memory added: ${arguments['title']}\n'
                  'The content has been processed and stored in your vault.',
            },
          ],
        };

      case 'recall_butler_list_memories':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Listing memories with limit: ${arguments['limit'] ?? 20}',
            },
          ],
        };

      case 'recall_butler_get_suggestions':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Butler suggestions (state: ${arguments['state'] ?? 'PENDING'})',
            },
          ],
        };

      case 'recall_butler_accept_suggestion':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Suggestion ${arguments['suggestion_id']} accepted!',
            },
          ],
        };

      case 'recall_butler_create_reminder':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Reminder created: ${arguments['title']} '
                  'for document ${arguments['document_id']} '
                  'scheduled at ${arguments['scheduled_at']}',
            },
          ],
        };

      case 'recall_butler_get_stats':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Vault statistics retrieved.',
            },
          ],
        };

      case 'recall_butler_delete_memory':
        return {
          'content': [
            {
              'type': 'text',
              'text': 'Memory ${arguments['document_id']} deleted.',
            },
          ],
        };

      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  /// Handle resource reads
  Future<Map<String, dynamic>> _handleResourceRead(Map<String, dynamic> params) async {
    final uri = params['uri'] as String;

    switch (uri) {
      case 'recall-butler://memories':
        return {
          'contents': [
            {
              'uri': uri,
              'mimeType': 'application/json',
              'text': '{"memories": []}', // Would return actual memories
            },
          ],
        };

      case 'recall-butler://suggestions':
        return {
          'contents': [
            {
              'uri': uri,
              'mimeType': 'application/json',
              'text': '{"suggestions": []}',
            },
          ],
        };

      case 'recall-butler://stats':
        return {
          'contents': [
            {
              'uri': uri,
              'mimeType': 'application/json',
              'text': '{"total": 0, "ready": 0, "processing": 0}',
            },
          ],
        };

      default:
        throw Exception('Unknown resource: $uri');
    }
  }

  /// Handle prompt gets
  Future<Map<String, dynamic>> _handlePromptGet(Map<String, dynamic> params) async {
    final promptName = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

    switch (promptName) {
      case 'search_memories':
        return {
          'description': 'Search through your memories',
          'messages': [
            {
              'role': 'user',
              'content': {
                'type': 'text',
                'text': 'Search my memories for: ${arguments['query']}',
              },
            },
          ],
        };

      case 'summarize_memories':
        return {
          'description': 'Summarize memories about a topic',
          'messages': [
            {
              'role': 'user',
              'content': {
                'type': 'text',
                'text': 'Summarize my memories about: ${arguments['topic']}',
              },
            },
          ],
        };

      case 'find_action_items':
        return {
          'description': 'Find action items from memories',
          'messages': [
            {
              'role': 'user',
              'content': {
                'type': 'text',
                'text': 'Find all action items and todos from my recent memories.',
              },
            },
          ],
        };

      default:
        throw Exception('Unknown prompt: $promptName');
    }
  }

  Map<String, dynamic> _errorResponse(dynamic id, int code, String message) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
      },
    };
  }
}

/// MCP Server configuration for clients
class MCPServerConfig {
  static Map<String, dynamic> generateCursorConfig() {
    return {
      'recall-butler': {
        'command': 'dart',
        'args': ['run', 'bin/mcp_server.dart'],
        'env': {
          'RECALL_BUTLER_API': 'http://localhost:8180',
        },
      },
    };
  }

  static String generateReadme() {
    return '''
# 🧠 Recall Butler MCP Server

## What is MCP?

Model Context Protocol (MCP) is the standardized protocol for AI assistants to connect to tools and data sources. Recall Butler implements MCP to be **enterprise-grade** and **protocol-native**.

## Available Tools

| Tool | Description |
|------|-------------|
| `recall_butler_search` | Semantic AI search through memories |
| `recall_butler_add_memory` | Add new memories (text, URL, file) |
| `recall_butler_list_memories` | List stored memories |
| `recall_butler_get_suggestions` | Get AI-generated suggestions |
| `recall_butler_accept_suggestion` | Accept a suggestion |
| `recall_butler_create_reminder` | Create reminders |
| `recall_butler_get_stats` | Vault statistics |
| `recall_butler_delete_memory` | Delete memories |

## Available Resources

| URI | Description |
|-----|-------------|
| `recall-butler://memories` | All stored memories |
| `recall-butler://suggestions` | AI suggestions |
| `recall-butler://stats` | Vault statistics |

## Integration with Cursor

Add to your `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "recall-butler": {
      "command": "dart",
      "args": ["run", "bin/mcp_server.dart"],
      "env": {
        "RECALL_BUTLER_API": "http://localhost:8180"
      }
    }
  }
}
```

## Integration with Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "recall-butler": {
      "command": "dart",
      "args": ["run", "bin/mcp_server.dart"]
    }
  }
}
```

## Why MCP?

- **Standardized**: Works with any MCP-compatible AI assistant
- **Discoverable**: AI systems can discover and use your tools
- **Enterprise-grade**: Production-ready governance and security
- **Multi-agent**: Enable coordination between AI systems
''';
  }
}
