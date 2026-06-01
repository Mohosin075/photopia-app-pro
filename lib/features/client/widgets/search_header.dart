import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/features/client/search_filter_screen.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/client/search_history_controller.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class SearchHeader extends StatefulWidget {
  final Function(Map<String, dynamic>)? onFilterApplied;
  final VoidCallback? onFocus;
  const SearchHeader({super.key, this.onFilterApplied, this.onFocus});

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _searchController.text.isNotEmpty;
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.onFocus != null) {
      widget.onFocus!();
    }
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (trimmed.isEmpty) {
        if (widget.onFilterApplied != null) {
          widget.onFilterApplied!({'searchTerm': ''});
        }
      } else if (trimmed.length >= 2 && widget.onFilterApplied != null) {
        widget.onFilterApplied!({'searchTerm': trimmed});
      }
    });
  }

  void _submitSearch(String value) {
    if (value.trim().isNotEmpty) {
      context.read<SearchHistoryController>().addSearchTerm(value);
    }
    if (widget.onFilterApplied != null) {
      widget.onFilterApplied!({'searchTerm': value});
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 12.w),
              ],
              Text(
                context.l10n.search,
                style: TextStyle(
                  fontSize: 20.sp.clamp(20, 22),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 15.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40.h.clamp(40, 42),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12).r,
                    border: Border.all(
                      color: _focusNode.hasFocus 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      width: _focusNode.hasFocus ? 1.5 : 1,
                    ),
                    boxShadow: _focusNode.hasFocus ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchHint,
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                        fontSize: 12.sp.clamp(12, 13),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: 12.w, right: 4.w),
                        child: Icon(
                          Icons.search,
                          color: _focusNode.hasFocus 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          size: 20.sp.clamp(20, 22),
                        ),
                      ),
                      suffixIcon: _showClearButton ? IconButton(
                        icon: Icon(
                          Icons.cancel,
                          size: 18.sp,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          if (widget.onFilterApplied != null) {
                            widget.onFilterApplied!({'searchTerm': ''});
                          }
                        },
                      ) : null,
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 35.w,
                        minHeight: 40.h,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _submitSearch,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                height: 40.h.clamp(40, 42),
                width: 40.h.clamp(40, 42),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12).r,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ),
                child: IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchFilterScreen(),
                      ),
                    );
                    if (result != null && widget.onFilterApplied != null) {
                      result['searchTerm'] = _searchController.text;
                      widget.onFilterApplied!(result);
                    }
                  },
                  icon: Image.asset(
                    'assets/images/filter_icon.png',
                    height: 20.h,
                    width: 20.h,
                    fit: BoxFit.contain,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}
