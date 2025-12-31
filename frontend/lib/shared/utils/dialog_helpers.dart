import 'package:flutter/material.dart';

/// Shows a confirmation dialog and returns true if confirmed.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shows a text input dialog and returns the entered text.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? labelText,
  String? hintText,
  int? maxLength,
  int maxLines = 1,
  String saveLabel = 'Save',
  String cancelLabel = 'Cancel',
  String? Function(String)? validator,
  TextInputType? keyboardType,
  bool obscureText = false,
  Widget? prefix,
}) async {
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefix: prefix,
            border: maxLines > 1 ? const OutlineInputBorder() : null,
            alignLabelWithHint: maxLines > 1,
          ),
          validator: validator != null
              ? (value) => validator(value ?? '')
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? true) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: Text(saveLabel),
        ),
      ],
    ),
  );

  return result;
}

/// Shows a selection dialog with options.
Future<T?> showSelectionDialog<T>(
  BuildContext context, {
  required String title,
  required List<SelectionOption<T>> options,
  T? selectedValue,
}) async {
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...options.map((option) => ListTile(
                leading: option.icon != null ? Icon(option.icon) : null,
                title: Text(option.label),
                subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                trailing: selectedValue == option.value
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, option.value),
              )),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

/// A selection option for showSelectionDialog.
class SelectionOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const SelectionOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}
