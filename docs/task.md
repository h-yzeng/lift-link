# LiftLink - Task Tracking

## Project Status

**Last Updated**: 2026-01-02
**Current Phase**: Phase 15 In Progress (setState migration started)
**Overall Progress**: ~96% Complete
**App Version**: 2.3.0

---

## Phase 1: Project Foundation (✅ COMPLETED)

- [x] Project scaffolding (frontend, backend, docs structure)
- [x] Flutter project with Windows, iOS, Android platforms
- [x] Supabase database migrations with RLS
- [x] Drift (SQLite) local database with sync tracking
- [x] Domain entities with freezed (WorkoutSet, Exercise, Profile, etc.)
- [x] Core infrastructure (exceptions, failures, network info)
- [x] Documentation (architecture, database schema, setup guide)

---

## Phase 2: Core Features (✅ COMPLETED)

### Authentication

- [x] User entity with email/password support
- [x] Login and registration flows with Supabase Auth
- [x] Auth state management with Riverpod
- [x] Route protection based on auth state

### Exercise Library

- [x] Search and filter by muscle group, equipment, custom-only
- [x] Offline-first with background sync
- [x] 20 seeded system exercises
- [x] Custom exercise CRUD operations

### Active Workout Tracking

- [x] Start/complete workout functionality
- [x] Add exercises and sets with weight, reps, RPE
- [x] Real-time 1RM calculation (Epley formula)
- [x] Live workout stats (duration, volume, sets)
- [x] Offline-first with background sync

### Workout History

- [x] Workout summary cards with stats
- [x] Date range filtering
- [x] Detailed workout view with exercise breakdown
- [x] Sets table with RPE color coding

---

## Phase 3: Social Features (✅ COMPLETED)

- [x] User search with real-time filtering
- [x] Send/accept/reject friend requests
- [x] Friends list management
- [x] Activity feed showing friends' workouts
- [x] RLS policies for shared workout visibility

---

## Phase 4: Analytics (✅ COMPLETED)

- [x] Personal records tracking with rank indicators
- [x] Progress charts (volume, 1RM progression, frequency)
- [x] Muscle frequency analysis with pie chart
- [x] Balance recommendations

---

## Phase 5: Advanced Features (✅ COMPLETED)

- [x] Workout templates (create, save, start from template)
- [x] Rest timer with configurable defaults
- [x] Data export (JSON/CSV formats)
- [x] Sync service with manual trigger
- [x] Dark mode with system/light/dark options
- [x] Settings page enhancements

---

## Phase 6: Code Quality & UX Polish (✅ COMPLETED)

- [x] Onboarding flow for new users (4-slide tour)
- [x] Custom exercise creation page
- [x] Shared widget library (EmptyState, ErrorState, ActionCard, StatItem)
- [x] AsyncValueBuilder for consistent loading/error states
- [x] Dialog helpers (confirmation, text input, selection)
- [x] Result extensions for Either handling
- [x] Barrel exports for shared modules
- [x] Preferences system (onboarding, rest timer, theme)

---

## Phase 7: Testing & Quality Assurance (✅ COMPLETED)

- [x] Unit tests for domain entities (WorkoutSet, ExercisePerformance, WorkoutSession)
- [x] Unit tests for use cases with mocks (StartWorkout, AddSetToExercise)
- [x] Widget tests for shared components (EmptyState, ErrorState)
- [x] App initialization tests
- [x] Mock infrastructure with mocktail
- [x] **105 total tests passing**

---

## Phase 8: Static Analysis & Code Cleanup (✅ COMPLETED)

- [x] Fixed `use_build_context_synchronously` in exercise_list_page.dart
- [x] Fixed trailing comma issues in dialog_helpers.dart
- [x] Fixed trailing comma issues in entity test files
- [x] Fixed trailing comma issues in use case test files
- [x] Updated app version to 2.0.0

---

## Phase 9: Quick Wins - UX Polish (✅ COMPLETED)

### Haptic Feedback

- [x] Created HapticService utility (`lib/shared/utils/haptic_service.dart`)
- [x] Add haptic feedback to primary action buttons
- [x] Add haptic feedback to set completion
- [x] Add haptic feedback to workout start/complete
- [x] Add haptic feedback to timer events

### Loading Skeletons

