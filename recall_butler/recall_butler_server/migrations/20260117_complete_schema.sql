-- ============================================================
-- RECALL BUTLER - COMPLETE DATABASE SCHEMA
-- Version: 1.0.0
-- Date: 2026-01-17
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";  -- pgvector for semantic search
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Trigram for fuzzy text search

-- ============================================================
-- USERS & AUTHENTICATION
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    role VARCHAR(20) DEFAULT 'user',
    
    -- Encryption keys (for E2E encryption)
    encryption_salt VARCHAR(64),
    encrypted_data_key TEXT,
    key_version INTEGER DEFAULT 1,
    
    -- OAuth info
    oauth_provider VARCHAR(50),
    oauth_id VARCHAR(255),
    
    -- Account status
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_role CHECK (role IN ('user', 'premium', 'admin', 'super_admin'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_oauth ON users(oauth_provider, oauth_id);

-- ============================================================
-- REFRESH TOKENS (for JWT auth)
-- ============================================================

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    session_id VARCHAR(32),
    device_info JSONB,
    ip_address INET,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);

-- ============================================================
-- DOCUMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Content (can be encrypted)
    title TEXT NOT NULL,
    content TEXT,
    summary TEXT,
    
    -- Metadata
    source_type VARCHAR(50) NOT NULL,  -- file, url, text, voice, camera
    source_url TEXT,
    original_filename VARCHAR(255),
    mime_type VARCHAR(100),
    file_size_bytes BIGINT,
    
    -- Processing status
    status VARCHAR(20) DEFAULT 'pending',
    processing_error TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    
    -- Categorization
    category VARCHAR(100),
    tags TEXT[],
    sentiment FLOAT,  -- -1.0 to 1.0
    
    -- Encryption flag
    is_encrypted BOOLEAN DEFAULT FALSE,
    
    -- Soft delete
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
);

CREATE INDEX idx_documents_user ON documents(user_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_created ON documents(created_at DESC);
CREATE INDEX idx_documents_tags ON documents USING GIN(tags);
CREATE INDEX idx_documents_title_trgm ON documents USING GIN(title gin_trgm_ops);

-- ============================================================
-- DOCUMENT CHUNKS (for RAG)
-- ============================================================

CREATE TABLE IF NOT EXISTS document_chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    
    -- Vector embedding for semantic search
    embedding vector(1536),  -- OpenAI ada-002 dimension
    
    -- Chunk metadata
    start_char INTEGER,
    end_char INTEGER,
    token_count INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(document_id, chunk_index)
);

CREATE INDEX idx_chunks_document ON document_chunks(document_id);
-- HNSW index for fast similarity search (requires pgvector)
CREATE INDEX idx_chunks_embedding ON document_chunks 
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- ============================================================
-- SUGGESTIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS suggestions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_id INTEGER REFERENCES documents(id) ON DELETE SET NULL,
    
    type VARCHAR(50) NOT NULL,  -- reminder, action, insight, connection
    title TEXT NOT NULL,
    description TEXT,
    
    -- Scheduling for reminders
    scheduled_at TIMESTAMP WITH TIME ZONE,
    reminder_sent BOOLEAN DEFAULT FALSE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending',
    responded_at TIMESTAMP WITH TIME ZONE,
    
    -- AI reasoning
    confidence FLOAT,
    reasoning TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_suggestion_status CHECK (status IN ('pending', 'accepted', 'dismissed', 'expired'))
);

CREATE INDEX idx_suggestions_user ON suggestions(user_id);
CREATE INDEX idx_suggestions_status ON suggestions(status);
CREATE INDEX idx_suggestions_scheduled ON suggestions(scheduled_at);

-- ============================================================
-- WORKSPACES (for collaboration)
-- ============================================================

CREATE TABLE IF NOT EXISTS workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT FALSE,
    invite_code VARCHAR(20) UNIQUE,
    
    -- Settings
    settings JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workspaces_owner ON workspaces(owner_id);
