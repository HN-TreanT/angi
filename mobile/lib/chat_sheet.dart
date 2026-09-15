import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

class ChatFab extends StatelessWidget {
  const ChatFab({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChatSheet(state: state),
      ),
      child: const Bobbing(child: DoraAvatar(size: 64)),
    );
  }
}

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key, required this.state});
  final AppState state;

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _input = TextEditingController();
  final _log = ScrollController();
  final _messages = <ChatTurn>[];
  var _pending = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _messages.add(ChatTurn(
      role: 'model',
      text: 'Chào ${widget.state.playerName}! Tớ là Doraemon đây. Muốn ăn gì cứ hỏi tớ nka.',
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _log.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _pending) return;
    setState(() {
      _messages.add(ChatTurn(role: 'user', text: text));
      _input.clear();
      _pending = true;
      _error = '';
    });
    try {
      final reply = await widget.state.api.chat(_messages.skip(1).toList(), widget.state.playerName);
      setState(() => _messages.add(ChatTurn(role: 'model', text: reply)));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _pending = false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_log.hasClients) {
        _log.jumpTo(_log.position.maxScrollExtent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE8F7FF)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.fromBorderSide(BorderSide(color: Dora.blue, width: 4)),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const DoraAvatar(size: 42),
              title: Text('Doraemon', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
              subtitle: const Text('Hỏi món ăn nha'),
            ),
            Expanded(
              child: ListView(
                controller: _log,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final m in _messages)
                    Align(
                      alignment: m.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: m.role == 'user' ? Dora.blue : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: m.role == 'user' ? null : Border.all(color: const Color(0xFFB7E4FF), width: 2),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: m.role == 'user' ? Colors.white : Dora.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (_pending) const Text('Đang nghĩ...', style: TextStyle(color: Dora.muted, fontStyle: FontStyle.italic)),
                  if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Dora.red, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_pending,
                      decoration: const InputDecoration(hintText: 'Hỏi Doraemon...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _pending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