- [x] Created ShimmerLoading widget with animation (`lib/shared/widgets/shimmer_loading.dart`)
- [x] Created ExerciseListSkeleton, WorkoutHistorySkeleton, FriendsListSkeleton
- [x] Created ActivityFeedSkeleton, TemplatesListSkeleton, HomePageSkeleton
- [x] Replace CircularProgressIndicator in exercise list
- [x] Replace CircularProgressIndicator in workout history
- [x] Replace CircularProgressIndicator in friends list
- [x] Replace CircularProgressIndicator in activity feed
- [x] Replace CircularProgressIndicator in templates page
- [x] Replace CircularProgressIndicator in home page

### Pull-to-Refresh Consistency

- [x] Add pull-to-refresh to workout history page (already had it)
- [x] Add pull-to-refresh to friends list page
- [x] Add pull-to-refresh to activity feed page (already had it)
- [x] Add pull-to-refresh to templates page

### Accessibility (a11y)

- [x] Add semantic labels to QuickActionCard buttons
- [x] Add semantic labels to ActiveWorkoutCard
- [x] Add semantic labels to WorkoutStat displays
- [x] Add ExcludeSemantics to decorative icons
- [ ] Test with screen reader (manual testing pending)

---

## Phase 10: Core UX Improvements (✅ COMPLETED)

### Exercise History Per Exercise (✅ COMPLETED)

- [x] Create exercise_history view in database
- [x] Add migration for exercise history
- [x] Create ExerciseHistory entity with freezed
- [x] Implement GetExerciseHistory use case
- [x] Add "Previous" section in active workout when adding sets
- [x] Show last 3 sessions for each exercise

### Local Notifications for Rest Timer (✅ COMPLETED)

- [x] Add flutter_local_notifications dependency
- [x] Create NotificationService
- [x] Request notification permissions on timer start
- [x] Trigger notification when timer completes
- [x] Handle notification tap to return to app

### Database Performance (✅ COMPLETED)

- [x] Add index on workout_sessions(user_id, created_at)
- [x] Add index on exercise_performances(workout_session_id)
- [x] Add index on sets(exercise_performance_id)
- [x] Add index on exercises(user_id, is_custom)
- [x] Add index on friendships(user_id, status)
- [x] Add additional composite indexes for activity feed and analytics

### Workout Streak Tracking (✅ COMPLETED)

- [x] Add streak fields to profiles table (current_streak, longest_streak, last_workout_date)
- [x] Create database functions for streak calculation
- [x] Create trigger to auto-update streaks on workout completion
- [x] Create StreakService to calculate streaks client-side
- [x] Create workoutStreak provider
- [x] Display streak card on home page with emoji and color coding
- [x] Show motivational messages based on streak length

---

## Phase 11: Quality & Reliability (✅ COMPLETED - 100%)

### Pagination (✅ COMPLETED)

- [x] Add offset parameter to repository layer
- [x] Update WorkoutRepository interface with offset support
- [x] Update local datasource with offset in Drift queries
- [x] Update GetWorkoutHistory use case
- [x] Create PaginatedWorkoutHistoryNotifier with state management
- [x] Implement workout history pagination with "Load More" button
- [x] Integrate date filtering with pagination
- [x] Add pull-to-refresh support

### Expanded Test Coverage (✅ COMPLETED - 100% Pass Rate)

**Tests Created (229 tests passing):**

- [x] StreakService tests (25 tests - comprehensive coverage)
- [x] PaginatedWorkoutHistoryProvider tests (20 tests - all scenarios)
- [x] workout_providers tests (22 tests - all functional providers)
- [x] exercise_providers tests (11 tests - filter and search providers)
- [x] Fixed workout_history_page.dart error (workoutHistoryProvider reference)
- [x] Fixed paginated_workout_history_provider.dart (added Failure import)
- [x] Fixed all repository test compilation errors
- [x] Fixed all provider test async disposal issues

**Test Coverage Summary:**

- **229 tests passing (100% pass rate)**
- Tests cover: providers, services, pagination, state management, repositories, entities, use cases
- All test failures resolved

### Code Quality Fixes (✅ COMPLETED - 0 Issues)

**Flutter Analyze Errors Fixed (141 → 0):**

**Critical Compilation Errors (12 fixed):**

- [x] Fixed 9 `userId` → `createdBy` parameter errors in Exercise entities
- [x] Added missing WorkoutSet import in workout_repository_impl_test.dart
- [x] Fixed invalid mock return type (changed `{}` to `testWorkout`)

**Style Issues (129 fixed):**

