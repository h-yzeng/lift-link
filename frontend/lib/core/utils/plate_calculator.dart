/// Utility for calculating barbell plate loading
class PlateCalculator {
  // Standard barbell weights
  static const double standardBarbellKg = 20.0; // Olympic barbell
  static const double standardBarbellLbs = 45.0; // Standard US barbell

  // Standard plate weights (pairs)
  static const List<double> standardPlatesKg = [
    25.0,
    20.0,
    15.0,
    10.0,
    5.0,
    2.5,
    1.25,
    0.5,
  ];

  static const List<double> standardPlatesLbs = [
    45.0,
    35.0,
    25.0,
    10.0,
    5.0,
    2.5,
  ];

  /// Calculate which plates to load on each side of the barbell
  /// Returns a map of plate weight to count per side
  static Map<double, int> calculatePlates({
    required double targetWeight,
    required bool useImperial,
    double? barbellWeight,
  }) {
    final barbell =
        barbellWeight ?? (useImperial ? standardBarbellLbs : standardBarbellKg);
    final plates = useImperial ? standardPlatesLbs : standardPlatesKg;

    // Weight to load on each side (excluding barbell)
    double remainingWeight = (targetWeight - barbell) / 2;

    if (remainingWeight <= 0) {
      return {}; // Target weight is less than barbell weight
    }

    final Map<double, int> plateCount = {};

    // Greedy algorithm: use largest plates first
    for (final plate in plates) {
      if (remainingWeight >= plate) {
        final count = (remainingWeight / plate).floor();
        if (count > 0) {
          plateCount[plate] = count;
          remainingWeight -= plate * count;
        }
      }
    }

    return plateCount;
  }

  /// Format the plate loading result for display
  static String formatPlateLoading({
    required double targetWeight,
    required bool useImperial,
    double? barbellWeight,
  }) {
    final plates = calculatePlates(
      targetWeight: targetWeight,
      useImperial: useImperial,
      barbellWeight: barbellWeight,
    );

    if (plates.isEmpty) {
      final barbell = barbellWeight ??
          (useImperial ? standardBarbellLbs : standardBarbellKg);
      if (targetWeight <= barbell) {
        return 'Empty bar';
      }
      return 'Cannot load exactly';
    }

    final unit = useImperial ? 'lb' : 'kg';
    final parts = plates.entries
        .map((e) =>
            '${e.value}×${e.key.toStringAsFixed(e.key % 1 == 0 ? 0 : 1)}$unit')
        .toList();

    return parts.join(' + ');
  }

  /// Get the actual weight that will be loaded (may differ from target due to plate availability)
  static double getActualWeight({
    required double targetWeight,
    required bool useImperial,
    double? barbellWeight,
  }) {
    final barbell =
        barbellWeight ?? (useImperial ? standardBarbellLbs : standardBarbellKg);
    final plates = calculatePlates(
      targetWeight: targetWeight,
      useImperial: useImperial,
      barbellWeight: barbellWeight,
    );

    if (plates.isEmpty) return barbell;

    final loadedWeight =
        plates.entries.fold<double>(0, (sum, e) => sum + (e.key * e.value * 2));

    return barbell + loadedWeight;
  }
}
