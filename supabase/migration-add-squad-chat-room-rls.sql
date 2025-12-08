-- ============================================================
-- MIGRATION: Add/Update RLS policies for squad_chat_room
-- ============================================================
-- This migration ensures Row Level Security policies are correctly
-- configured for squad_chat_room. It's idempotent and safe to run multiple times.
-- ============================================================

-- Enable RLS on squad_chat_room (idempotent - safe if already enabled)
ALTER TABLE public.squad_chat_room ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts and ensure consistency)
-- Note: The existing policies in All_Supabase_Scripts.sql have slightly different names,
-- but we'll ensure the correct policies are in place.

DROP POLICY IF EXISTS "Squad members can view chat room" ON public.squad_chat_room;
DROP POLICY IF EXISTS "Squad members can view chat rooms" ON public.squad_chat_room;
DROP POLICY IF EXISTS "Squad members can create chat room" ON public.squad_chat_room;
DROP POLICY IF EXISTS "Squad members can create chat rooms" ON public.squad_chat_room;
DROP POLICY IF EXISTS "Squad owners can update chat rooms" ON public.squad_chat_room;

-- Policy: Allow squad members to view chat rooms for squads they belong to
CREATE POLICY "Squad members can view chat rooms"
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

-- Policy: Allow squad members or squad creators to create chat rooms
-- This policy is permissive to handle timing issues during squad creation.
-- It allows creation if:
-- 1. User is a squad member (for existing squads), OR
-- 2. User is the squad creator (for new squads - this is checked FIRST to avoid timing issues)
CREATE POLICY "Squad members can create chat rooms"
ON public.squad_chat_room
FOR INSERT
WITH CHECK (
    -- FIRST check if user is the squad creator (most reliable, no timing issues)
    EXISTS (
        SELECT 1
        FROM public.squad
        WHERE squad.id = squad_chat_room.squad_id
        AND squad.created_by = auth.uid()
    )
    OR
    -- OR allow if user is a squad member (for existing squads)
    EXISTS (
        SELECT 1
        FROM public.squad_membership
        WHERE squad_membership.squad_id = squad_chat_room.squad_id
        AND squad_membership.user_id = auth.uid()
    )
);

-- Policy: Allow squad owners/admins to update chat rooms for their squads
-- (Optional - for future functionality if needed)
CREATE POLICY "Squad owners can update chat rooms"
ON public.squad_chat_room
FOR UPDATE
USING (
    EXISTS (
        SELECT 1
        FROM public.squad_membership
        WHERE squad_membership.squad_id = squad_chat_room.squad_id
        AND squad_membership.user_id = auth.uid()
        AND squad_membership.role IN ('owner', 'admin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.squad_membership
        WHERE squad_membership.squad_id = squad_chat_room.squad_id
        AND squad_membership.user_id = auth.uid()
        AND squad_membership.role IN ('owner', 'admin')
    )
);

-- Note: We don't need a DELETE policy since chat rooms are deleted
-- automatically via CASCADE when squads are deleted.