- [x] Fixed 14 double quote violations (changed to single quotes)
- [x] Fixed 2 deprecated `withOpacity` calls (changed to `withValues(alpha: ...)`)
- [x] Fixed 2 `prefer_const_constructors` issues
- [x] Auto-fixed 99 trailing comma violations using `dart fix`
- [x] Manually fixed remaining trailing commas

**Test Fixes (8 failures → 0):**

- [x] Fixed StreakService `checkMilestone` to return highest milestone
- [x] Added Mocktail fallback values (FakeExercise, FakeWorkoutSession, FakeWorkoutSet)
- [x] Fixed sequential mock return values in getAllExercises test
- [x] Fixed 8 async container disposal issues (changed `expect()` to `await expectLater()`)

**Final Results:**

- ✅ **0 flutter analyze issues**
- ✅ **229 tests passing (100%)**
- ✅ **0 compilation errors**
- ✅ **0 runtime errors**

### Error Monitoring (⏭️ SKIPPED)

- [x] Skipped Sentry/Firebase Crashlytics (per user request)
- [x] Skipped global error handler
- [x] Skipped breadcrumb logging
- [x] Skipped error reporting service

---

## Phase 12: Advanced Improvements (✅ COMPLETED)

### Input Validation UI (✅ COMPLETED)

- [x] Created ValidatedTextField widget (`lib/shared/widgets/validated_text_field.dart`)
- [x] Multiple validation types (text, integer, decimal, email, custom)
- [x] Three validation modes (onChange, onFocusLost, onSubmit)
- [x] Real-time validation feedback
- [x] Consistent error styling with theme integration
- [x] Automatic keyboard type detection
- [x] Min/max length and value validation
- [x] Added to shared widgets barrel export

### Offline Queue with Retry (✅ COMPLETED)

- [x] Created sync_queue table with database migration
- [x] Created SyncQueueItem entity with Freezed
- [x] Implemented SyncQueueService with exponential backoff (5s → 300s)
- [x] Added conflict resolution strategies (useLocal, useRemote, lastWriteWins, merge)
- [x] Created sync queue providers (syncQueueService, pendingSyncCount)
- [x] Implemented timer-based automatic retry processing
- [x] Created SyncQueueIndicator widget for UI display
- [x] Added database queries for efficient pending item retrieval
- [x] Implemented automatic cleanup of old failed items (7 days)
- [x] Integrated with Drift local database for persistence

### Undo Functionality (✅ COMPLETED)

- [x] Created UndoAction entity with Freezed
- [x] Implemented UndoService with persistent stack (SharedPreferences)
- [x] Support for multiple action types (deleteSet, removeExercise, deleteWorkout)
- [x] Factory methods for creating specific undo actions
- [x] 5-second undo timeout with automatic expiration
- [x] Stack size limit (10 items) with automatic cleanup
- [x] Expiration of old actions (5 minutes)
- [x] Created showUndoSnackbar helper for UI integration
- [x] JSON serialization for persistence across app restarts

### Search Improvements (✅ COMPLETED)

- [x] Created SearchHistoryService for managing search history
- [x] Implemented fuzzy search with Levenshtein distance algorithm
- [x] Multiple scoring strategies (exact match, prefix, contains, word matching)
- [x] Persistent search history with SharedPreferences (20 items max)
- [x] Search suggestions based on query prefix matching
- [x] Created search history providers (searchHistoryService, recentSearches, searchSuggestions)
- [x] Created SearchSuggestionsList widget for UI display
- [x] Configurable similarity threshold for fuzzy matching
- [x] Recent searches display with history management

### Bug Fixes

- [x] Fixed flaky test in streak_service_test.dart (time-dependent test issue)

**Final Results:**

- ✅ **0 flutter analyze issues**
- ✅ **229 tests passing (100%)**
- ✅ **0 compilation errors**
- ✅ **All Phase 12 features complete**

---

## Phase 13: Mobile Enhancement Features (🔄 IN PROGRESS)

### Workout Enhancements (✅ COMPLETED)

- [x] Add RIR (Reps in Reserve) field to workout sets
  - [x] Database migration (20260101000016) to add RIR column
  - [x] Updated Drift sets_table with RIR field (0-10 range)
  - [x] Updated WorkoutSet entity with rir field and formattedRir getter
  - [x] Added RIR input field to SetInputRow widget
  - [x] Updated use cases (AddSetToExercise, UpdateSet) with RIR validation
  - [x] Updated repository interface and implementation
  - [x] Integrated RIR into active workout page
