import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF1C1C1C),

        prefixIcon: widget.prefixIcon is AppFieldPrefixIcon
            ? AppFieldPrefixIcon(
          icon: (widget.prefixIcon as AppFieldPrefixIcon).icon,
          isFocused: _focusNode.hasFocus,
        )
            : widget.prefixIcon,

        suffixIcon: widget.suffixIcon,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white54),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:  BorderSide(color: AppColors.primaryDark),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primaryDark)),
      ),
    );
  }
}


class AppFieldPrefixIcon extends StatelessWidget {
  const AppFieldPrefixIcon({
    super.key,
    required this.icon,
    this.isFocused = false,
  });

  final Widget icon;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 16),

        ColorFiltered(
          colorFilter: ColorFilter.mode(
            isFocused ? Colors.white : Colors.grey,
            BlendMode.srcIn,
          ),
          child: icon,
        ),

        const SizedBox(width: 12),

        Container(
          width: 1,
          height: 24,
          color: Colors.grey.shade700,
        ),

        const SizedBox(width: 12),
      ],
    );
  }
}