CREATE INDEX idx_workspaces_invite ON workspaces(invite_code);

-- ============================================================
-- WORKSPACE MEMBERS
-- ============================================================

CREATE TABLE IF NOT EXISTS workspace_members (
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (workspace_id, user_id),
    CONSTRAINT valid_member_role CHECK (role IN ('owner', 'admin', 'editor', 'member', 'viewer'))
);

-- ============================================================
-- WORKSPACE DOCUMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS workspace_documents (
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    added_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (workspace_id, document_id)
);

-- ============================================================
-- KNOWLEDGE GRAPH
-- ============================================================

CREATE TABLE IF NOT EXISTS entities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,  -- person, organization, concept, etc.
    canonical_name VARCHAR(255),  -- normalized name for matching
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(canonical_name, type)
);

CREATE INDEX idx_entities_name ON entities(canonical_name);
CREATE INDEX idx_entities_type ON entities(type);

CREATE TABLE IF NOT EXISTS entity_relations (
    id SERIAL PRIMARY KEY,
    source_entity_id INTEGER NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    target_entity_id INTEGER NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    relationship VARCHAR(100) NOT NULL,
    strength FLOAT DEFAULT 1.0,
    
    -- Source document that established this relation
    document_id INTEGER REFERENCES documents(id) ON DELETE SET NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(source_entity_id, target_entity_id, relationship)
);

CREATE INDEX idx_entity_relations_source ON entity_relations(source_entity_id);
CREATE INDEX idx_entity_relations_target ON entity_relations(target_entity_id);

CREATE TABLE IF NOT EXISTS document_entities (
    document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    entity_id INTEGER NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    importance FLOAT DEFAULT 0.5,
    
    PRIMARY KEY (document_id, entity_id)
);

-- ============================================================
-- CALENDAR INTEGRATION
-- ============================================================

CREATE TABLE IF NOT EXISTS calendar_events (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- External calendar info
    external_id VARCHAR(255),
    calendar_provider VARCHAR(50),  -- google, apple, outlook
    
    -- Event details
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    is_all_day BOOLEAN DEFAULT FALSE,
    
    -- Linked documents
    linked_document_ids INTEGER[],
    
    -- Sync status
    last_synced_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_calendar_user ON calendar_events(user_id);
CREATE INDEX idx_calendar_time ON calendar_events(start_time);

-- ============================================================
-- SMART REMINDERS
-- ============================================================

CREATE TABLE IF NOT EXISTS smart_reminders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    suggestion_id INTEGER REFERENCES suggestions(id) ON DELETE SET NULL,
    
    title TEXT NOT NULL,
    description TEXT,
    
    -- Trigger conditions
    trigger_type VARCHAR(50) NOT NULL,  -- time, location, context
    trigger_time TIMESTAMP WITH TIME ZONE,
    trigger_location JSONB,  -- {lat, lng, radius}
    trigger_context JSONB,   -- {keywords, entities}
    
    -- Recurrence
    recurrence_rule TEXT,  -- RRULE format
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reminders_user ON smart_reminders(user_id);
CREATE INDEX idx_reminders_trigger ON smart_reminders(trigger_time);

-- ============================================================
-- CONVERSATION MEMORY
-- ============================================================

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT,
    
    -- Conversation summary for context
    summary TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS conversation_messages (
    id SERIAL PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,  -- user, assistant, system
    content TEXT NOT NULL,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    token_count INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_role CHECK (role IN ('user', 'assistant', 'system'))
);

CREATE INDEX idx_conversation_messages ON conversation_messages(conversation_id, created_at);

-- ============================================================
-- AUDIT LOG
-- ============================================================

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id TEXT,
    
    -- Change details
    old_values JSONB,
    new_values JSONB,
    
    -- Request context
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_resource ON audit_log(resource_type, resource_id);
CREATE INDEX idx_audit_created ON audit_log(created_at DESC);

-- ============================================================
-- ANALYTICS
-- ============================================================

CREATE TABLE IF NOT EXISTS user_analytics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    
    -- Daily metrics
    documents_created INTEGER DEFAULT 0,
    documents_viewed INTEGER DEFAULT 0,
    searches_performed INTEGER DEFAULT 0,
    suggestions_accepted INTEGER DEFAULT 0,
    suggestions_dismissed INTEGER DEFAULT 0,
    ai_interactions INTEGER DEFAULT 0,
    
    -- Storage metrics
    storage_used_bytes BIGINT DEFAULT 0,
    
    UNIQUE(user_id, date)
);