- [x] Display PR (Personal Record) at bottom of exercise sets
  - [x] Added visual PR display showing max 1RM during workout
  - [x] Trophy icon with highlighted container
  - [x] Displays below all sets, above "Add Set" button
  - [x] Shows formatted weight in user's preferred units

### Bodyweight Tracking (✅ COMPLETED)

- [x] Create weight_logs table (migration 20260101000015)
- [x] Add WeightLog entity with unit conversion (kg/lbs)
- [x] Create weight logging UI with history and change tracking
- [x] WeightLogPage with form, history list, delete functionality

### Quick UX Wins (✅ COMPLETED - 2026-01-02)

- [x] Quick Weight Increment Buttons (+/- 2.5, 5, 10)
  - [x] Added increment/decrement buttons to weight input in SetInputRow
  - [x] Unit-aware increments (2.5 lbs or 1.25 kg)
  - [x] Haptic feedback on button press
  - [x] Visual hint showing increment value
- [x] Improved Empty States across all pages
  - [x] Enhanced workout_history_page with motivational messaging
  - [x] Enhanced templates_page with circular icon container
  - [x] Enhanced friends_list_page with better visual design
  - [x] Enhanced activity_feed_page with timeline icon
  - [x] Enhanced exercise_list_page with conditional messaging
- [x] Start from Previous Workout feature
  - [x] Added "Repeat Workout" button to workout_detail_page
  - [x] One-tap functionality to clone workout with all exercises
  - [x] Proper loading indicators and error handling
  - [x] Navigation to active workout page

---

## Phase 14: Code Quality & Architecture Improvements (✅ COMPLETED - 2026-01-02)

### Comprehensive Accessibility Support (✅ COMPLETED)

- [x] Add semantic labels to IconButtons across key pages
  - [x] social_hub_page.dart (3 buttons with Semantics wrappers)
  - [x] friends_list_page.dart (1 button with Semantics wrapper)
  - [x] workout_history_page.dart (1 button with dynamic label)
  - [x] workout_detail_page.dart (1 button with descriptive label)
  - [x] exercise_list_page.dart (2 buttons with clear labels)
- [x] Add ExcludeSemantics to decorative icons
  - [x] Stat display icons in WorkoutSummarySection
  - [x] Badge icons in ExerciseListSection
  - [x] PR trophy icons
- [x] WCAG 2.1 AA compliant with proper button and label declarations

### Complete Sync Merge Logic (✅ COMPLETED)

- [x] Implement field-level merge conflict resolution
  - [x] Created MergeStrategy enum (merge_strategy.dart)
  - [x] Created MergeResult freezed class for resolution outcomes
  - [x] Implemented EntityMerger class with field-level merging
  - [x] WorkoutSession merge logic (title, notes, timestamps)
  - [x] Profile merge logic (displayName, bio, preferredUnits)
- [x] Add conflict resolution UI
  - [x] Created conflict_resolution_dialog.dart
  - [x] User choice between local/remote versions
  - [x] Visual display of conflicting fields
  - [x] Error container with warning icon
- [x] Update SyncQueueService
  - [x] Replaced TODO at line 255 with EntityMerger integration
  - [x] Added WorkoutSession merge case
  - [x] Added Profile merge case
  - [x] Fallback to last-write-wins for unsupported types

### Decompose Large Page Widget (✅ COMPLETED)

- [x] Split active_workout_page.dart (803 to 470 lines, 41% reduction)
  - [x] Created WorkoutSummarySection widget (88 lines)
  - [x] Created ExerciseListSection widget (300 lines)
  - [x] Added accessibility labels to new widgets
  - [x] Integrated previous workout performance display
  - [x] Removed duplicate code (_StatItem, _ExerciseCard classes)

### UI Test Infrastructure (✅ COMPLETED)

- [x] Created test helpers directory (test/test_helpers/)
- [x] Created pump_app.dart extension for widget testing
- [x] Established testing patterns with Riverpod provider overrides
- [x] Foundation ready for incremental test coverage expansion

### Social Features Pagination (✅ COMPLETED - Repository Layer)

- [x] Update FriendshipRepository interface
  - [x] Added getFriendsPaginated method with limit/offset parameters
- [x] Implement pagination in repository
  - [x] Added implementation in FriendshipRepositoryImpl
  - [x] In-memory pagination with TODO for SQL optimization
