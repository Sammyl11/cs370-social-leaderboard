-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR CHAT SYSTEM
-- ============================================================
-- Run this SQL in your Supabase SQL Editor to enable chat functionality
-- ============================================================

-- Enable RLS on squad_chat_room table
ALTER TABLE public.squad_chat_room ENABLE ROW LEVEL SECURITY;

-- Policy: Squad members can view their squad's chat room
CREATE POLICY "Squad members can view chat room"
ON public.squad_chat_room
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM public.squad_membership
        WHERE squad_membership.squad_id = squad_chat_room.squad_id
        AND squad_membership.user_id = auth.uid()
    )
);

-- Policy: Squad members can create chat rooms for their squads
CREATE POLICY "Squad members can create chat room"
ON public.squad_chat_room
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.squad_membership
        WHERE squad_membership.squad_id = squad_chat_room.squad_id
        AND squad_membership.user_id = auth.uid()
    )
);

-- Enable RLS on chat_message table
ALTER TABLE public.chat_message ENABLE ROW LEVEL SECURITY;

-- Policy: Squad members can view messages in their squad's chat
CREATE POLICY "Squad members can view messages"
ON public.chat_message
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM public.squad_chat_room
        JOIN public.squad_membership ON squad_membership.squad_id = squad_chat_room.squad_id
        WHERE squad_chat_room.id = chat_message.squad_chat_id
        AND squad_membership.user_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1
        FROM public.leaderboard_chat_room
        JOIN public.leaderboard_membership ON leaderboard_membership.leaderboard_id = leaderboard_chat_room.leaderboard_id
        WHERE leaderboard_chat_room.id = chat_message.leaderboard_chat_id
        AND leaderboard_membership.user_id = auth.uid()
    )
);

-- Policy: Squad members can send messages to their squad's chat
CREATE POLICY "Squad members can send messages"
ON public.chat_message
FOR INSERT
WITH CHECK (
    auth.uid() = user_id
    AND (
        EXISTS (
            SELECT 1
            FROM public.squad_chat_room
            JOIN public.squad_membership ON squad_membership.squad_id = squad_chat_room.squad_id
            WHERE squad_chat_room.id = chat_message.squad_chat_id
            AND squad_membership.user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1
            FROM public.leaderboard_chat_room
            JOIN public.leaderboard_membership ON leaderboard_membership.leaderboard_id = leaderboard_chat_room.leaderboard_id
            WHERE leaderboard_chat_room.id = chat_message.leaderboard_chat_id
            AND leaderboard_membership.user_id = auth.uid()
        )
    )
);

-- Policy: Users can update their own messages (optional - for editing)
CREATE POLICY "Users can update own messages"
ON public.chat_message
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own messages (optional - for deleting)
CREATE POLICY "Users can delete own messages"
ON public.chat_message
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================
-- ENABLE REALTIME FOR CHAT MESSAGES
-- ============================================================
-- Note: Realtime must be enabled in Supabase Dashboard
-- Go to Database → Replication → Enable replication for chat_message table

-- Enable replication for chat_message table (if not already enabled)
-- This is typically done via the Supabase Dashboard, but can also be done via SQL:
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_message;







-- ============================================================
-- COMPLETE SETUP
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ENUMS
CREATE TYPE squad_role AS ENUM ('member', 'admin', 'owner');
CREATE TYPE leaderboard_role AS ENUM ('member', 'admin');
CREATE TYPE leaderboard_status AS ENUM ('active', 'archived');
CREATE TYPE match_status AS ENUM ('scheduled', 'submitted', 'under_review', 'approved', 'rejected', 'completed', 'canceled');
CREATE TYPE result_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE line_outcome AS ENUM ('win', 'loss', 'draw');

-- UTILITY FUNCTIONS
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS 'BEGIN NEW.updated_at = now(); RETURN NEW; END;';

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS 'BEGIN INSERT INTO public."user" (id, email, username) VALUES (new.id, new.email, new.email); RETURN new; END;';

