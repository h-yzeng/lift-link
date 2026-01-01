import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Validation mode for the text field
enum ValidationMode {
  /// Validate on every change
  onChange,

  /// Validate when focus is lost
  onFocusLost,

  /// Validate only when form is submitted
  onSubmit,
}

/// Pre-defined validation types
enum ValidationType {
  /// Text validation (min/max length)
  text,

  /// Integer number validation
  integer,

  /// Decimal number validation
  decimal,

  /// Email validation
  email,

  /// Custom validation (use custom validator)
  custom,
}

/// A text field with built-in validation UI and consistent styling
class ValidatedTextField extends StatefulWidget {
  /// Controller for the text field
  final TextEditingController? controller;

  /// Label text
  final String? labelText;

  /// Hint text
  final String? hintText;

  /// Helper text shown below the field
  final String? helperText;

  /// Prefix icon
  final Widget? prefixIcon;

  /// Suffix icon
  final Widget? suffixIcon;

  /// Whether the field is required
  final bool isRequired;

  /// Type of validation to apply
  final ValidationType validationType;

  /// Custom validator function
  final String? Function(String? value)? customValidator;

  /// When to validate
  final ValidationMode validationMode;

  /// Minimum length for text validation
  final int? minLength;

  /// Maximum length for text validation
  final int? maxLength;

  /// Minimum value for number validation
  final double? minValue;

  /// Maximum value for number validation
  final double? maxValue;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  /// Max lines
  final int? maxLines;

  /// Whether the field is enabled
  final bool enabled;

  /// On changed callback
  final ValueChanged<String>? onChanged;

  /// On submitted callback
  final ValueChanged<String>? onSubmitted;

  /// Auto focus
  final bool autofocus;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  const ValidatedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.isRequired = false,
    this.validationType = ValidationType.text,
    this.customValidator,
    this.validationMode = ValidationMode.onChange,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.inputFormatters,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  String? _errorText;
  bool _hasInteracted = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    // Add focus listener for onFocusLost validation
    _focusNode.addListener(_onFocusChanged);

    // Add text change listener for onChange validation
    if (widget.validationMode == ValidationMode.onChange) {
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus &&
        widget.validationMode == ValidationMode.onFocusLost) {
      _validateField();
    }
  }

  void _onTextChanged() {
    if (_hasInteracted &&
        widget.validationMode == ValidationMode.onChange) {
      _validateField();
    }
  }

  void _validateField() {
    setState(() {
      _errorText = _getValidationError(_controller.text);
    });
  }

  String? _getValidationError(String? value) {
    // Custom validator takes precedence
    if (widget.customValidator != null) {
      return widget.customValidator!(value);
    }

    // Required check
    if (widget.isRequired && (value == null || value.trim().isEmpty)) {
      return '${widget.labelText ?? 'This field'} is required';
    }

    // If not required and empty, no error
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Type-specific validation
    switch (widget.validationType) {
      case ValidationType.text:
        return _validateText(value);
      case ValidationType.integer:
        return _validateInteger(value);
      case ValidationType.decimal:
        return _validateDecimal(value);
      case ValidationType.email:
        return _validateEmail(value);
      case ValidationType.custom:
        return null; // Already handled by customValidator
    }
  }

  String? _validateText(String value) {
    if (widget.minLength != null && value.length < widget.minLength!) {
      return 'Must be at least ${widget.minLength} characters';
    }
    if (widget.maxLength != null && value.length > widget.maxLength!) {
      return 'Must be at most ${widget.maxLength} characters';
    }
    return null;
  }

  String? _validateInteger(String value) {
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    if (widget.minValue != null && intValue < widget.minValue!) {
      return 'Must be at least ${widget.minValue!.toInt()}';
    }
    if (widget.maxValue != null && intValue > widget.maxValue!) {
      return 'Must be at most ${widget.maxValue!.toInt()}';
    }
    return null;
  }

  String? _validateDecimal(String value) {
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Please enter a valid number';
    }
    if (widget.minValue != null && doubleValue < widget.minValue!) {
      return 'Must be at least ${widget.minValue}';
    }
    if (widget.maxValue != null && doubleValue > widget.maxValue!) {
      return 'Must be at most ${widget.maxValue}';
    }
    return null;
  }

  String? _validateEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) {
      return widget.keyboardType!;
    }

    switch (widget.validationType) {
      case ValidationType.integer:
        return TextInputType.number;
      case ValidationType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case ValidationType.email:
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (widget.inputFormatters != null) {
      return widget.inputFormatters!;
    }

    switch (widget.validationType) {
      case ValidationType.integer:
        return [FilteringTextInputFormatter.digitsOnly];
      case ValidationType.decimal:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: _getKeyboardType(),
      textCapitalization: widget.textCapitalization,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      inputFormatters: _getInputFormatters(),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        errorText: _errorText,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
      ),
      onChanged: (value) {
        if (!_hasInteracted) {
          setState(() {
            _hasInteracted = true;
          });
        }
        widget.onChanged?.call(value);
      },
      onSubmitted: widget.onSubmitted,
    );
  }
}