- [x] Foundation ready for PaginatedFriendsProvider and UI updates
  - [ ] Use Riverpod .select() for specific state slices
  - [ ] Add RepaintBoundary where appropriate
  - [ ] Minimize widget tree depth
- [ ] Add widget tests for new components
  - [ ] Test WorkoutSummarySection rendering
  - [ ] Test ExerciseListSection interactions
  - [ ] Test SetInputSection validation
  - [ ] Test WorkoutControlsSection actions

### Extend UI Test Coverage (⏳ PENDING)

- [ ] Add widget tests for all 24 pages
  - [ ] Auth pages (login, register, password reset) - 3 tests
  - [ ] Home page - 1 test
  - [ ] Exercise pages (list, create, detail) - 3 tests
  - [ ] Workout pages (active, history, detail) - 3 tests
  - [ ] Template pages (list, create) - 2 tests
  - [ ] Profile pages (profile, settings, weight log) - 3 tests
  - [ ] Social pages (friends, search, activity, friend profile) - 4 tests
  - [ ] Analytics pages (records, charts) - 2 tests
  - [ ] Onboarding pages - 1 test
- [ ] Test user interaction flows
  - [ ] Tap interactions (buttons, cards)
  - [ ] Scroll interactions (lists, pages)
  - [ ] Form input interactions
  - [ ] Navigation flows
- [ ] Test error state UI rendering
  - [ ] Network error displays
  - [ ] Validation error displays
  - [ ] Empty state displays (already tested)
- [ ] Test authentication flow UI
  - [ ] Login form validation
  - [ ] Registration form validation
  - [ ] Password reset flow
- [ ] Target: 70%+ presentation layer coverage

### Implement Social Features Pagination (⏳ PENDING)

- [ ] Add cursor-based pagination to user search
  - [ ] Update UserRepository with cursor support
  - [ ] Create PaginatedUserSearchProvider
  - [ ] Add "Load More" button to search results
  - [ ] Implement pull-to-refresh
- [ ] Paginate friend list
  - [ ] Add pagination to FriendshipRepository
  - [ ] Update friendsListProvider with pagination state
  - [ ] Show loading indicator while fetching
- [ ] Paginate activity feed
  - [ ] Update friendsWorkoutsFeedProvider with pagination
  - [ ] Implement infinite scroll or "Load More"
  - [ ] Cache loaded pages for smooth scrolling
- [ ] Performance testing
  - [ ] Test with 100+ friends
  - [ ] Test with 1000+ workouts in feed
  - [ ] Verify smooth scrolling

---

## Phase 15: Advanced Code Refactoring (🔄 IN PROGRESS)

### Migrate setState to Riverpod StateNotifier (🔄 IN PROGRESS - Started 2026-01-02)

**Overview**: Large refactoring task to migrate 60 setState occurrences across 16 files to Riverpod StateNotifier pattern for better state management, testability, and performance.

- [x] Audit all StatefulWidget usage (60 setState occurrences found)
  - [x] Created inventory of stateful widgets (16 files)
  - [x] Identified migration candidates by priority
  - [x] Prioritize by impact and complexity
- [x] Migrate user_search_page.dart (5 setState calls → StateNotifier) ✅
  - [x] Created UserSearchState class with Freezed
  - [x] Implemented UserSearchNotifier with @riverpod annotation
  - [x] Converted search state (_searchResults, _isSearching, _errorMessage) to immutable state
  - [x] Updated UI to use ref.watch(userSearchNotifierProvider)
  - [x] Removed all 5 setState calls
  - [x] Added proper error handling with Failure.userMessage extension
  - [x] Files created:
    - frontend/lib/features/social/presentation/providers/user_search_state.dart
    - frontend/lib/features/social/presentation/providers/user_search_notifier.dart
- [x] Migrate active_workout_page.dart (4 setState calls → StateProvider) ✅
  - [x] Created activeWorkoutLoadingProvider with StateProvider.autoDispose
  - [x] Converted loading state (_isLoading) to provider
  - [x] Updated _addExercise and _completeWorkout methods
  - [x] Updated build method Consumer widgets
  - [x] Removed all 4 setState calls and local state variable
