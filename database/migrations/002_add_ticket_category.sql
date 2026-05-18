-- Migration 002: Add ticket_category column to tickets table
-- Run on Render DB: psql $RENDER_DATABASE_URL -f database/migrations/002_add_ticket_category.sql

ALTER TABLE tickets
    ADD COLUMN IF NOT EXISTS ticket_category VARCHAR(50) DEFAULT 'question';

-- Update existing tickets to have the default category
UPDATE tickets SET ticket_category = 'question' WHERE ticket_category IS NULL;
