import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'catalog.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

class SpinPage extends StatefulWidget {
  const SpinPage({super.key, required this.state});
  final AppState state;

  @override
  State<SpinPage> createState() => _SpinPageState();
}

class _SpinPageState extends State<SpinPage> {
  final _reel = ScrollController();
  bool _filtersOpen = false;

  AppState get state => widget.state;

  Future<void> _spin() async {
    final winner = await state.openCase();
    if (winner == null || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_reel.hasClients) {
      await _reel.animateTo(
        _reel.position.maxScrollExtent,
        duration: const Duration(milliseconds: 5600),
        curve: Curves.easeOutCubic,
      );
    }
    await state.finishSpin(winner);
    if (mounted && state.result != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => WinnerDialog(food: state.result!),
      );
      state.dismissResult();
    }
  }

  @override
  void dispose() {
    _reel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eligible = state.eligible;
    final province = state.catalog.provinceById(state.spinProvince);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
      children: [
        Row(
          children: [
            Bobbing(
              fast: state.spinning,
              child: const DoraAvatar(size: 72, wave: true, circle: false),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MỞ HÒM ĂN TRƯA',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: 0.8,
                      color: Dora.ink,
                    ),
                  ),
                  Text(
                    '${state.playerName} hãy tick địa chỉ rồi quay món nka.',
                    style: const TextStyle(color: Dora.muted, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 214,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Dora.blue, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0x99F6C51A), offset: Offset(0, 10), blurRadius: 0),
              BoxShadow(color: Color(0x3300A0E9), offset: Offset(0, 18), blurRadius: 28),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8F7FF), Dora.cream],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: ListView.separated(
                  controller: _reel,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.reel.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => FoodTile(food: state.reel[i], reel: true),
                ),
              ),
              const IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 7,
                    height: 178,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Dora.red, Dora.yellow, Dora.blue],
                        ),
                        boxShadow: [BoxShadow(color: Color(0xAAF6C51A), blurRadius: 12)],
                      ),
                    ),
                  ),
                ),
              ),
              const IgnorePointer(
                child: Row(
                  children: [
                    Expanded(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xE8E8F7FF), Color(0x00E8F7FF)])))),
                    Spacer(flex: 5),
                    Expanded(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x00FFFDF8), Color(0xE8FFFDF8)])))),
                  ],
                ),
              ),
              if (state.spinning)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF4D5A), Dora.red]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF9B000C), offset: Offset(0, 4), blurRadius: 0),
                          BoxShadow(color: Dora.yellow, offset: Offset(0, 7), blurRadius: 0),
                        ],
                      ),
                      child: Text('ĐANG QUAY', style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OpenChestButton(
          busy: state.spinning,
          onPressed: state.spinning || eligible.isEmpty ? null : _spin,
          label: state.spinning ? 'ĐANG QUAY...' : state.addressesPicked ? 'MỞ HÒM THEO ĐỊA CHỈ' : 'MỞ HÒM',
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFF5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Dora.blue, width: 4),
            boxShadow: const [BoxShadow(color: Color(0x55F6C51A), offset: Offset(0, 10), blurRadius: 0)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                InkWell(
                  onTap: state.spinning ? null : () => setState(() => _filtersOpen = !_filtersOpen),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Dora.sky, Dora.blue]),
                          boxShadow: [BoxShadow(color: Dora.deep, offset: Offset(0, 3), blurRadius: 0)],
                        ),
                        child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lọc địa chỉ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(
                              state.addressesPicked
                                  ? '${eligible.length} món · ${state.spinAddresses.length} địa chỉ'
                                  : '${state.addressOptions.length} địa chỉ · catalog',
                              style: const TextStyle(color: Dora.muted, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Icon(_filtersOpen ? Icons.expand_less : Icons.expand_more, color: Dora.ink),
                    ],
                  ),
                ),
                if (_filtersOpen) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: state.spinProvince,
                    decoration: const InputDecoration(labelText: 'Tỉnh / thành'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Mọi nơi')),
                      ...state.catalog.sortedProvinces.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: state.spinning ? null : (v) => state.setProvince(v ?? ''),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: state.spinDistrict,
                    decoration: const InputDecoration(labelText: 'Quận / huyện'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Tất cả quận')),
                      ...?province?.districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: state.spinning || province == null ? null : (v) => state.setDistrict(v ?? ''),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    enabled: !state.spinning,
                    decoration: const InputDecoration(labelText: 'Tìm địa chỉ', hintText: 'Lê Văn Hưu...'),
                    onChanged: state.setArea,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: state.budget,
                    decoration: const InputDecoration(labelText: 'Mức chi thường ngày'),
                    items: [for (var n = 0; n <= 100; n += 10) DropdownMenuItem(value: n, child: Text(priceLabel(n)))],
                    onChanged: state.spinning ? null : (v) => state.setBudget(v ?? 50),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<PoolMode>(
                    initialValue: state.addressesPicked ? PoolMode.eaten : state.poolMode,
                    decoration: const InputDecoration(labelText: 'Pool quay'),
                    items: [
                      DropdownMenuItem(value: PoolMode.catalog, child: Text('Catalog gốc (${state.catalog.foods.length})')),
                      DropdownMenuItem(value: PoolMode.eaten, child: Text('Quán đã ăn (${state.places.length})')),
                      const DropdownMenuItem(value: PoolMode.both, child: Text('Cả hai')),
                    ],
                    onChanged: state.spinning || state.addressesPicked ? null : (v) => state.setPool(v ?? PoolMode.catalog),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ăn chay', style: TextStyle(fontWeight: FontWeight.w800)),
                    value: state.veg,
                    onChanged: state.spinning ? null : state.setVeg,
                  ),
                  if (state.addressOptions.isNotEmpty) ...[
                    Row(
                      children: [
                        TextButton(onPressed: state.spinning ? null : state.selectAllAddresses, child: Text('Chọn tất cả (${state.addressOptions.length})')),
                        TextButton(onPressed: state.spinning || !state.addressesPicked ? null : state.clearAddresses, child: const Text('Bỏ chọn')),
                      ],
                    ),
                    ...state.addressOptions.map((option) {
                      final checked = state.selectedAddressKeys.contains(foldVi(option.address));
                      return CheckboxListTile(
                        value: checked,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.address, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${option.count} món'),
                        onChanged: state.spinning ? null : (_) => state.toggleAddress(option.address),
                      );
                    }),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Chưa có địa chỉ quán. Vào tab Đã ăn để thêm.', style: TextStyle(color: Dora.muted, fontWeight: FontWeight.w700)),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Trong hòm', style: GoogleFonts.beVietnamPro(color: Dora.deep, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.4)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Vật phẩm trong hòm', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7FF),
                border: Border.all(color: Dora.blue, width: 2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(eligible.length.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < rarityLabels.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(rarityColors[i].value), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(rarityLabels[i], style: const TextStyle(fontSize: 11, color: Dora.muted, fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: eligible.length.clamp(0, 30),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.92,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, i) => FoodTile(food: eligible[i]),
        ),
      ],
    );
  }
}

class WinnerDialog extends StatelessWidget {
  const WinnerDialog({super.key, required this.food});
  final Food food;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE8F7FF)]),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Dora.blue, width: 5),
          boxShadow: const [
            BoxShadow(color: Dora.yellow, offset: Offset(0, 12), blurRadius: 0),
            BoxShadow(color: Dora.red, offset: Offset(0, 20), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MÓN MAY MẮN', style: GoogleFonts.beVietnamPro(color: Dora.red, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(height: 140, width: 140, child: FoodArt(food: food)),
            ),
            const SizedBox(height: 10),
            Text(food.name, textAlign: TextAlign.center, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 26, color: Dora.ink)),
            Text(
              'Giá tham khảo · ${priceLabel(food.price)} / người',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Dora.muted, fontWeight: FontWeight.w700),
            ),
            if (food.address != null && food.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(food.address!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 14),
            OpenChestButton(label: 'Tiếp tục', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
