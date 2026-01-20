# Recall Butler - Architecture Overview

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         RECALL BUTLER                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │   Flutter   │  │   Chrome    │  │    MCP      │  │    n8n      │ │
│  │   Web App   │  │  Extension  │  │   Clients   │  │  Workflows  │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘ │
│         │                │                │                │         │
│         └────────────────┴────────────────┴────────────────┘         │
│                                   │                                   │
│                          ┌────────┴────────┐                         │
│                          │   API Gateway   │                         │
│                          │   (Serverpod)   │                         │
│                          └────────┬────────┘                         │
│                                   │                                   │
│    ┌──────────────────────────────┼──────────────────────────────┐   │
│    │                              │                              │   │
│    ▼                              ▼                              ▼   │
│ ┌──────────┐              ┌──────────────┐              ┌──────────┐ │
│ │ Document │              │    Search    │              │Suggestion│ │
│ │ Endpoint │              │   Endpoint   │              │ Endpoint │ │
│ └────┬─────┘              └──────┬───────┘              └────┬─────┘ │
│      │                           │                           │       │
│      └───────────────────────────┼───────────────────────────┘       │
│                                  │                                   │
│              ┌───────────────────┼───────────────────┐               │
│              │                   │                   │               │
│              ▼                   ▼                   ▼               │
│       ┌────────────┐     ┌────────────┐     ┌────────────┐          │
│       │    AI      │     │   Vector   │     │   Config   │          │
│       │  Service   │     │  Service   │     │  Service   │          │
│       │(OpenRouter)│     │ (pgvector) │     │            │          │
│       └────────────┘     └────────────┘     └────────────┘          │
│                                  │                                   │
│                          ┌───────┴───────┐                          │
│                          │  PostgreSQL   │                          │
│                          │  + pgvector   │                          │
│                          └───────────────┘                          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## 📦 Component Breakdown

### Backend (Serverpod)
```
recall_butler_server/
├── bin/
│   ├── main.dart              # Server entry point
│   └── mcp_server.dart        # MCP server CLI
├── lib/
│   ├── server.dart            # Server configuration
│   └── src/
│       ├── endpoints/         # API endpoints
│       │   ├── document_endpoint.dart
│       │   ├── search_endpoint.dart
│       │   ├── suggestion_endpoint.dart
│       │   ├── analytics_endpoint.dart
│       │   ├── health_endpoint.dart
│       │   ├── mcp_endpoint.dart
│       │   └── realtime_endpoint.dart
│       ├── services/          # Business logic
│       │   ├── ai_service.dart
│       │   ├── config_service.dart
│       │   ├── error_handler.dart
│       │   └── logger_service.dart
│       ├── integrations/      # External integrations
│       │   ├── n8n_integration.dart
│       │   ├── web5_integration.dart
│       │   └── realtime_api.dart
│       ├── mcp/              # MCP Protocol
│       │   └── mcp_server.dart
│       └── models/           # Data models
└── config/                   # Environment configs
```

### Frontend (Flutter)
```
recall_butler_flutter/
├── lib/
│   ├── main.dart
│   ├── screens/              # UI Screens
│   │   ├── shell_screen.dart
│   │   ├── ingest_screen.dart
│   │   ├── search_screen.dart
│   │   ├── activity_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── analytics_screen.dart      # NEW
│   │   ├── knowledge_graph_screen.dart # NEW
│   │   ├── calendar_screen.dart        # NEW
│   │   ├── smart_reminders_screen.dart # NEW
│   │   ├── workspaces_screen.dart      # NEW
│   │   └── web5_profile_screen.dart
│   ├── services/             # Services
│   │   ├── api_service.dart
│   │   ├── offline_service.dart
│   │   ├── calendar_service.dart       # NEW
│   │   ├── smart_reminder_service.dart # NEW
│   │   ├── collaboration_service.dart  # NEW
│   │   └── conversation_memory_service.dart # NEW
│   ├── providers/            # State management
│   ├── widgets/              # Reusable widgets
│   └── theme/                # Theming
└── web/                      # Web-specific
```

### Browser Extension
```
browser-extension/
├── manifest.json             # Extension manifest (v3)
├── popup.html/css/js         # Extension popup UI
├── background.js             # Service worker
├── content.js/css            # Content scripts
└── icons/                    # Extension icons
```

## 🔌 Integration Points

### 1. MCP (Model Context Protocol)
- Standardized AI assistant integration
- Tools: search, ingest, suggest, remind
- Resources: documents, suggestions, stats

### 2. OpenRouter AI
- Multi-model support (Claude, GPT-4, Llama, etc.)
- Used for: Answers, Summarization, Extraction, Embeddings

### 3. n8n Workflow Automation
- Webhook triggers for document events
- 400+ app integrations
- Custom workflow builder

### 4. Web5 Decentralized Identity
- Self-sovereign identity (DID)
- Decentralized Web Nodes (DWN)
- Verifiable Credentials

## 🔐 Security Architecture

```
┌─────────────────────────────────────────┐
│            Security Layers              │
├─────────────────────────────────────────┤
│  1. Rate Limiting (per IP/user)         │
│  2. Input Validation & Sanitization     │
│  3. JWT Authentication                  │
│  4. Role-Based Access Control           │
│  5. CORS Policy                         │
│  6. SQL Injection Prevention (ORM)      │
│  7. XSS Prevention (Flutter)            │
│  8. HTTPS Enforcement (Production)      │
└─────────────────────────────────────────┘
```

## 📊 Data Flow

### Document Ingestion
```
User Input → Validation → Storage → Text Extraction → 
AI Processing → Embedding Generation → Vector Index → 
Suggestion Generation → Notification
```

### Search Query
```
Query → Rate Limit Check → Authentication → 
Vector Search → Result Ranking → AI Answer Generation → 
Response with Sources
```

## 🚀 Deployment Architecture

### Development
```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    ports: ["5432:5432"]
  
  server:
    command: dart run bin/main.dart
    ports: ["8180:8180"]
  
  flutter:
    command: flutter run -d chrome --web-port=3000
    ports: ["3000:3000"]
```

### Production (Recommended)
```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    deploy:
      replicas: 1
      resources:
        limits:
          memory: 2G
  
  server:
    image: recall-butler-server:latest
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 1G
    environment:
      - RECALL_BUTLER_ENV=production
      - JWT_SECRET=${JWT_SECRET}
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
  
  nginx:
    image: nginx:alpine
    ports: ["443:443"]
```

## 📈 Scalability Considerations

| Component | Strategy |
|-----------|----------|
| API Server | Horizontal scaling with load balancer |
| Database | Read replicas, connection pooling |
| Search | pgvector with HNSW index |
| File Storage | S3-compatible object storage |
| Cache | Redis for session/rate limiting |

## 🧪 Testing Strategy

| Type | Coverage | Tools |
|------|----------|-------|
| Unit | Services, Models | dart test |
| Integration | API Endpoints | Serverpod test |
| Widget | UI Components | Flutter test |
| E2E | User Journeys | Playwright |
| Performance | Load Testing | k6, Artillery |
