/// Utility for generating warmup sets based on working weight
class WarmupSetGenerator {
  /// Generate warmup sets based on working weight
  /// Returns list of (weight percentage, reps) tuples
  static List<({double weight, int reps})> generateWarmupSets({
    required double workingWeight,
    required bool useImperial,
  }) {
    // Don't generate warmups for very light weights
    final minWeight = useImperial ? 95.0 : 40.0; // 95 lbs or 40 kg
    if (workingWeight < minWeight) {
      return [];
    }

    // Standard warmup protocol:
    // Set 1: 50% x 8-10 reps
    // Set 2: 70% x 5 reps
    // Set 3: 85% x 3 reps
    return [
      (weight: workingWeight * 0.50, reps: 8),
      (weight: workingWeight * 0.70, reps: 5),
      (weight: workingWeight * 0.85, reps: 3),
    ];
  }

  /// Format warmup set for display
  static String formatWarmupSet({
    required double weight,
    required int reps,
    required bool useImperial,
  }) {
    final unit = useImperial ? 'lb' : 'kg';
    return '${weight.toStringAsFixed(1)} $unit × $reps reps';
  }
}
