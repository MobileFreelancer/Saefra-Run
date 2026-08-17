import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/generated/assets.dart';

enum SearchFilterStyle {
  /// Filter icon inside the search field (dashboard original).
  inside,
  /// Red square filter button beside the field (search screen).
  outside,
}

/// Dashboard + Search search bar.
class SearchRouteBar extends StatelessWidget {
  const SearchRouteBar({
    super.key,
    this.controller,
    this.readOnly = false,
    this.autofocus = false,
    this.hintText = 'Search Route...',
    this.onChanged,
    this.onSearchTap,
    this.onFilterTap,
    this.onClear,
    this.showClearButton = false,
    this.showFilter = true,
    this.filterStyle = SearchFilterStyle.inside,
  });

  final TextEditingController? controller;
  final bool readOnly;
  final bool autofocus;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;
  final bool showClearButton;
  final bool showFilter;
  final SearchFilterStyle filterStyle;

  @override
  Widget build(BuildContext context) {
    void openSearch() {
      if (onSearchTap != null) {
        onSearchTap!();
        return;
      }
      final q = controller?.text.trim() ?? '';
      context.pushNamed(
        'search',
        queryParameters: q.isNotEmpty ? {'q': q} : {},
      );
    }

    void openFilter() {
      if (onFilterTap != null) {
        onFilterTap!();
        return;
      }
      context.pushNamed('generateRoute');
    }

    final field = _buildField(context, openSearch, openFilter);

    if (filterStyle == SearchFilterStyle.outside && showFilter) {
      return Row(
        children: [
          Expanded(child: field),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: openFilter,
            child: Container(
              width: 41.w,
              height: 41.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Image.asset(
                Assets.filter,
                width: 20,
                height: 20,
                color: AppColors.white,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.tune,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return field;
  }

  Widget _buildField(
    BuildContext context,
    VoidCallback openSearch,
    VoidCallback openFilter,
  ) {
    final showInsideFilter = showFilter && filterStyle == SearchFilterStyle.inside;
    final hasText = controller?.text.isNotEmpty ?? false;

    Widget? suffix;
    if (showClearButton && hasText) {
      suffix = GestureDetector(
        onTap: () {
          controller?.clear();
          onClear?.call();
          onChanged?.call('');
        },
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.close, color: AppColors.textMuted, size: 18),
        ),
      );
    } else if (!showInsideFilter) {
      suffix = GestureDetector(
        onTap: openFilter,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            Assets.filter,
            scale: 2.5,
            errorBuilder: (_, __, ___) => Image.asset(
              Assets.homeFilterIcon,
              width: 20,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.tune,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 41.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        autofocus: autofocus,
        showCursor: !readOnly,
        enableInteractiveSelection: !readOnly,
        style: const TextStyle(color: AppColors.white),
        onTap: readOnly ? openSearch : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
          filled: true,
          fillColor: const Color(0xFF222222),
          contentPadding: EdgeInsets.symmetric(vertical: 8.h),
          prefixIcon: Image.asset(
            Assets.Search,
            scale: 2.5,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.search,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          suffixIcon: suffix,
          suffixIconConstraints:
              suffix != null ? BoxConstraints(minWidth: 50.w) : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(width: 1.2, color: Color(0xFF131315)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(width: 1.2, color: Color(0xFF131315)),
          ),
        ),
      ),
    );
  }
}
