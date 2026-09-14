import 'package:flutter/material.dart';

import 'models.dart';
import 'photo.dart';
import 'theme.dart';

class AtlasCell {
  const AtlasCell({required this.asset, required this.cols, required this.rows, required this.index});
  final String asset;
  final int cols;
  final int rows;
  final int index;
}

AtlasCell? atlasFor(int image) {
  if (image < 0) return null;
  if (image >= 120) {
    final i = image - 120;
    return AtlasCell(asset: 'assets/images/food-common-${i ~/ 12}.webp', cols: 4, rows: 3, index: i % 12);
  }
  if (image >= 72) {
    final i = image - 72;
    return AtlasCell(asset: 'assets/images/food-lunch-${i ~/ 12}.webp', cols: 4, rows: 3, index: i % 12);
  }
  if (image >= 36) {
    final i = image - 36;
    return AtlasCell(asset: 'assets/images/food-expanded-${i ~/ 12}.webp', cols: 4, rows: 3, index: i % 12);
  }
  return AtlasCell(asset: 'assets/images/food-hd-${image ~/ 4}.webp', cols: 2, rows: 2, index: image % 4);
}

class FoodArt extends StatelessWidget {
  const FoodArt({super.key, required this.food, this.fit = BoxFit.cover});
  final Food food;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDishPhoto(food.photo);
    if (bytes != null) {
      return Image.memory(bytes, fit: fit);
    }
    final cell = atlasFor(food.image);
    if (cell == null) {
      return const ColoredBox(
        color: Color(0xFFE8F7FF),
        child: Center(child: Icon(Icons.restaurant, color: Dora.ink, size: 36)),
      );
    }
    final col = cell.index % cell.cols;
    final row = cell.index ~/ cell.cols;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0 ? constraints.maxWidth : 150.0;
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0 ? constraints.maxHeight : w;
        return ClipRect(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -col * w,
                  top: -row * h,
                  width: cell.cols * w,
                  height: cell.rows * h,
                  child: Image.asset(
                    cell.asset,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Bobbing extends StatefulWidget {
  const Bobbing({super.key, required this.child, this.distance = 8, this.fast = false});
  final Widget child;
  final double distance;
  final bool fast;

  @override
  State<Bobbing> createState() => _BobbingState();
}

class _BobbingState extends State<Bobbing> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.fast ? 280 : 2800),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(covariant Bobbing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fast != widget.fast) {
      controller.duration = Duration(milliseconds: widget.fast ? 280 : 2800);
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -widget.distance * Curves.easeInOut.transform(controller.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}
