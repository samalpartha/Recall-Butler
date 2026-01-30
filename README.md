# 🧠 Recall Butler

> **Your AI-powered memory assistant** — Dump anything now, retrieve and act later.

Recall Butler transforms unorganized inputs (text, screenshots, links, voice notes) into searchable memory with proactive Butler actions. Built with **Flutter** and **Serverpod 3** for the Serverpod Hackathon.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Serverpod](https://img.shields.io/badge/Serverpod_3-6B4EFF?style=flat&logo=dart&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=flat&logo=openai&logoColor=white)

---

## 🚀 Live Demo

- **Frontend App**: [https://recall-butler-web.web.app](https://recall-butler-web.web.app)
- **Backend API**: [https://recall-butler-server-fozkypxpga-uc.a.run.app](https://recall-butler-server-fozkypxpga-uc.a.run.app)
- **Health Check**: [https://recall-butler-server-fozkypxpga-uc.a.run.app/health](https://recall-butler-server-fozkypxpga-uc.a.run.app/health)

## ✨ Features

### 📥 Smart Ingest

- **Upload files** (PDFs, images, documents)
- **Paste text** directly from clipboard
- **Save URLs** for automatic content extraction
- Immediate "Queued" state with real-time processing updates

### 🔍 Semantic Recall

- Natural language search across all your memories
- **AI-powered answers** with grounded sources
- Top 3 source snippets with relevance scores
- One-click document navigation

### 🤵 Butler Actions

- **Smart suggestions** based on document content:
  - Invoice → Payment reminder
  - Itinerary → Check-in reminder
  - Meeting notes → Follow-up actions
- **Approve or dismiss** with one tap
- **Scheduled reminders** via Serverpod future calls

- Live processing status via WebSocket
- Progress indicators: QUEUED → EXTRACTING → EMBEDDING → READY
- Instant notifications when processing completes

### 🔌 Offline-First

- **Works without internet**: Create notes and capture thoughts anytime
- **Local Caching**: Instant access to your recent memories
- **Auto-Sync**: Changes sync automatically when connection returns
- **Idempotent Sync**: Smart hashing prevents duplicate entries

### 🛡️ Reliability

- **Content Hashing**: Prevents duplicates if you click twice
- **Queue System**: Persistent local queue for offline actions
- **Graceful Fallbacks**: API Service automatically switches to offline mode

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.x, Riverpod, flutter_animate |
| **Backend** | Serverpod 3, Dart |
| **Database** | PostgreSQL 16 + pgvector |
| **AI** | OpenAI text-embedding-3-small, GPT-4o-mini |
| **Storage** | Local / S3-compatible (MinIO) |

---

## 🚀 Quick Start

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.2+)
- [Dart SDK](https://dart.dev/get-dart) (3.2+)
- [Docker](https://www.docker.com/get-started) & Docker Compose
- [Serverpod CLI](https://serverpod.dev/docs/get-started)
- OpenAI API key

### 1. Clone & Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/recall-butler.git
cd recall-butler

# Copy environment file
cp .env.example .env

# Add your OpenAI API key to .env
echo "OPENAI_API_KEY=sk-your-key-here" >> .env
```

### 2. Start Database

```bash
# Start PostgreSQL with pgvector
docker-compose up -d postgres

# Wait for database to be ready
sleep 5
```

### 3. Run Server

```bash
# Navigate to server directory
cd recall_butler_server

# Install dependencies
dart pub get

# Generate Serverpod code
serverpod generate

# Run migrations
serverpod create-migration
serverpod apply-migrations

# Start the server
dart run bin/main.dart
```

### 4. Run Flutter App

```bash
# Open new terminal, navigate to Flutter app
cd recall_butler_flutter

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Or run on mobile
flutter run
```

---

## 📁 Project Structure

```
recall-butler/
├── recall_butler_server/       # Serverpod backend
│   ├── lib/
│   │   └── src/
│   │       ├── endpoints/      # API endpoints
│   │       ├── models/         # Data models
│   │       ├── services/       # AI, Vector, Text services
│   │       └── future_calls/   # Background jobs
│   ├── migrations/             # Database migrations
│   └── config/                 # Server configuration
│
├── recall_butler_flutter/      # Flutter frontend
│   ├── lib/
│   │   ├── screens/            # Main screens
│   │   ├── widgets/            # Reusable components
│   │   ├── providers/          # Riverpod state
│   │   ├── models/             # Client models
│   │   ├── services/           # API service
│   │   └── theme/              # App theming
│   └── web/                    # Web configuration
│
├── docker-compose.yml          # Local development
├── .env.example                # Environment template
└── README.md                   # This file
```

---

## 🎯 Serverpod Features Used

| Feature | Usage |
|---------|-------|
| **Future Calls** | Background document processing, scheduled reminders |
| **pgvector Integration** | Semantic search with vector embeddings |
| **WebSocket Streaming** | Real-time job status updates |
| **Auth Module** | User authentication and session management |
| **Relic Routes** | External webhook ingest endpoint |

---

## 🧪 Demo Flow

1. **Upload an invoice** → Watch processing animation
2. **See Butler suggestion** → "Remind me before due date"
3. **Approve the suggestion** → Reminder scheduled
4. **Search "invoices due"** → Get grounded answer with source
5. **View Activity tab** → See scheduled actions and history

### Sample Demo Data

The app includes mock data for demonstration:

- Q4 Invoice from Acme Corp ($5,400 due Jan 30)
- NYC Flight Itinerary (Jan 20-24)
- Team Standup Notes

---

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API key for embeddings | ✅ |
| `POSTGRES_PASSWORD` | Database password | ✅ |
| `SERVER_PORT` | API server port (default: 8080) | ❌ |
| `S3_ENDPOINT` | S3-compatible storage endpoint | ❌ |

### Embedding Model

Using OpenAI `text-embedding-3-small`:

- **Dimension**: 1536
- **Chunk size**: 500 tokens
- **Overlap**: 100 tokens

---

## 📸 Screenshots

| Ingest Screen | Search Screen | Activity Screen |
|--------------|---------------|-----------------|
| Upload, paste, or URL | Semantic recall | Butler suggestions |

---

## 🏗️ Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────┐
│  Flutter App    │────▶│  Serverpod API   │────▶│  PostgreSQL │
│                 │◀────│                  │◀────│  + pgvector │
│  • Ingest       │     │  • Endpoints     │     │             │
│  • Search       │     │  • Future Calls  │     └─────────────┘
│  • Activity     │     │  • WebSocket     │
└─────────────────┘     │                  │     ┌─────────────┐
                        │                  │────▶│   OpenAI    │
                        └──────────────────┘     │  Embeddings │
                                                 └─────────────┘
```

---

## 🚢 Deployment

### Backend (Google Cloud Run)

The backend is containerized and deployed to Cloud Run.

```bash
# Deploy to Cloud Run (handles build, push, migration, and deploy)
./deploy_gcp.sh
```

**Key Configuration:**

- **Database**: Cloud SQL (PostgreSQL 16)
- **Connectivity**: Public IP (TCP 5432)
- **Secrets**: Managed via Google Secret Manager

### Frontend (Firebase Hosting)

The frontend is a Flutter Web app hosted on Firebase.

```bash
# Deploy to Firebase Hosting
# Usage: ./deploy_frontend.sh <BACKEND_URL>
./deploy_frontend.sh https://recall-butler-server-fozkypxpga-uc.a.run.app
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

MIT License - feel free to use this project as inspiration for your own AI-powered apps!

---

## 🙏 Acknowledgments

- [Serverpod](https://serverpod.dev) - The amazing Flutter backend framework
- [OpenAI](https://openai.com) - Embeddings and AI capabilities
- [pgvector](https://github.com/pgvector/pgvector) - Vector similarity search

---

**Built with ❤️ for the Serverpod Hackathon 2026**
