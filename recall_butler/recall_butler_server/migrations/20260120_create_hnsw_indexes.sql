-- Create HNSW indexes for fast vector similarity search
-- Migration: 20260120_create_hnsw_indexes.sql
-- HNSW (Hierarchical Navigable Small World) provides approximate nearest neighbor search

-- Create HNSW index on document_chunks for chunk-level search
CREATE INDEX IF NOT EXISTS idx_document_chunks_embedding_hnsw 
ON document_chunks 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Create HNSW index on documents for document-level search
CREATE INDEX IF NOT EXISTS idx_documents_embedding_hnsw 
ON documents 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Create index on user_id for efficient per-user queries
CREATE INDEX IF NOT EXISTS idx_document_chunks_user_id 
ON document_chunks(user_id);

CREATE INDEX IF NOT EXISTS idx_documents_user_id 
ON documents(user_id);

-- Create composite index for user + created_at (for recent documents)
CREATE INDEX IF NOT EXISTS idx_documents_user_created 
ON documents(user_id, created_at DESC);

-- Comments explaining HNSW parameters
COMMENT ON INDEX idx_document_chunks_embedding_hnsw IS 
  'HNSW index for vector similarity search.
   m=16: max connections per layer (higher = better accuracy, more memory)
   ef_construction=64: size of dynamic candidate list (higher = better index quality)';

COMMENT ON INDEX idx_documents_embedding_hnsw IS 
  'HNSW index for full-document vector similarity search';

-- Analyze tables for query optimization
ANALYZE document_chunks;
ANALYZE documents;

COMMIT;
