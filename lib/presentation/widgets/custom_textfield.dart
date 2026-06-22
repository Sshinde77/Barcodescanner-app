import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixAssetPath,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.keyboardType,
    this.readOnly = false,
    this.validator,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixAssetPath;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool readOnly;
  final String? Function(String?)? validator;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixAssetPath != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  widget.prefixAssetPath!,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              )
            : widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon == null
            ? null
            : IconButton(
                icon: Icon(widget.suffixIcon),
                onPressed: widget.onSuffixTap,
              ),
      ),
    );
  }
}
