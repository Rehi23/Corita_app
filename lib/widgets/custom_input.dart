import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final TextInputType type;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final VoidCallback? onToggleVisibility;
  final bool obscureText;
  final bool readOnly;

  const CustomInput({
    Key? key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.icon,
    this.type = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.formatters,
    this.onToggleVisibility,
    this.obscureText = false,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: type,
            obscureText: isPassword ? obscureText : false,
            readOnly: readOnly,
            validator: validator,
            inputFormatters: formatters,
            style: TextStyle(color: readOnly ? Colors.grey[700] : Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon) : null,
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}