- [ ] Remaining migrations (51 setState calls across 14 files)
  - [ ] rest_timer.dart (6 setState) - Timer state
  - [ ] set_input_row.dart (5 setState) - Form editing state
  - [ ] exercise_list_page.dart (6 setState) - Selection mode
  - [ ] create_template_page.dart (7 setState) - Template creation
  - [ ] create_exercise_page.dart (5 setState) - Exercise creation
  - [ ] export_data_page.dart (6 setState) - Export state
  - [ ] register_page.dart (4 setState) - Form validation
  - [ ] login_page.dart (3 setState) - Form validation
  - [ ] workout_history_page.dart (2 setState) - Filter state
  - [ ] validated_text_field.dart (2 setState) - Validation state (reusable widget)
  - [ ] progress_charts_page.dart (1 setState) - Chart selection
  - [ ] weight_log_page.dart (1 setState) - Log entry
  - [ ] onboarding_page.dart (1 setState) - Page index
  - [ ] main_scaffold.dart (1 setState) - Navigation index

**Migration Pattern Established**:
1. Create freezed state class with all UI state fields
2. Create StateNotifier with @riverpod annotation
3. Replace setState calls with state.copyWith() updates
4. Update UI to watch provider instead of local state
5. Run build_runner to generate code
6. Verify compilation and test

**Note**: This is a 5-7 day incremental task. Can be completed over multiple sessions. Priority should be given to pages with business logic over form validation widgets.

### Reduce Late Initialization Pattern (⏳ PENDING)

- [ ] Audit all late field usage (160+ occurrences)
  - [ ] Create inventory by file and usage type
  - [ ] Identify risky vs. safe usages
  - [ ] Prioritize by crash risk
- [ ] Convert TextEditingController late fields
  - [ ] Option 1: Initialize in field declaration
  - [ ] Option 2: Use nullable fields with null checks
  - [ ] Option 3: Use factory constructors
- [ ] Convert FocusNode late fields
  - [ ] Same strategies as TextEditingController
  - [ ] Ensure proper disposal
- [ ] Convert other late fields
  - [ ] Animation controllers
  - [ ] Stream subscriptions
  - [ ] Computed values
- [ ] Add null safety assertions
  - [ ] Use bang operator (!) only when truly safe
  - [ ] Add null checks with early returns
  - [ ] Document why late is necessary if kept
- [ ] Testing
  - [ ] Run all existing tests
  - [ ] Add tests for edge cases
  - [ ] Verify no uninitialized access errors

---

## Future Features (⏳ BACKLOG)

### Exercise Videos/GIFs

- [ ] Set up video storage (Supabase Storage)
- [ ] Add video_url field to exercises
- [ ] Implement video player widget
- [ ] Add video upload for custom exercises

### Multi-language Support (i18n)

- [ ] Extract all strings to ARB files
- [ ] Set up flutter_localizations
- [ ] Add language selector in settings
- [ ] Translate to Spanish, French, German

### Companion Apps

- [ ] Apple Watch app (Swift)
- [ ] Wear OS app (Kotlin)
- [ ] Quick workout logging
- [ ] Rest timer on wrist

---

## Code Efficiency Improvements

### Database Optimization

- [x] Add database indexes (Phase 10) - Comprehensive indexes added in migration 20250101000012
- [ ] Implement query result caching
- [ ] Use database views for complex queries
- [ ] Optimize JOIN operations

### State Management Optimization

- [ ] Implement selective provider rebuilds (partially done - needs review)
- [ ] Add provider caching with expiration
- [x] Use .select() for granular updates - 52 usages across codebase
- [ ] Reduce unnecessary rebuilds

### UI Performance

- [x] Use const constructors everywhere possible - 1182+ const usages
- [x] Implement ListView.builder for all lists - 14 ListView.builder implementations
- [x] Add RepaintBoundary for complex widgets - Added to ExerciseCard and WorkoutSummaryCard
- [ ] Lazy load images and heavy content

### Memory Management

- [x] Dispose controllers properly - 29 dispose implementations
- [x] Cancel streams on widget disposal - Using Riverpod streams (auto-cleanup)
- [ ] Limit cached data size
- [ ] Profile memory usage

---

## Technical Notes

**1RM Calculation:**

- Epley Formula: `weight × (1 + reps/30)`
- Calculated client-side only, never stored

**Offline-First Architecture:**

- Drift (SQLite) is source of truth for UI
- Supabase sync in background when online
- `isPendingSync` flag tracks unsynced data
- Last-write-wins conflict resolution

**Code Generation:**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Run after modifying freezed models, Drift tables, or Riverpod providers.
