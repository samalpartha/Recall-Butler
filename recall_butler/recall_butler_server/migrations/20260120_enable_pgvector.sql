-- Enable pgvector extension for vector similarity search
-- Migration: 20260120_enable_pgvector.sql

-- Create extension if not exists
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify extension
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'vector'
  ) THEN
    RAISE EXCEPTION 'pgvector extension failed to install';
  END IF;
END $$;

-- Add embedding column to document_chunks if not exists
ALTER TABLE document_chunks 
ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Add embedding column to documents for full-document embeddings
ALTER TABLE documents
ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Comment on columns
COMMENT ON COLUMN document_chunks.embedding IS 
  'OpenAI text-embedding-3-small vector (1536 dimensions)';
  
COMMENT ON COLUMN documents.embedding IS 
  'Full document embedding for similarity search';

COMMIT;
