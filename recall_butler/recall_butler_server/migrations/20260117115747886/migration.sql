BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "document_chunks" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "chunkIndex" bigint NOT NULL,
    "text" text NOT NULL,
    "embeddingJson" text
);

-- Indexes
CREATE INDEX "chunk_document_idx" ON "document_chunks" USING btree ("documentId");
CREATE INDEX "chunk_document_index_idx" ON "document_chunks" USING btree ("documentId", "chunkIndex");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "documents" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "sourceType" text NOT NULL,
    "title" text NOT NULL,
    "sourceUrl" text,
    "mimeType" text,
    "extractedText" text,
    "summary" text,
    "keyFieldsJson" text,
    "status" text NOT NULL,
    "errorMessage" text
);

-- Indexes
CREATE INDEX "document_user_idx" ON "documents" USING btree ("userId");
CREATE INDEX "document_status_idx" ON "documents" USING btree ("status");
CREATE INDEX "document_user_status_idx" ON "documents" USING btree ("userId", "status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "suggestions" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "type" text NOT NULL,
    "title" text NOT NULL,
    "description" text NOT NULL,
    "payloadJson" text NOT NULL,
    "state" text NOT NULL,
    "scheduledAt" timestamp without time zone,
    "executedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "suggestion_document_idx" ON "suggestions" USING btree ("documentId");
CREATE INDEX "suggestion_user_idx" ON "suggestions" USING btree ("userId");
CREATE INDEX "suggestion_state_idx" ON "suggestions" USING btree ("state");
CREATE INDEX "suggestion_user_state_idx" ON "suggestions" USING btree ("userId", "state");


--
-- MIGRATION VERSION FOR recall_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('recall_butler', '20260117115747886', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260117115747886', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260109031533194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260109031533194', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
