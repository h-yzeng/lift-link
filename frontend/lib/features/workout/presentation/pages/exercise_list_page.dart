import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/presentation/pages/create_exercise_page.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_list_filter_notifier.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart';
import 'package:liftlink/features/workout/presentation/widgets/exercise_card.dart';
import 'package:liftlink/shared/widgets/shimmer_loading.dart';

class ExerciseListPage extends ConsumerStatefulWidget {
  final bool selectionMode;

  const ExerciseListPage({
    this.selectionMode = false,
    super.key,
  });

  @override
  ConsumerState<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends ConsumerState<ExerciseListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync search controller with provider state
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(exerciseListFilterNotifierProvider.notifier)
        .setSearchQuery(_searchController.text);
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(exerciseListFilterNotifierProvider.notifier).clearAll();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(exerciseListFilterNotifierProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(exerciseListFilterNotifierProvider);
    final filterNotifier =
        ref.read(exerciseListFilterNotifierProvider.notifier);

    final exercisesAsync =
        filterState.isSearching && filterState.searchQuery.isNotEmpty
            ? ref.watch(exerciseSearchResultsProvider(filterState.searchQuery))
            : ref.watch(
                exerciseListProvider(
                  muscleGroup: filterState.selectedMuscleGroup,
                  equipmentType: filterState.selectedEquipmentType,
                  customOnly: filterState.showCustomOnly ? true : null,
                ),
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          if (filterState.hasActiveFilters)
            Semantics(
              label: 'Clear all filters and search',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: 'Clear filters',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Semantics(
                        label: 'Clear search text',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Filter chips
          if (!filterState.isSearching) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Muscle group filter
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All muscle groups'),
                      ),
                      ...MuscleGroups.all.map(
                        (group) => PopupMenuItem(
                          value: group,
                          child: Text(
                            group[0].toUpperCase() + group.substring(1),
                          ),
                        ),
                      ),
                    ],
                    onSelected: filterNotifier.setMuscleGroup,
                    child: Chip(
                      avatar: const Icon(Icons.filter_list, size: 18),
                      label: Text(
                        filterState.selectedMuscleGroup != null
                            ? filterState.selectedMuscleGroup![0]
                                    .toUpperCase() +
                                filterState.selectedMuscleGroup!.substring(1)
                            : 'Muscle Group',
                      ),
                      backgroundColor: filterState.selectedMuscleGroup != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Equipment filter
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All equipment'),
                      ),
                      ...EquipmentTypes.all.map(
                        (type) => PopupMenuItem(
                          value: type,
                          child: Text(
                            type[0].toUpperCase() + type.substring(1),
                          ),
                        ),
                      ),
                    ],
                    onSelected: filterNotifier.setEquipmentType,
                    child: Chip(
                      avatar: const Icon(Icons.fitness_center, size: 18),
                      label: Text(
                        filterState.selectedEquipmentType != null
                            ? filterState.selectedEquipmentType![0]
                                    .toUpperCase() +
                                filterState.selectedEquipmentType!.substring(1)
                            : 'Equipment',
                      ),
                      backgroundColor: filterState.selectedEquipmentType != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Custom only filter
                  FilterChip(
                    label: const Text('Custom Only'),
                    selected: filterState.showCustomOnly,
                    onSelected: filterNotifier.setShowCustomOnly,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              filterState.isSearching
                                  ? Icons.search_off
                                  : Icons.fitness_center,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            filterState.isSearching
                                ? 'No Exercises Found'
                                : 'Build Your Exercise Library',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            filterState.isSearching
                                ? 'Try adjusting your search term or filters to find what you\'re looking for.'
                                : 'Create custom exercises or pull down to sync from the cloud. Every great workout starts with the right exercises.',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          if (!filterState.isSearching) ...[
                            const SizedBox(height: 32),
                            FilledButton.icon(
                              onPressed: () =>
                                  _navigateToCreateExercise(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Custom Exercise'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(exerciseListProvider);
                  },
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ExerciseCard(
                        exercise: exercise,
                        onTap: widget.selectionMode
                            ? () {
                                Navigator.pop(context, {
                                  'id': exercise.id,
                                  'name': exercise.name,
                                });
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Selected: ${exercise.name}'),
                                  ),
                                );
                              },
                      );
                    },
                  ),
                );
              },
              loading: () => const ExerciseListSkeleton(),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading exercises',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(exerciseListProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateExercise(context),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
        tooltip: 'Create custom exercise',
      ),
    );
  }

  Future<void> _navigateToCreateExercise(BuildContext context) async {
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateExercisePage(),
      ),
    );

    if (result != null && widget.selectionMode && mounted) {
      if (!context.mounted) return;
      Navigator.pop(context, {
        'id': result.id,
        'name': result.name,
      });
    }
  }
}
