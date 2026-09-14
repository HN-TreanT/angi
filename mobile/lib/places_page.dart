import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'catalog.dart';
import 'food_art.dart';
import 'models.dart';
import 'theme.dart';

class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key, required this.state});
  final AppState state;

  Future<void> _openForm(BuildContext context, {Place? editing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PlaceForm(state: state, editing: editing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('Nhật ký quán', style: GoogleFonts.beVietnamPro(color: Dora.deep, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.4)),
                  Text('Món đã ăn', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 22)),
                    Text('${state.places.length} quán đã lưu', style: const TextStyle(color: Dora.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.places.isEmpty
              ? const Center(child: Text('Chưa có quán nào. Thêm món đã ăn để lần sau quay đúng địa chỉ.', textAlign: TextAlign.center))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: state.places.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final place = state.places[i];
                    final food = state.catalog.placeToFood(place);
                    return Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: place.eatAgain ? Dora.blue : const Color(0xFFB7E4FF), width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 88,
                              height: 88,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ColoredBox(color: const Color(0xFFE8F7FF), child: FoodArt(food: food)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(place.dishName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  Text(place.restaurant, style: const TextStyle(color: Dora.muted, fontWeight: FontWeight.w700)),
                                  Text(
                                    '${place.address} · ${food.districtName ?? ''} · ${shortPlaceName(food.provinceName ?? '')}',
                                    style: const TextStyle(fontSize: 12, color: Dora.muted),
                                  ),
                                  Row(
                                    children: [
                                      for (var s = 1; s <= 5; s++)
                                        Icon(Icons.star_rounded, size: 16, color: s <= place.stars ? Dora.yellow : const Color(0xFFD7EAF6)),
                                    ],
                                  ),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      TextButton(
                                        onPressed: () => launchUrl(Uri.parse(state.catalog.mapsUrl(place)), mode: LaunchMode.externalApplication),
                                        child: const Text('Maps'),
                                      ),
                                      IconButton(onPressed: () => _openForm(context, editing: place), icon: const Icon(Icons.edit, size: 18)),
                                      IconButton(
                                        onPressed: () => state.deletePlace(place.id),
                                        icon: const Icon(Icons.delete_outline, color: Dora.red, size: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class PlaceForm extends StatefulWidget {
  const PlaceForm({super.key, required this.state, this.editing});
  final AppState state;
  final Place? editing;

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  late final _dish = TextEditingController(text: widget.editing?.dishName ?? '');
  late final _shop = TextEditingController(text: widget.editing?.restaurant ?? '');
  late final _addr = TextEditingController(text: widget.editing?.address ?? '');
  late final _notes = TextEditingController(text: widget.editing?.notes ?? '');
  late String _provinceId = widget.editing?.provinceId ?? '01';
  late String _districtId = widget.editing?.districtId ?? '001';
  late int _stars = widget.editing?.stars ?? 4;
  late bool _eatAgain = widget.editing?.eatAgain ?? true;
  late int _price = widget.editing?.price ?? 50;

  @override
  void dispose() {
    _dish.dispose();
    _shop.dispose();
    _addr.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_dish.text.trim().isEmpty || _shop.text.trim().isEmpty || _addr.text.trim().isEmpty) return;
    await widget.state.savePlace(
      {
        'dishName': _dish.text.trim(),
        'restaurant': _shop.text.trim(),
        'address': _addr.text.trim(),
        'provinceId': _provinceId,
        'districtId': _districtId,
        'stars': _stars,
        'eatAgain': _eatAgain,
        'price': _price,
        'notes': _notes.text.trim(),
      },
      id: widget.editing?.id,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final province = widget.state.catalog.provinceById(_provinceId);
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.editing == null ? 'Thêm món đã ăn' : 'Sửa món đã ăn', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 12),
            TextField(controller: _dish, decoration: const InputDecoration(labelText: 'Món ăn')),
            const SizedBox(height: 10),
            TextField(controller: _shop, decoration: const InputDecoration(labelText: 'Tên quán')),
            const SizedBox(height: 10),
            TextField(controller: _addr, decoration: const InputDecoration(labelText: 'Địa chỉ')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _provinceId,
              decoration: const InputDecoration(labelText: 'Tỉnh / thành'),
              items: widget.state.catalog.sortedProvinces
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) {
                final next = widget.state.catalog.provinceById(v ?? '');
                setState(() {
                  _provinceId = v ?? '01';
                  _districtId = next?.districts.first.id ?? '';
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _districtId,
              decoration: const InputDecoration(labelText: 'Quận / huyện'),
              items: [
                ...?province?.districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
              ],
              onChanged: (v) => setState(() => _districtId = v ?? ''),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _price,
              decoration: const InputDecoration(labelText: 'Giá khoảng'),
              items: [
                for (var n = 20; n <= 150; n += 10) DropdownMenuItem(value: n, child: Text(priceLabel(n))),
              ],
              onChanged: (v) => setState(() => _price = v ?? 50),
            ),
            const SizedBox(height: 8),
            const Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w800)),
            Row(
              children: [
                for (var s = 1; s <= 5; s++)
                  IconButton(
                    onPressed: () => setState(() => _stars = s),
                    icon: Icon(Icons.star_rounded, color: s <= _stars ? Dora.yellow : const Color(0xFFD7EAF6)),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đáng ăn lại', style: TextStyle(fontWeight: FontWeight.w800)),
              value: _eatAgain,
              onChanged: (v) => setState(() => _eatAgain = v),
            ),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Ghi chú'), maxLines: 2),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Lưu quán')),
          ],
        ),
      ),
    );
  }
}
