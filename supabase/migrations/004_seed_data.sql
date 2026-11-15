-- ============================================================================
-- MELSAVA Dating App — Seed Data
-- Migration: 004_seed_data.sql
-- Description: Reference data for activity categories, intentions, interests,
--              and sample experiences.
-- ============================================================================

-- ============================================================================
-- 12 Activity Categories
-- ============================================================================
INSERT INTO public.activity_categories (name, description, icon, color, display_order) VALUES
    ('Coffee & Conversation',      'Casual coffee meetups and meaningful conversations',                'coffee',       '#8B4513', 1),
    ('Board Games',                'Board game nights, card games, and puzzles',                        'games',        '#4A90D9', 2),
    ('Nature Walks',               'Hiking, park walks, and outdoor exploration',                       'hiking',       '#2E8B57', 3),
    ('Sports & Fitness',           'Sports activities, gym sessions, and fitness classes',              'fitness',      '#FF6347', 4),
    ('Photography',                'Photo walks, workshops, and creative shoots',                       'camera',       '#9B59B6', 5),
    ('Music',                      'Live music, jam sessions, and music appreciation',                  'music',        '#E74C3C', 6),
    ('Art & Creative Workshops',   'Painting, pottery, crafts, and creative expression',                'palette',      '#F39C12', 7),
    ('Food Experiences',           'Cooking classes, food tours, and tasting events',                   'restaurant',   '#E67E22', 8),
    ('Reading & Book Clubs',       'Book discussions, reading meetups, and literary events',             'book',         '#3498DB', 9),
    ('Volunteering',               'Community service, charity events, and giving back',                'heart',        '#E91E63', 10),
    ('Learning & Skill-sharing',   'Workshops, skill exchanges, and educational meetups',               'lightbulb',    '#00BCD4', 11),
    ('Cultural Activities',        'Museum visits, cultural festivals, and heritage exploration',        'museum',       '#795548', 12);

-- ============================================================================
-- 7 Intentions
-- ============================================================================
INSERT INTO public.intentions (name, description, category) VALUES
    ('Genuine friendship',     'Looking for authentic, lasting friendships',                          'friendship'),
    ('Activity partner',       'Seeking someone to share hobbies and activities with',               'friendship'),
    ('Casual dating',          'Open to casual, low-pressure dating experiences',                    'dating'),
    ('Meaningful dating',      'Looking for deeper, more intentional dating connections',            'dating'),
    ('Serious relationship',   'Seeking a committed, long-term relationship',                       'dating'),
    ('Marriage-minded',        'Looking for a life partner with marriage in mind',                   'dating'),
    ('Open to discovering',    'No fixed expectations — open to whatever develops naturally',        'friendship');

-- ============================================================================
-- 18 Interests
-- ============================================================================
INSERT INTO public.interests (name, icon, category) VALUES
    ('Travel',           'airplane',     'lifestyle'),
    ('Cooking',          'chef_hat',     'food'),
    ('Reading',          'book',         'culture'),
    ('Fitness',          'dumbbell',     'sports'),
    ('Music',            'music_note',   'arts'),
    ('Photography',      'camera',       'arts'),
    ('Hiking',           'mountain',     'outdoors'),
    ('Movies',           'film',         'entertainment'),
    ('Gaming',           'gamepad',      'entertainment'),
    ('Yoga',             'lotus',        'wellness'),
    ('Dancing',          'dance',        'arts'),
    ('Art',              'palette',      'arts'),
    ('Technology',       'laptop',       'tech'),
    ('Volunteering',     'hands',        'social'),
    ('Meditation',       'zen',          'wellness'),
    ('Languages',        'globe',        'culture'),
    ('Gardening',        'plant',        'outdoors'),
    ('Coffee',           'coffee_cup',   'food');

-- ============================================================================
-- 10 Sample Experiences
-- (host_id is NULL here — in production, these would reference real users.
--  For seed data we use a CTE to pick the first available profile, or skip
--  if no profiles exist yet.)
-- ============================================================================

-- We create a helper function for seeding to avoid FK violations when no
-- profiles exist. In production, experiences are created by real users.
DO $$
DECLARE
    v_cat_coffee   UUID;
    v_cat_board    UUID;
    v_cat_nature   UUID;
    v_cat_sports   UUID;
    v_cat_photo    UUID;
    v_cat_music    UUID;
    v_cat_art      UUID;
    v_cat_food     UUID;
    v_cat_book     UUID;
    v_cat_volunteer UUID;
