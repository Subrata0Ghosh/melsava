-- ============================================================================
-- Migration 018: Phase 6 Production Hardening & Query Performance Optimization
-- Covers missing foreign-key indexes, composite indexes for high-frequency chat
-- retrieval, and filtered unread message tracking index.
-- ============================================================================

-- 1. Foreign Key Index Coverage for Data Integrity & Fast Cascades
CREATE INDEX IF NOT EXISTS idx_profile_intentions_intention_id
  ON public.profile_intentions(intention_id);

CREATE INDEX IF NOT EXISTS idx_moderation_actions_performed_by
  ON public.moderation_actions(performed_by);

CREATE INDEX IF NOT EXISTS idx_post_experience_submissions_user_id
  ON public.post_experience_submissions(user_id);

CREATE INDEX IF NOT EXISTS idx_app_notifications_connection_id
  ON public.app_notifications(connection_id);

CREATE INDEX IF NOT EXISTS idx_app_notifications_experience_id
  ON public.app_notifications(experience_id);

-- 2. Composite Index for Conversation Message Paging (Avoids separate Sort stage)
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
  ON public.messages(conversation_id, created_at DESC);

-- 3. Filtered Partial Index for Unread Message Count Lookups
CREATE INDEX IF NOT EXISTS idx_messages_unread
  ON public.messages(conversation_id, sender_id)
  WHERE is_read = false;

COMMENT ON INDEX idx_messages_conversation_created IS 'Optimizes reverse-chronological conversation message stream loading';
COMMENT ON INDEX idx_messages_unread IS 'Optimizes inbox unread counter aggregations without full table scans';
