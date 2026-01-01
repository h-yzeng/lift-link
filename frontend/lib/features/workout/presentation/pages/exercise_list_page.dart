import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/presentation/pages/create_exercise_page.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart';
import 'package:liftlink/features/workout/presentation/widgets/exercise_card.dart';

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
  String? _selectedMuscleGroup;
  String? _selectedEquipmentType;
  bool _showCustomOnly = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedMuscleGroup = null;
      _selectedEquipmentType = null;
      _showCustomOnly = false;
      _searchController.clear();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = _isSearching && _searchController.text.isNotEmpty
        ? ref.watch(exerciseSearchResultsProvider(_searchController.text))
        : ref.watch(
            exerciseListProvider(
              muscleGroup: _selectedMuscleGroup,
              equipmentType: _selectedEquipmentType,
              customOnly: _showCustomOnly ? true : null,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          if (_selectedMuscleGroup != null ||
              _selectedEquipmentType != null ||
              _showCustomOnly ||
              _isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Clear filters',
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
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),

          // Filter chips
          if (!_isSearching) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Muscle group filter
                  PopupMenuButton<String>(
                    child: Chip(
                      avatar: const Icon(Icons.filter_list, size: 18),
                      label: Text(
                        _selectedMuscleGroup != null
                            ? _selectedMuscleGroup![0].toUpperCase() +
                                _selectedMuscleGroup!.substring(1)
                            : 'Muscle Group',
                      ),
                      backgroundColor: _selectedMuscleGroup != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
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
                    onSelected: (value) {
                      setState(() {
                        _selectedMuscleGroup = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),

                  // Equipment filter
                  PopupMenuButton<String>(
                    child: Chip(
                      avatar: const Icon(Icons.fitness_center, size: 18),
                      label: Text(
                        _selectedEquipmentType != null
                            ? _selectedEquipmentType![0].toUpperCase() +
                                _selectedEquipmentType!.substring(1)
                            : 'Equipment',
                      ),
                      backgroundColor: _selectedEquipmentType != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
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
                    onSelected: (value) {
                      setState(() {
                        _selectedEquipmentType = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),

                  // Custom only filter
                  FilterChip(
                    label: const Text('Custom Only'),
                    selected: _showCustomOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showCustomOnly = selected;
                      });
                    },
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? 'No exercises found'
                              : 'No exercises available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSearching
                              ? 'Try a different search term'
                              : 'Pull down to sync or create a custom exercise',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (!_isSearching) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _navigateToCreateExercise(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Exercise'),
                          ),
                        ],
                      ],
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
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
