# 🚀 Recall Butler - Innovation Features

## 🔗 1. Model Context Protocol (MCP) Integration

**THE hottest trend for 2026** - Recall Butler is one of the first hackathon projects to implement MCP, making it **protocol-native** and **enterprise-grade**.

### What MCP Enables:
- ✅ **Standardized AI Integration**: Any MCP-compatible AI assistant can use Recall Butler
- ✅ **Discoverable Tools**: AI systems can discover and use your memory tools
- ✅ **Enterprise-Grade**: Production-ready governance and security
- ✅ **Multi-Agent Coordination**: Enable AI systems to work together

### Available MCP Tools (13 Total):

| Tool | Description |
|------|-------------|
| `recall_butler_search` | Semantic AI search through memories |
| `recall_butler_add_memory` | Add new memories (text, URL, file, voice) |
| `recall_butler_list_memories` | List stored memories with filtering |
| `recall_butler_get_suggestions` | Get AI-generated suggestions |
| `recall_butler_accept_suggestion` | Accept and schedule suggestions |
| `recall_butler_create_reminder` | Create reminders for documents |
| `recall_butler_get_stats` | Get vault statistics |
| `recall_butler_delete_memory` | Delete memories |
| `recall_butler_create_identity` | Create Web5 decentralized identity |
| `recall_butler_store_in_dwn` | Store in Decentralized Web Node |
| `recall_butler_share_memories` | Share via Verifiable Credentials |
| `recall_butler_subscribe_events` | Real-time event subscriptions |
| `recall_butler_trigger_sync` | Manual sync trigger |

---

## 🌐 2. Web5 Decentralized Identity

**FIRST hackathon project** with Web5 decentralized identity integration!

### Revolutionary Features:
- ✅ **Self-Sovereign Identity**: Users own their DID, not us
- ✅ **Decentralized Web Nodes (DWN)**: Store memories in user-controlled nodes
- ✅ **Verifiable Credentials**: Cryptographically secure memory sharing
- ✅ **No Vendor Lock-in**: User data is portable and owned by user
- ✅ **Privacy by Design**: Zero-knowledge proofs for selective disclosure

### Web5 Architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER'S DIGITAL IDENTITY                      │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │     DID     │     │     DWN     │     │     VC      │       │
│  │  (Identity) │────▶│  (Storage)  │────▶│  (Sharing)  │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│        │                    │                    │              │
│        ▼                    ▼                    ▼              │
│  did:key:z6Mk...    recall-butler://    MemoryShareCredential   │
│                      memories                                   │
└─────────────────────────────────────────────────────────────────┘
```

### API Examples:

```dart
// Create decentralized identity
final identity = await web5.createIdentity(name: 'John');
// Returns: did:key:z6MkhaXgBZDvotDkL5257faiztiGiC2QtKLGpbnnEGta2doK

// Store in user's DWN
await web5.storeMemory(
  title: 'Medical Records',
  content: '...',
  sourceType: 'file',
);

// Share with cryptographic proof
final credential = await web5.createMemoryShareCredential(
  recipientDid: 'did:key:z6Mkh...',
  memoryIds: ['med_001', 'med_002'],
  expiresAt: DateTime.now().add(Duration(days: 30)),
);
```

---

## ⚡ 3. FastAPI-Style Real-Time APIs

Modern async patterns matching FastAPI's performance and developer experience.

### Real-Time Features:
- ✅ **Server-Sent Events (SSE)**: One-way real-time updates
- ✅ **WebSocket**: Bidirectional real-time communication
- ✅ **Streaming AI**: Token-by-token response streaming
- ✅ **Event Bus**: Pub/sub for internal event propagation
- ✅ **Auto-Reconnect**: Resilient connection handling

### Event Types:

| Event | Description |
|-------|-------------|
| `documentCreated` | New memory added |
| `documentUpdated` | Memory modified |
| `documentDeleted` | Memory removed |
| `suggestionCreated` | New AI suggestion |
| `searchCompleted` | Search results ready |
| `aiResponse` | AI answer streaming |
| `syncStarted` | Sync in progress |
| `syncCompleted` | Sync finished |
| `reminderTriggered` | Reminder due |

### SSE Connection:

```javascript
// Client-side SSE subscription
const eventSource = new EventSource('/events/sse?userId=1');

