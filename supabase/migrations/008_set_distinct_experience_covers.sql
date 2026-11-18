-- ============================================================================
-- MELSAVA — Set Distinct High-Quality Photo Covers for Experiences
-- Migration: 008_set_distinct_experience_covers.sql
-- ============================================================================

UPDATE public.experiences
SET cover_image_url = 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=80'
WHERE title = 'Mindful Meditation & Sound Bath';

UPDATE public.experiences
SET cover_image_url = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80'
WHERE title = 'Artisan Coffee Tasting & Social';

UPDATE public.experiences
SET cover_image_url = 'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=1200&q=80'
WHERE title = 'Weekend Trek to Mukutmanipur';

UPDATE public.experiences
SET cover_image_url = 'https://images.unsplash.com/photo-1500835556837-99ac94a94552?auto=format&fit=crop&w=1200&q=80'
WHERE title = 'Sunset Photography Walk';
