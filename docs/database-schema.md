# LiftLink Database Schema

## Entity Relationship Diagram

```
┌─────────────┐         ┌───────────────────┐         ┌────────────────────────┐
│  profiles   │────────<│  workout_sessions │────────<│  exercise_performances │
│             │  1:N    │                   │   1:N   │                        │
└─────────────┘         └───────────────────┘         └────────────────────────┘
       │                                                         │
       │                                                         │ N:1
       │                                                         ▼
       │                                              ┌────────────────┐
       │                                              │   exercises    │
       │                                              └────────────────┘
       │                                                         │
       │                                                         │ 1:N
       │                                                         ▼
       │                                              ┌────────────────┐
       │                                              │      sets      │
       │                                              └────────────────┘
       │
       │ N:N (self-referencing)
       ▼
┌─────────────┐
│ friendships │
└─────────────┘
```

## Tables

### profiles
User profile information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, FK → auth.users | User ID from Supabase Auth |
| username | TEXT | UNIQUE, NOT NULL | Unique username |
| display_name | TEXT | | Display name |
| avatar_url | TEXT | | URL to avatar image |
| bio | TEXT | | User biography |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

### exercises
Exercise library (system + custom).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Exercise ID |
| name | TEXT | NOT NULL | Exercise name |
| description | TEXT | | Exercise description |
| muscle_group | TEXT | NOT NULL | chest, back, legs, shoulders, arms, core |
| equipment_type | TEXT | | barbell, dumbbell, machine, cable, bodyweight |
| is_custom | BOOLEAN | NOT NULL, DEFAULT FALSE | Is this a custom exercise? |
| created_by | UUID | FK → profiles | Creator (NULL for system exercises) |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

### workout_sessions
Individual workout sessions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Session ID |
| user_id | UUID | FK → profiles, NOT NULL | Owner of the workout |
| title | TEXT | NOT NULL | Workout title |
| notes | TEXT | | Workout notes |
| started_at | TIMESTAMPTZ | NOT NULL | When workout started |
| completed_at | TIMESTAMPTZ | | When workout ended (NULL if in progress) |
| duration_minutes | INTEGER | | Duration in minutes |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

### exercise_performances
Junction table between workouts and exercises.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Performance ID |
| workout_session_id | UUID | FK → workout_sessions, NOT NULL | Parent workout |
| exercise_id | UUID | FK → exercises, NOT NULL | Exercise performed |
| order_index | INTEGER | NOT NULL | Order in workout |
| notes | TEXT | | Performance notes |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

### sets
Individual sets within an exercise performance.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Set ID |
| exercise_performance_id | UUID | FK → exercise_performances, NOT NULL | Parent performance |
| set_number | INTEGER | NOT NULL | Set order (1, 2, 3...) |
| reps | INTEGER | NOT NULL, CHECK > 0 | Number of repetitions |
| weight_kg | DECIMAL(6,2) | NOT NULL, CHECK >= 0 | Weight in kilograms |
| is_warmup | BOOLEAN | NOT NULL, DEFAULT FALSE | Is this a warmup set? |
| is_dropset | BOOLEAN | NOT NULL, DEFAULT FALSE | Is this a dropset? |
| rpe | DECIMAL(3,1) | CHECK 0-10 | Rate of Perceived Exertion |
| notes | TEXT | | Set notes |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Note**: 1RM is **NOT stored** in the database. It is calculated client-side using the Epley Formula: `weight × (1 + reps/30)`

### friendships
Friend relationships between users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Friendship ID |
| requester_id | UUID | FK → profiles, NOT NULL | User who sent request |
| addressee_id | UUID | FK → profiles, NOT NULL | User who received request |
| status | TEXT | NOT NULL, CHECK (pending/accepted/rejected) | Friendship status |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

## Row Level Security Policies

### Profiles
- Users can view their own profile
- Users can view accepted friends' profiles
- Users can update their own profile

### Exercises
- Anyone can view system exercises (created_by IS NULL)
- Users can view their own custom exercises
- Users can create/update/delete their own custom exercises

### Workout Sessions
- Users can view their own workouts
- Users can view accepted friends' workouts (read-only)
- Users can create/update/delete their own workouts

### Exercise Performances & Sets
- Follow parent workout_session permissions
- Users can view their own and friends' data
- Users can only modify their own data

### Friendships
- Users can view friendships they're involved in
- Users can create friend requests (as requester)
- Addressees can update status (accept/reject)
- Either party can delete the friendship

## Indexes

Key indexes for performance:
- `idx_profiles_username` - Username lookups
- `idx_exercises_muscle_group` - Exercise filtering
- `idx_workout_sessions_user_id` - User's workouts
- `idx_workout_sessions_started_at` - Workout history sorting
- `idx_friendships_requester/addressee` - Friend lookups
- `idx_friendships_status` - Filtering by status

## Triggers

### updated_at Trigger
All tables have an `update_updated_at_column()` trigger that automatically updates the `updated_at` timestamp on any row modification.

### New User Profile Trigger
When a user signs up via Supabase Auth, the `handle_new_user()` trigger automatically creates a profile row.