eventSource.addEventListener('documentCreated', (event) => {
  const data = JSON.parse(event.data);
  console.log('New memory:', data.title);
});

eventSource.addEventListener('aiResponse', (event) => {
  // Stream AI response token by token
  document.getElementById('response').innerHTML += event.data.token;
});
```

### WebSocket Connection:

```javascript
// Client-side WebSocket
const ws = new WebSocket('ws://localhost:8180/ws');

ws.onopen = () => {
  ws.send(JSON.stringify({
    action: 'subscribe',
    payload: { types: ['documentCreated', 'suggestionCreated'] }
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  handleRealtimeEvent(data);
};
```

---

## 🔄 4. n8n Workflow Automation Integration

Connect Recall Butler to **400+ apps** without writing code.

### Available Webhooks:

| Webhook | Purpose |
|---------|---------|
| `/webhook/recall-butler/reminder` | Trigger multi-channel reminders |
| `/webhook/recall-butler/document` | Process documents with AI |
| `/webhook/recall-butler/notification` | Send push/email/SMS |
| `/webhook/recall-butler/sync` | Sync with external services |

### Pre-built Workflow Templates:

1. **Reminder → Email + SMS + Push**
2. **Document → AI Summary → Slack**
3. **Calendar → Import → Butler**
4. **Voice Note → Transcribe → Store**

---

## 🤖 5. OpenRouter AI Integration

Multi-model AI access through OpenRouter's unified API.

### Available Models:

| Model | Use Case |
|-------|----------|
| Claude 3.5 Sonnet | Default, balanced |
| Claude 3 Haiku | Fast search answers |
| Claude 3 Opus | Complex analysis |
| GPT-4 Turbo | Alternative reasoning |
| Llama 3.1 70B | Open-source option |
| Gemini Pro 1.5 | Long context |

### AI Features:
- ✅ Semantic search with RAG
- ✅ Auto-summarization
- ✅ Entity extraction
- ✅ Smart suggestions
- ✅ Streaming responses

---

## 🏗️ 6. Serverpod 3 Backend

Built on Serverpod 3 with:
- ✅ Type-safe Dart endpoints
- ✅ Auto-generated Flutter client
- ✅ Future calls for background jobs
- ✅ WebSocket support
- ✅ PostgreSQL + pgvector

---

## 🎨 7. Flutter Multi-Platform UI

Native-quality across all platforms:
- ✅ Web (responsive)
- ✅ iOS (native)
- ✅ Android (Material 3)
- ✅ Desktop (macOS, Windows, Linux)

### Special Features:
- 🎤 Voice input
- 📷 Camera/OCR
- 😊 Mood tracking
- ♿ Accessibility (17 options)
- 📴 Offline mode
- 🌍 15+ languages

---

## 📊 Innovation Summary

| Innovation | Status | Impact |
|------------|--------|--------|
| MCP Protocol | ✅ | First hackathon with MCP |
| Web5 Identity | ✅ | First decentralized memory app |
| Real-Time APIs | ✅ | SSE + WebSocket + Streaming |
| n8n Integration | ✅ | 400+ app connections |
| OpenRouter AI | ✅ | Multi-model AI access |
| Serverpod 3 | ✅ | Modern Dart backend |
| Multi-Platform | ✅ | Web + Mobile + Desktop |
| Offline Support | ✅ | Full offline capability |
| Accessibility | ✅ | 17 accessibility options |

---

## 🚀 Quick Start

```bash
# Set environment
source setup_env.sh

# Start backend
cd recall_butler_server
dart run bin/main.dart

# Start Flutter app  
cd ../recall_butler_flutter
flutter run -d chrome

# Start MCP server (for AI assistants)
dart run bin/mcp_server.dart --stdio
```

---

*Built for the 2026 Serverpod Hackathon with ❤️*
