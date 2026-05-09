# Leechai Product Context

Use this file as a quick memory refresh before any product design work.

## What This App Does

Leechai is a personal finance journaling app.
It helps users record daily money movement, track assets, and understand trends.

## Core Experience

- Daily entry and monthly journal review
- Statistics overview for spending and net worth trends
- Account and asset management
- Budget setup and budget progress visibility
- Category and tag management for clearer records
- Profile settings for theme, notifications, feedback, and cloud sync

## Product Characteristics

- Mobile-first and fast to log
- Supports local-first usage with cloud sync capability
- Focuses on practical financial clarity instead of heavy financial jargon
- Emphasizes confidence and continuity in daily tracking behavior
- Mascot is a Shiba Inu; use it as a warm, friendly brand cue in suitable surfaces and copy

## Design Style Direction

- Warm, calm, and trustworthy visual tone
- Comfortable density, clear hierarchy, and clean spacing rhythm
- Friendly and encouraging interaction language
- Polished but not flashy; clarity first, delight second

## UX Principles for This Product

- Reduce logging friction and time-to-complete
- Keep user control high for edits and corrections
- Make trends understandable at a glance
- Handle empty/loading/error states as first-class experiences
- Keep interactions consistent across journal, statistics, assets, and profile

## Interaction and Motion Tone

- Motion should be subtle and meaningful
- Feedback should be immediate for create, update, delete, and sync actions
- Avoid dramatic transitions that distract from bookkeeping tasks

## Copy Tone

- Direct, concise, and supportive
- Avoid blame language when users miss data or have inconsistent records
- Prefer action-oriented labels and messages

## Technical Context

This app is **offline-first**: it works fully without network. When online, local data syncs to the cloud. The **same account can be active on multiple devices**. When advising on architecture, APIs, or database design, always consider:

- **Local-first data model** — Local DB is source of truth; design for offline CRUD and sync metadata (e.g. `updated_at`, `synced_at`, client-generated stable IDs).
- **Multi-device & conflicts** — Use client-generated UUIDs for entities to avoid ID collisions across devices; define conflict resolution (e.g. last-write-wins, vector clocks, or CRDTs where needed).
- **Sync boundaries** — Data is scoped by account; design schemas and sync payloads so multi-device merge and incremental sync are feasible.
