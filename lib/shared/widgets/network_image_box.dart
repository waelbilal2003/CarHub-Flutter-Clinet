import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// صندوق صورة قادمة من الخادم مع الحالات الثلاث: تحميل، خطأ، غياب.
///
/// سبب وجوده: صور المنتجات تأتي من `product.images[].image_url`، وكثير
/// من المنتجات في قاعدة بيانات التطوير بلا صور أصلاً. بدل مربع أسود أو
/// استثناء، نعرض أيقونة قطعة غيار على خلفية التصميم (surface-container)
/// تماماً كما في مربعات الصور في 07_marketplace.html.
class NetworkImageBox extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  /// حجم الأيقونة البديلة عند غياب الصورة.
  final double placeholderIconSize;

  const NetworkImageBox({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppDimensions.radiusInput,
    this.placeholderIconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceContainer,
        child: url == null || url!.isEmpty
            ? _placeholder()
            : Image.network(
                url!,
                width: width,
                height: height,
                fit: fit,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.outline),
                      ),
                    ),
                  );
                },
                // رابط الصورة في بيئة التطوير يشير أحياناً إلى
                // 127.0.0.1 لا إلى نفق ngrok، فيفشل التحميل على الجهاز.
                // نعرض البديل بدل شاشة خطأ حمراء.
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Center(
        child: Icon(
          Icons.settings_suggest_outlined,
          size: placeholderIconSize,
          color: AppColors.outline,
        ),
      );
}
