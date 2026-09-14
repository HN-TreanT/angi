import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'chat_sheet.dart';
import 'places_page.dart';
import 'spin_page.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BaongocangiApp());
}

class BaongocangiApp extends StatefulWidget {
  const BaongocangiApp({super.key});

  @override
  State<BaongocangiApp> createState() => _BaongocangiAppState();
}

class _BaongocangiAppState extends State<BaongocangiApp> {
  final state = AppState();
  var _ready = false;

  @override
  void initState() {
    super.initState();
    state.boot().whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hôm nay ăn gì?',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: !_ready
          ? const SkyBackdrop(child: Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator(color: Dora.blue))))
          : ListenableBuilder(
              listenable: state,
              builder: (_, _) => state.playerName.isEmpty ? NameGate(state: state) : HomeShell(state: state),
            ),
    );
  }
}

class NameGate extends StatefulWidget {
  const NameGate({super.key, required this.state});
  final AppState state;

  @override
  State<NameGate> createState() => _NameGateState();
}

class _NameGateState extends State<NameGate> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkyBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
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
                    const Bobbing(child: DoraAvatar(size: 96, wave: true, circle: false)),
                    const SizedBox(height: 6),
                    Text('CHÀO BẠN', style: GoogleFonts.beVietnamPro(color: Dora.red, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 13)),
                    Text('Bạn tên gì?', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 28, color: Dora.ink)),
                    const SizedBox(height: 4),
                    const Text('Nhập tên rồi mới tick địa chỉ và quay món nka.', textAlign: TextAlign.center, style: TextStyle(color: Dora.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _name,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Tên của bạn'),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _go(),
                    ),
                    const SizedBox(height: 16),
                    OpenChestButton(label: 'Vào quay', onPressed: _go),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _go() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await widget.state.saveName(name);
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});
  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return SkyBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 64,
          titleSpacing: 12,
          title: const Row(
            children: [
              DoraAvatar(size: 40),
              SizedBox(width: 8),
              Flexible(child: Text('HÔM NAY ĂN GÌ?')),
            ],
          ),
          actions: [
            IconButton(
              tooltip: state.soundOn ? 'Tắt âm thanh' : 'Bật âm thanh',
              onPressed: state.toggleSound,
              icon: Icon(state.soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: Dora.ink),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x5500A0E9), width: 2),
                    ),
                    child: Row(
                      children: [
                        _TabChip(label: 'Mở hòm', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                        _TabChip(label: 'Đã ăn  ${state.places.length}', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                      ],
                    ),
                  ),
                ),
                Container(height: 4, color: Dora.blue),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            SpinPage(state: state),
            PlacesPage(state: state),
          ],
        ),
        floatingActionButton: ChatFab(state: state),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Dora.sky, Dora.blue]) : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? const [BoxShadow(color: Dora.deep, offset: Offset(0, 3), blurRadius: 0)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: selected ? Colors.white : Dora.muted,
            ),
          ),
        ),
      ),
    );
  }
}
