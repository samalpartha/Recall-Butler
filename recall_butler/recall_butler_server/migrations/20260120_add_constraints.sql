-- Add database constraints and foreign keys
-- Migration: 20260120_add_constraints.sql

-- Add foreign keys
ALTER TABLE documents
ADD CONSTRAINT fk_documents_user
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE document_chunks
ADD CONSTRAINT fk_document_chunks_document
FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE;

ALTER TABLE document_chunks
ADD CONSTRAINT fk_document_chunks_user
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE suggestions
ADD CONSTRAINT fk_suggestions_document
FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE;

ALTER TABLE suggestions
ADD CONSTRAINT fk_suggestions_user
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE refresh_tokens
ADD CONSTRAINT fk_refresh_tokens_user
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE workspaces
ADD CONSTRAINT fk_workspaces_owner
FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE workspace_members
ADD CONSTRAINT fk_workspace_members_workspace
FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE;

ALTER TABLE workspace_members
ADD CONSTRAINT fk_workspace_members_user
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE entities
ADD CONSTRAINT fk_entities_document
FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE;

ALTER TABLE entity_relations
ADD CONSTRAINT fk_entity_relations_source
FOREIGN KEY (source_entity_id) REFERENCES entities(id) ON DELETE CASCADE;

ALTER TABLE entity_relations
ADD CONSTRAINT fk_entity_relations_target
FOREIGN KEY (target_entity_id) REFERENCES entities(id) ON DELETE CASCADE;

-- Add NOT NULL constraints
ALTER TABLE documents
ALTER COLUMN title SET NOT NULL,
ALTER COLUMN content SET NOT NULL,
ALTER COLUMN source_type SET NOT NULL,
ALTER COLUMN user_id SET NOT NULL,
ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE users
ALTER COLUMN email SET NOT NULL,
ALTER COLUMN password_hash SET NOT NULL,
ALTER COLUMN role SET NOT NULL,
ALTER COLUMN created_at SET NOT NULL;

-- Add unique constraints
ALTER TABLE users
ADD CONSTRAINT unique_user_email UNIQUE (email);

ALTER TABLE workspace_members
ADD CONSTRAINT unique_workspace_user UNIQUE (workspace_id, user_id);

-- Add check constraints
ALTER TABLE users
ADD CONSTRAINT check_email_format 
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

ALTER TABLE users
ADD CONSTRAINT check_role_valid
CHECK (role IN ('user', 'premium', 'admin', 'superAdmin'));

ALTER TABLE workspace_members
ADD CONSTRAINT check_workspace_role_valid
CHECK (role IN ('owner', 'admin', 'editor', 'member', 'viewer'));

ALTER TABLE suggestions
ADD CONSTRAINT check_status_valid
CHECK (status IN ('pending', 'approved', 'dismissed', 'completed'));

-- Add default values
ALTER TABLE documents
ALTER COLUMN created_at SET DEFAULT NOW();

ALTER TABLE users
ALTER COLUMN created_at SET DEFAULT NOW(),
ALTER COLUMN role SET DEFAULT 'user';

ALTER TABLE suggestions
ALTER COLUMN status SET DEFAULT 'pending',
ALTER COLUMN created_at SET DEFAULT NOW();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_documents_source_type ON documents(source_type);
CREATE INDEX IF NOT EXISTS idx_suggestions_status ON suggestions(status);
CREATE INDEX IF NOT EXISTS idx_suggestions_user_status ON suggestions(user_id, status);

COMMIT;
