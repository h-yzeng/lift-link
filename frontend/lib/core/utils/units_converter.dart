/// Utility class for converting between imperial and metric units.
class UnitsConverter {
  // Weight conversions
  static const double kgToLbs = 2.20462;
  static const double lbsToKg = 0.453592;

  // Distance conversions
  static const double cmToInches = 0.393701;
  static const double inchesToCm = 2.54;
  static const double metersToFeet = 3.28084;
  static const double feetToMeters = 0.3048;

  /// Convert kilograms to pounds
  static double kgToPounds(double kg) => kg * kgToLbs;

  /// Convert pounds to kilograms
  static double poundsToKg(double lbs) => lbs * lbsToKg;

  /// Convert centimeters to inches
  static double cmToInchesConvert(double cm) => cm * cmToInches;

  /// Convert inches to centimeters
  static double inchesToCmConvert(double inches) => inches * inchesToCm;

  /// Convert meters to feet
  static double metersToFeetConvert(double meters) => meters * metersToFeet;

  /// Convert feet to meters
  static double feetToMetersConvert(double feet) => feet * feetToMeters;

  /// Format weight with appropriate unit
  static String formatWeight(double kg, {required bool imperial}) {
    if (imperial) {
      final lbs = kgToPounds(kg);
      return '${lbs.toStringAsFixed(1)} lbs';
    } else {
      return '${kg.toStringAsFixed(1)} kg';
    }
  }

  /// Format weight value only (no unit)
  static String formatWeightValue(double kg, {required bool imperial}) {
    if (imperial) {
      return kgToPounds(kg).toStringAsFixed(1);
    } else {
      return kg.toStringAsFixed(1);
    }
  }

  /// Get weight unit label
  static String getWeightUnit({required bool imperial}) {
    return imperial ? 'lbs' : 'kg';
  }

  /// Parse weight input and convert to kg (internal storage format)
  static double parseWeight(String input, {required bool imperial}) {
    final value = double.tryParse(input) ?? 0.0;
    return imperial ? poundsToKg(value) : value;
  }
}
