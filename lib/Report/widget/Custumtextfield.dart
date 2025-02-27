import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFieldRow extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final String? hintText;
  final bool isDropdown;
  final List<String>? dropdownItems;
  final int? selectedValue;
  final void Function(int?)? onChanged;
  final String? errorMessage;
  final int? maxLength;
  final bool obscureText;
  final double? length;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final int? selectedIndex;
  final bool numbersOnly; // New parameter for controlling input type

  const CustomTextFieldRow({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.isDropdown = false,
    this.dropdownItems,
    this.selectedValue,
    this.onChanged,
    this.length,
    this.errorMessage,
    this.maxLength,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
    this.selectedIndex,
    this.numbersOnly =
        false, // Default to false (allow both numbers and letters)
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: SizedBox(
                width: length ??
                    120.0, // Use 'length' if provided, otherwise default
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey, // Label color
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: isDropdown
                ? DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 10.0,
                      ),
                      hintText: hintText,
                      hintStyle: const TextStyle(
                          color: Colors.grey), // Hint text color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0)), // Light grey border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      filled: true, // Fill the background
                      fillColor: Colors.white, // White background
                    ),
                    value: selectedValue,
                    items: dropdownItems?.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  )
                : TextFormField(
                    controller: controller,
                    obscureText: obscureText,
                    maxLength: maxLength,
                    keyboardType: numbersOnly
                        ? TextInputType.number
                        : keyboardType ?? TextInputType.text,
                    inputFormatters: numbersOnly
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 10.0,
                      ),
                      hintText: hintText,
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: suffixIcon,
                      errorText: errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0)), // Light grey border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      filled: true, // Fill the background
                      fillColor: Colors.white, // White background
                    ),
                    validator: validator,
                  ),
          ),
        ],
      ),
    );
  }
}
