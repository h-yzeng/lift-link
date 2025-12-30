/// Utility class for converting between metric and imperial units
class UnitConversion {
  static const double kgToLbsMultiplier = 2.20462;
  static const double lbsToKgMultiplier = 0.453592;

  /// Convert kilograms to pounds
  static double kgToLbs(double kg) {
    return kg * kgToLbsMultiplier;
  }

  /// Convert pounds to kilograms
  static double lbsToKg(double lbs) {
    return lbs * lbsToKgMultiplier;
  }

  /// Format weight with appropriate unit label
  static String formatWeight(double kg, bool useImperial) {
    if (useImperial) {
      final lbs = kgToLbs(kg);
      return '${lbs.toStringAsFixed(1)} lbs';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  /// Format weight without unit label (for input fields)
  static String formatWeightValue(double kg, bool useImperial) {
    if (useImperial) {
      final lbs = kgToLbs(kg);
      return lbs.toStringAsFixed(1);
    }
    return kg.toStringAsFixed(1);
  }

  /// Get the unit label
  static String getWeightUnit(bool useImperial) {
    return useImperial ? 'lbs' : 'kg';
  }
}
