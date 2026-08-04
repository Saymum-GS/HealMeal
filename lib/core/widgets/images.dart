import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HealMealImage extends StatefulWidget {
  const HealMealImage({
    super.key,
    required this.imageUrl,
    this.productId,
    this.hasImage = false,
    this.label,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.icon = Icons.medication_rounded,
  });

  final String? imageUrl;
  final String? productId;
  final bool hasImage;
  final String? label;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData icon;

  @override
  State<HealMealImage> createState() => _HealMealImageState();
}

class _HealMealImageState extends State<HealMealImage> {
  static final Map<String, Uint8List> _base64Cache = {};
  static final Map<String, String> _firestoreBase64Cache = {};

  bool _isLoading = false;
  String? _dynamicBase64;

  @override
  void initState() {
    super.initState();
    _checkAndFetchImage();
  }

  @override
  void didUpdateWidget(covariant HealMealImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId ||
        oldWidget.imageUrl != widget.imageUrl) {
      _checkAndFetchImage();
    }
  }

  void _checkAndFetchImage() {
    _dynamicBase64 = null;
    if (widget.productId != null &&
        widget.hasImage &&
        (widget.imageUrl == null || widget.imageUrl!.isEmpty)) {
      if (_firestoreBase64Cache.containsKey(widget.productId!)) {
        _dynamicBase64 = _firestoreBase64Cache[widget.productId!];
      } else {
        _fetchFromFirestore();
      }
    }
  }

  Future<void> _fetchFromFirestore() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('product_images')
          .doc(widget.productId)
          .get();
      if (doc.exists && doc.data() != null) {
        final b64 = doc.data()!['base64'] as String?;
        if (b64 != null) {
          _firestoreBase64Cache[widget.productId!] = b64;
          if (mounted) setState(() => _dynamicBase64 = b64);
        }
      }
    } catch (e) {
      debugPrint('Error fetching product image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isBase64 {
    final String value = _dynamicBase64 ?? widget.imageUrl ?? '';
    return value.startsWith('data:image') ||
        (value.length > 100 &&
            !value.startsWith('http') &&
            !value.startsWith('assets/'));
  }

  bool get _isAsset {
    final String value = widget.imageUrl ?? '';
    return value.startsWith('assets/');
  }

  bool get _useFallback {
    if (_isLoading) return false; // Show loading instead of fallback
    final String value = _dynamicBase64 ?? widget.imageUrl ?? '';
    return value.isEmpty ||
        (!_isBase64 &&
            !_isAsset &&
            (value.contains('via.placeholder.com') ||
                value.contains('placeholder.com')));
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = widget.borderRadius ?? AppRadius.md;
    final String currentUrl = _dynamicBase64 ?? widget.imageUrl ?? '';

    Widget child;
    if (_isLoading) {
      child = _FallbackImage(
        label: widget.label,
        icon: widget.icon,
        isLoading: true,
      );
    } else if (_useFallback) {
      child = _FallbackImage(label: widget.label, icon: widget.icon);
    } else if (_isAsset) {
      child = Image.asset(
        currentUrl,
        fit: widget.fit,
        errorBuilder: (_, __, ___) =>
            _FallbackImage(label: widget.label, icon: widget.icon),
      );
    } else if (_isBase64) {
      try {
        String base64Data = currentUrl.contains(',')
            ? currentUrl.split(',').last
            : currentUrl;

        base64Data = base64Data.replaceAll(RegExp(r'\s+'), '');

        final Uint8List bytes = _base64Cache.putIfAbsent(
          base64Data,
          () => base64Decode(base64Data),
        );

        child = Image.memory(
          bytes,
          fit: widget.fit,
          errorBuilder: (_, __, ___) =>
              _FallbackImage(label: widget.label, icon: widget.icon),
        );
      } catch (e) {
        child = _FallbackImage(label: widget.label, icon: widget.icon);
      }
    } else {
      child = CachedNetworkImage(
        imageUrl: currentUrl,
        fit: widget.fit,
        placeholder: (_, __) => _FallbackImage(
          label: widget.label,
          icon: widget.icon,
          isLoading: true,
        ),
        errorWidget: (_, __, ___) =>
            _FallbackImage(label: widget.label, icon: widget.icon),
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({
    this.label,
    this.icon = Icons.local_hospital_rounded,
    this.isLoading = false,
  });

  final String? label;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final String text = (label == null || label!.trim().isEmpty)
        ? 'HealMeal'
        : label!.trim();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool ultraCompact = constraints.maxHeight <= 72;
        final bool compact =
            constraints.maxHeight <= 96 || constraints.maxWidth <= 120;
        final double padding = ultraCompact
            ? AppSpacing.sm
            : (compact ? 10 : AppSpacing.md);
        final double logoSize = ultraCompact ? 18 : (compact ? 20 : 24);
        final double iconSize = ultraCompact ? 20 : (compact ? 22 : 28);
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? <Color>[context.colorCard, AppColors.darkSurface]
                  : <Color>[AppColors.primaryLight, Color(0xFFF4FAF8)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                right: ultraCompact ? -6 : -8,
                top: ultraCompact ? -6 : -8,
                child: Container(
                  width: ultraCompact ? 34 : 48,
                  height: ultraCompact ? 34 : 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(.45),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: ultraCompact
                    ? Center(
                        child: isLoading
                            ? SizedBox(
                                width: 18.w,
                                height: 18.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                icon,
                                color: AppColors.primary,
                                size: iconSize,
                              ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  AppAssets.logo,
                                  height: logoSize,
                                  width: logoSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    icon,
                                    color: AppColors.primary,
                                    size: logoSize,
                                  ),
                                ),
                              ),
                              if (!compact) SizedBox(width: 8.w),
                              if (!compact)
                                Flexible(
                                  child: Text(
                                    'HealMeal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Spacer(),
                          if (isLoading)
                            Center(
                              child: SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  icon,
                                  color: AppColors.primary,
                                  size: iconSize,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    text,
                                    maxLines: compact ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: context.colorTextPrimary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