-- TABLES
CREATE TABLE public."user" (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT NOT NULL UNIQUE,
  email         TEXT NOT NULL UNIQUE,
  first_name    TEXT,
  last_name     TEXT,
  phone         TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (length(email) <= 320)
);

CREATE TRIGGER trg_user_updated BEFORE UPDATE ON public."user"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.squad (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  created_by  UUID NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_squad_updated BEFORE UPDATE ON public.squad
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.squad_membership (
  id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  squad_id  BIGINT NOT NULL REFERENCES public.squad(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  role      squad_role NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (squad_id, user_id)
);

CREATE TABLE public.leaderboard (
  id                         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  squad_id                   BIGINT NOT NULL REFERENCES public.squad(id) ON DELETE CASCADE,
  name                       TEXT NOT NULL,
  game_name                  TEXT NOT NULL,
  admin_user_id              UUID NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  status                     leaderboard_status NOT NULL DEFAULT 'active',
  current_champion_user_id   UUID REFERENCES public."user"(id) ON DELETE SET NULL,
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_leaderboard_updated BEFORE UPDATE ON public.leaderboard
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.leaderboard_membership (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  leaderboard_id BIGINT NOT NULL REFERENCES public.leaderboard(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  role           leaderboard_role NOT NULL DEFAULT 'member',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (leaderboard_id, user_id)
);

CREATE TABLE public.pinned_leaderboard (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  leaderboard_id BIGINT NOT NULL REFERENCES public.leaderboard(id) ON DELETE CASCADE,
  pin_rank       INTEGER NOT NULL CHECK (pin_rank >= 1),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, leaderboard_id)
);

CREATE TABLE public.match_result (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  leaderboard_id BIGINT NOT NULL REFERENCES public.leaderboard(id) ON DELETE CASCADE,
  status         result_status NOT NULL DEFAULT 'pending',
  submitted_by   UUID NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  reviewed_by    UUID REFERENCES public."user"(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.result_line (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  match_result_id BIGINT NOT NULL REFERENCES public.match_result(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  score           INTEGER,
  outcome         line_outcome,
  UNIQUE (match_result_id, user_id)
);

CREATE TABLE public.match (
  id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  squad_id           BIGINT NOT NULL REFERENCES public.squad(id) ON DELETE CASCADE,
  leaderboard_id     BIGINT NOT NULL REFERENCES public.leaderboard(id) ON DELETE CASCADE,
  player1_user_id    UUID NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  player2_user_id    UUID NOT NULL REFERENCES public."user"(id) ON DELETE RESTRICT,
  player1_points     INTEGER,
  player2_points     INTEGER,
  winner_user_id     UUID REFERENCES public."user"(id) ON DELETE SET NULL,
  status             match_status NOT NULL DEFAULT 'scheduled',
  submitted_by       UUID REFERENCES public."user"(id) ON DELETE SET NULL,
  reviewed_by        UUID REFERENCES public."user"(id) ON DELETE SET NULL,
  played_at          TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.squad_chat_room (
  id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  squad_id  BIGINT NOT NULL REFERENCES public.squad(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.leaderboard_chat_room (
  id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  leaderboard_id     BIGINT NOT NULL REFERENCES public.leaderboard(id) ON DELETE CASCADE,
  squad_chat_room_id BIGINT NOT NULL REFERENCES public.squad_chat_room(id) ON DELETE CASCADE,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.chat_message (
  id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id             UUID NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  squad_chat_id       BIGINT REFERENCES public.squad_chat_room(id) ON DELETE CASCADE,
  leaderboard_chat_id BIGINT REFERENCES public.leaderboard_chat_room(id) ON DELETE CASCADE,
  body                TEXT NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (squad_chat_id IS NOT NULL OR leaderboard_chat_id IS NOT NULL)
);

-- INDEXES
CREATE INDEX idx_user_email ON public."user"(email);
CREATE INDEX idx_squad_created_by ON public.squad(created_by);
CREATE INDEX idx_sm_user ON public.squad_membership(user_id);
CREATE INDEX idx_sm_squad ON public.squad_membership(squad_id);
CREATE INDEX idx_lb_squad ON public.leaderboard(squad_id);
CREATE INDEX idx_lb_admin ON public.leaderboard(admin_user_id);
CREATE INDEX idx_lb_current_champion ON public.leaderboard(current_champion_user_id);
CREATE INDEX idx_lbm_user ON public.leaderboard_membership(user_id);
CREATE INDEX idx_lbm_leaderboard ON public.leaderboard_membership(leaderboard_id);
CREATE INDEX idx_pin_user ON public.pinned_leaderboard(user_id);
CREATE INDEX idx_pin_leaderboard ON public.pinned_leaderboard(leaderboard_id);
CREATE INDEX idx_mr_leaderboard ON public.match_result(leaderboard_id);
CREATE INDEX idx_mr_submitted_by ON public.match_result(submitted_by);
CREATE INDEX idx_rl_result ON public.result_line(match_result_id);
CREATE INDEX idx_rl_user ON public.result_line(user_id);
CREATE INDEX idx_match_leaderboard ON public.match(leaderboard_id);
CREATE INDEX idx_match_squad ON public.match(squad_id);
CREATE INDEX idx_match_played_at ON public.match(played_at DESC);
CREATE INDEX idx_scr_squad ON public.squad_chat_room(squad_id);
CREATE INDEX idx_lcr_leaderboard ON public.leaderboard_chat_room(leaderboard_id);
CREATE INDEX idx_chat_user ON public.chat_message(user_id);
CREATE INDEX idx_chat_squad_room_time ON public.chat_message(squad_chat_id, created_at DESC);
CREATE INDEX idx_chat_leaderboard_room_time ON public.chat_message(leaderboard_chat_id, created_at DESC);

-- ROW LEVEL SECURITY (RLS)
ALTER TABLE public."user" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public user profiles are viewable"
ON public."user"
FOR SELECT
USING (true);

CREATE POLICY "Users can update their own profile"
ON public."user"
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- TRIGGERS FOR AUTH INTEGRATION
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();








-- ============================================================
-- SQUAD TABLE SCHEMA UPDATE on 11/16/2025
-- ============================================================

-- Add missing fields to squad table
ALTER TABLE public.squad 
ADD COLUMN IF NOT EXISTS game_title TEXT,
ADD COLUMN IF NOT EXISTS skill_tier TEXT,
ADD COLUMN IF NOT EXISTS invite_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'public'));

-- Add index on invite_code for faster lookups
CREATE INDEX IF NOT EXISTS idx_squad_invite_code ON public.squad(invite_code);

-- Add comment for documentation
COMMENT ON COLUMN public.squad.game_title IS 'Primary game for this squad';
COMMENT ON COLUMN public.squad.skill_tier IS 'Skill level tier (e.g., Immortal, Grandmaster)';
COMMENT ON COLUMN public.squad.invite_code IS 'Unique invite code for joining private squads';
COMMENT ON COLUMN public.squad.visibility IS 'Squad visibility: private or public';









SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'match_result' 
AND column_name = 'evidence_url';











CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS text LANGUAGE plpgsql AS $$
DECLARE code text;
BEGIN
  LOOP
    code := upper(replace(gen_random_uuid()::text, '-', ''));
    code := substring(code FROM 1 FOR 12);
    code := regexp_replace(code, '(.{4})', '\1-', 'g');
    code := trim(trailing '-' FROM code);
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.squad WHERE invite_code = code);
  END LOOP;
  RETURN code;
END;
$$;

ALTER TABLE public.squad
  ALTER COLUMN invite_code SET DEFAULT public.generate_invite_code();

UPDATE public.squad
SET invite_code = public.generate_invite_code()
WHERE invite_code IS NULL;