CREATE INDEX idx_analytics_user_date ON user_analytics(user_id, date DESC);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_workspaces_updated_at
    BEFORE UPDATE ON workspaces
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Semantic search function
CREATE OR REPLACE FUNCTION semantic_search(
    query_embedding vector(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INTEGER DEFAULT 10,
    filter_user_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    document_id INTEGER,
    chunk_id INTEGER,
    chunk_index INTEGER,
    content TEXT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dc.document_id,
        dc.id as chunk_id,
        dc.chunk_index,
        dc.content,
        1 - (dc.embedding <=> query_embedding) as similarity
    FROM document_chunks dc
    JOIN documents d ON dc.document_id = d.id
    WHERE 
        (filter_user_id IS NULL OR d.user_id = filter_user_id)
        AND d.deleted_at IS NULL
        AND 1 - (dc.embedding <=> query_embedding) >= match_threshold
    ORDER BY dc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- Hybrid search function (combines keyword + semantic)
CREATE OR REPLACE FUNCTION hybrid_search(
    search_query TEXT,
    query_embedding vector(1536),
    semantic_weight FLOAT DEFAULT 0.7,
    match_count INTEGER DEFAULT 10,
    filter_user_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    document_id INTEGER,
    title TEXT,
    content TEXT,
    combined_score FLOAT
) AS $$
BEGIN
    RETURN QUERY
    WITH semantic_results AS (
        SELECT 
            d.id as doc_id,
            d.title,
            d.content,
            MAX(1 - (dc.embedding <=> query_embedding)) as semantic_score
        FROM documents d
        JOIN document_chunks dc ON d.id = dc.document_id
        WHERE 
            (filter_user_id IS NULL OR d.user_id = filter_user_id)
            AND d.deleted_at IS NULL
        GROUP BY d.id
        HAVING MAX(1 - (dc.embedding <=> query_embedding)) > 0.5
    ),
    keyword_results AS (
        SELECT 
            d.id as doc_id,
            d.title,
            d.content,
            similarity(d.title || ' ' || COALESCE(d.content, ''), search_query) as keyword_score
        FROM documents d
        WHERE 
            (filter_user_id IS NULL OR d.user_id = filter_user_id)
            AND d.deleted_at IS NULL
            AND (
                d.title ILIKE '%' || search_query || '%' 
                OR d.content ILIKE '%' || search_query || '%'
            )
    )
    SELECT 
        COALESCE(s.doc_id, k.doc_id) as document_id,
        COALESCE(s.title, k.title) as title,
        COALESCE(s.content, k.content) as content,
        (
            COALESCE(s.semantic_score, 0) * semantic_weight +
            COALESCE(k.keyword_score, 0) * (1 - semantic_weight)
        ) as combined_score
    FROM semantic_results s
    FULL OUTER JOIN keyword_results k ON s.doc_id = k.doc_id
    ORDER BY combined_score DESC
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- SEED DATA
-- ============================================================

-- Create demo user
INSERT INTO users (email, name, role, email_verified)
VALUES ('demo@recallbutler.ai', 'Demo User', 'user', true)
ON CONFLICT (email) DO NOTHING;

-- ============================================================
-- GRANTS (adjust for your production user)
-- ============================================================

-- GRANT ALL ON ALL TABLES IN SCHEMA public TO recall_butler_app;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO recall_butler_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO recall_butler_app;
