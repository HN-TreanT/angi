import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalog.dart';
import 'food_art.dart';
import 'models.dart';
import 'theme.dart';

export 'food_art.dart';

class FoodTile extends StatelessWidget {
  const FoodTile({
    super.key,
    required this.food,
    this.wide = false,
    this.compact = false,
    this.reel = false,
  });

  final Food food;
  final bool wide;
  final bool compact;
  final bool reel;

  @override
  Widget build(BuildContext context) {
    final color = Color(rarityColors[food.rarity.clamp(0, rarityColors.length - 1)].value);
    if (compact) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: const Color(0xFFE8F7FF),
          child: FoodArt(food: food),
        ),
      );
    }

    final card = Container(
      width: wide || reel ? 168 : null,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18), bottom: Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withValues(alpha: 0.28), Colors.white],
          stops: const [0, 0.55],
        ),
        boxShadow: const [BoxShadow(color: Color(0x140A4A7A), offset: Offset(0, 8), blurRadius: 0)],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18), bottom: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: color, width: reel ? 8 : 6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, reel ? 4 : 8, 8, 0),
              child: FoodArt(food: food),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: reel ? 14 : 13, color: Dora.ink),
                ),
                if (!reel)
                  Text(
                    food.address?.isNotEmpty == true ? food.address! : priceLabel(food.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Dora.muted, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (wide || reel) return SizedBox(width: 168, height: 188, child: card);
    return card;
  }
}

class DoraAvatar extends StatelessWidget {
  const DoraAvatar({super.key, this.size = 44, this.wave = false, this.circle = true});
  final double size;
  final bool wave;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      wave ? 'assets/images/doraemon_wave.png' : 'assets/images/doraemon.png',
      fit: BoxFit.contain,
    );
    if (!circle) {
      return SizedBox(width: size, height: size, child: img);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FF),
        shape: BoxShape.circle,
        border: Border.all(color: Dora.yellow, width: 3),
        boxShadow: const [BoxShadow(color: Dora.deep, offset: Offset(0, 4), blurRadius: 0)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Transform.scale(scale: 1.2, child: img),
    );
  }
}

class OpenChestButton extends StatelessWidget {
  const OpenChestButton({super.key, required this.label, required this.onPressed, this.busy = false});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: Dora.deep.withValues(alpha: onPressed == null ? 0.3 : 1), offset: const Offset(0, 6), blurRadius: 0),
            const BoxShadow(color: Dora.yellow, offset: Offset(0, 10), blurRadius: 0),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(busy ? Icons.sync : Icons.auto_awesome, size: 22),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: Dora.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 17),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

class SkyBackdrop extends StatelessWidget {
  const SkyBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9E9FF), Dora.cream, Color(0xFFFFE8EE)],
        ),
      ),
      child: child,
    );
  }
}