BEGIN
    -- Look up category IDs
    SELECT id INTO v_cat_coffee     FROM public.activity_categories WHERE name = 'Coffee & Conversation';
    SELECT id INTO v_cat_board      FROM public.activity_categories WHERE name = 'Board Games';
    SELECT id INTO v_cat_nature     FROM public.activity_categories WHERE name = 'Nature Walks';
    SELECT id INTO v_cat_sports     FROM public.activity_categories WHERE name = 'Sports & Fitness';
    SELECT id INTO v_cat_photo      FROM public.activity_categories WHERE name = 'Photography';
    SELECT id INTO v_cat_music      FROM public.activity_categories WHERE name = 'Music';
    SELECT id INTO v_cat_art        FROM public.activity_categories WHERE name = 'Art & Creative Workshops';
    SELECT id INTO v_cat_food       FROM public.activity_categories WHERE name = 'Food Experiences';
    SELECT id INTO v_cat_book       FROM public.activity_categories WHERE name = 'Reading & Book Clubs';
    SELECT id INTO v_cat_volunteer  FROM public.activity_categories WHERE name = 'Volunteering';

    -- Insert sample experiences (draft status, no host — will need real
    -- users in production). Using a placeholder UUID that can be updated.
    -- NOTE: These will only work after at least one user has signed up.
    -- In a fresh database, these inserts are skipped gracefully.

    -- We check if any profile exists to use as host
    IF EXISTS (SELECT 1 FROM public.profiles LIMIT 1) THEN
        DECLARE
            v_host UUID;
        BEGIN
            SELECT id INTO v_host FROM public.profiles LIMIT 1;

            INSERT INTO public.experiences (title, description, category_id, host_id, city, venue_name, is_online, max_participants, status, starts_at, duration_minutes) VALUES
            (
                'Morning Coffee & Deep Conversations',
                'Start your weekend with great coffee and even better conversations. We will explore thought-provoking questions designed to help you connect authentically with others.',
                v_cat_coffee, v_host, 'San Francisco', 'Blue Bottle Coffee', FALSE, 8, 'draft',
                now() + interval '7 days', 90
            ),
            (
                'Strategy Board Game Night',
                'An evening of strategy games — from Settlers of Catan to Ticket to Ride. All experience levels welcome! Snacks provided.',
                v_cat_board, v_host, 'San Francisco', 'Game Parlour', FALSE, 12, 'draft',
                now() + interval '10 days', 180
            ),
            (
                'Golden Gate Park Sunset Walk',
                'Join us for a leisurely walk through Golden Gate Park as the sun sets. Great opportunity to unwind and meet new people in a relaxed setting.',
                v_cat_nature, v_host, 'San Francisco', 'Golden Gate Park', FALSE, 10, 'draft',
                now() + interval '5 days', 120
            ),
            (
                'Beginner-Friendly Volleyball',
                'Casual beach volleyball for all skill levels. The focus is on fun, laughter, and meeting new people — not competition!',
                v_cat_sports, v_host, 'San Francisco', 'Ocean Beach', FALSE, 16, 'draft',
                now() + interval '8 days', 120
            ),
            (
                'Street Photography Walk',
                'Explore the city through your lens. We will walk through colorful neighborhoods capturing street life and architecture. Any camera welcome, including phones!',
                v_cat_photo, v_host, 'San Francisco', 'Mission District', FALSE, 8, 'draft',
                now() + interval '12 days', 150
            ),
            (
                'Acoustic Open Mic Night',
                'Share your music or just enjoy listening! A warm, supportive environment for musicians and music lovers alike.',
                v_cat_music, v_host, 'San Francisco', 'The Attic', FALSE, 20, 'draft',
                now() + interval '14 days', 180
            ),
            (
                'Watercolor Painting for Beginners',
                'Learn the basics of watercolor painting in this hands-on workshop. All materials provided. No experience needed — just bring your curiosity!',
                v_cat_art, v_host, 'San Francisco', 'ArtHouse Studio', FALSE, 10, 'draft',
                now() + interval '9 days', 120
            ),
            (
                'Homemade Pasta Workshop',
                'Learn to make fresh pasta from scratch! We will prepare three types of pasta and enjoy them together with wine and good conversation.',
                v_cat_food, v_host, 'San Francisco', 'Kitchen on Fire', FALSE, 8, 'draft',
                now() + interval '11 days', 180
            ),
            (
                'Contemporary Fiction Book Club',
                'This month we are reading "Tomorrow, and Tomorrow, and Tomorrow" by Gabrielle Zevin. Join us for a lively discussion over coffee and pastries.',
                v_cat_book, v_host, 'San Francisco', 'City Lights Bookstore', FALSE, 12, 'draft',
                now() + interval '15 days', 120
            ),
            (
                'Beach Cleanup & Brunch',
                'Make a difference while making friends! We will spend the morning cleaning up the beach, then enjoy brunch together at a nearby café.',
                v_cat_volunteer, v_host, 'San Francisco', 'Baker Beach', FALSE, 20, 'draft',
                now() + interval '6 days', 240
            );
        END;
    ELSE
        RAISE NOTICE 'No profiles found — skipping sample experiences. They require at least one signed-up user.';
    END IF;
END;
$$;
