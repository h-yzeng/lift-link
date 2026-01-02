import 'package:freezed_annotation/freezed_annotation.dart';

part 'weight_log.freezed.dart';

@freezed
class WeightLog with _$WeightLog {
  const factory WeightLog({
    required String id,
    required String userId,
    required double weight,
    required String unit,
    String? notes,
    required DateTime loggedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WeightLog;

  const WeightLog._();

  /// Convert weight to kg for consistent calculations
  double get weightInKg => unit == 'kg' ? weight : weight * 0.453592;

  /// Convert weight to lbs for display
  double get weightInLbs => unit == 'lbs' ? weight : weight * 2.20462;

  /// Get formatted weight string with unit
  String get formattedWeight => '${weight.toStringAsFixed(1)} $unit';

  /// Get weight change from another log (positive = gained, negative = lost)
  double weightChangeTo(WeightLog other) {
    if (unit == other.unit) {
      return weight - other.weight;
    }
    // Convert to kg for comparison if units differ
    return weightInKg - other.weightInKg;
  }

  /// Get percentage change from another log
  double? percentageChangeTo(WeightLog other) {
    if (other.weight == 0) return null;
    final change = weightChangeTo(other);
    final baseWeight = unit == other.unit ? other.weight : other.weightInKg;
    return (change / baseWeight) * 100;
  }
}
