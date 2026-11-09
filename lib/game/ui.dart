import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'art.dart';
import 'engine.dart';
import 'level.dart';
import 'painter.dart';

const _gold = Color(0xFFFFD27A);
const _ice = Color(0xFFCFE4FF);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final GameEngine eng = GameEngine();
  Art? art;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(eng.tick);
    Art.load().then((a) {
      if (!mounted) return;
      setState(() => art = a);
      _ticker.start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (art == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF05070D),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 38, height: 38, child: CircularProgressIndicator(color: _gold, strokeWidth: 3)),
            SizedBox(height: 18),
            Text('جاري إشعال الجمرة...', style: TextStyle(color: _ice, fontSize: 16)),
          ]),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: kW / kH,
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: GamePainter(eng, art!))),
                  Positioned.fill(child: AnimatedBuilder(animation: eng, builder: (_, __) => _overlay())),
                ]),
              ),
            ),
          ),
          _controls(),
        ]),
      ),
    );
  }

  Widget _overlay() {
    if (eng.paused) {
      return _panel(children: [
        _title('متوقفة'),
        const SizedBox(height: 14),
        _btn('متابعة', eng.togglePause),
        const SizedBox(height: 10),
        _btn('إعادة من البداية', eng.start, secondary: true),
      ]);
    }
    switch (eng.phase) {
      case Phase.menu:
        return _panel(children: [
          _title('الجمرة التائهة'),
          const SizedBox(height: 10),
          const Text('نزلت المغارة وياك فانوس صغير.\nاجمع الجمرات وصل للبوابة المضيئة\nبآخر الطريق.',
              textAlign: TextAlign.center, style: TextStyle(color: _ice, fontSize: 15, height: 1.8)),
          const SizedBox(height: 8),
          const Text('حركة · قفز · اندفاع · ضربة', style: TextStyle(color: Color(0x99CFE4FF), fontSize: 13)),
          const SizedBox(height: 18),
          _btn('ابدأ', eng.start),
          const SizedBox(height: 14),
          const Text('مجسمات CC0: Avramania · Virtual Museums of Małopolska · Galway3D · Cleveland Museum of Art',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0x66CFE4FF), fontSize: 10)),
        ]);
      case Phase.dead:
        return GestureDetector(
          onTap: eng.start,
          child: Container(
            color: const Color(0xAA000000),
            alignment: Alignment.center,
            child: const Text('انطفأت الجمرة...', style: TextStyle(color: Color(0xFFFFB347), fontSize: 26, fontWeight: FontWeight.w800)),
          ),
        );
      case Phase.won:
        final s = eng.playFrames ~/ 60;
        final time = '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
        return _panel(children: [
          _title('وصلت للبوابة!'),
          const SizedBox(height: 14),
          Text('الجمرات: ${eng.collected} / ${eng.totalEmbers}', style: const TextStyle(color: _ice, fontSize: 17)),
          const SizedBox(height: 4),
          Text('الأعداء: ${eng.kills}      الوقت: $time', style: const TextStyle(color: _ice, fontSize: 17)),
          const SizedBox(height: 10),
          const Text('الفصل القادم قريباً: منطقة جديدة وزعيم', style: TextStyle(color: Color(0x99CFE4FF), fontSize: 13)),
          const SizedBox(height: 16),
          _btn('العب مرة ثانية', eng.start),
        ]);
      case Phase.playing:
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 40, left: 8),
            child: GestureDetector(
              onTap: eng.togglePause,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x55101828), border: Border.all(color: const Color(0x663A5A8C))),
                child: const Icon(Icons.pause_rounded, color: _ice, size: 20),
              ),
            ),
          ),
        );
    }
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(radius: 1.0, colors: [Color(0xB0050810), Color(0xE6020308)]),
      ),
      padding: const EdgeInsets.all(22),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: children)),
    );
  }

  Widget _title(String s) => Text(s,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFFFE3A8),
        fontSize: 34,
        fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Color(0xCCFF9A3C), blurRadius: 24), Shadow(color: Color(0x88FFB347), blurRadius: 6)],
      ));

  Widget _btn(String s, VoidCallback f, {bool secondary = false}) {
    return GestureDetector(
      onTap: f,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: secondary ? const [Color(0xFF1B2640), Color(0xFF16223A)] : const [Color(0xFFFFB347), Color(0xFFE0703A)]),
          border: Border.all(color: secondary ? const Color(0xFF3A5A8C) : const Color(0xFFFFE3A8), width: 1.5),
          boxShadow: secondary ? null : const [BoxShadow(color: Color(0x99FF9A3C), blurRadius: 22)],
        ),
        child: Text(s, style: TextStyle(color: secondary ? _ice : const Color(0xFF2A1208), fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _controls() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          _DPad(eng),
          Row(children: [
            _PadBtn(icon: Icons.keyboard_double_arrow_right_rounded, onChange: (v) => eng.dash = v, size: 60),
            const SizedBox(width: 10),
            _PadBtn(icon: Icons.local_fire_department_rounded, onChange: (v) => eng.atk = v, size: 66, accent: true),
            const SizedBox(width: 10),
            _PadBtn(icon: Icons.keyboard_arrow_up_rounded, onChange: (v) => eng.jump = v, size: 74),
          ]),
        ]),
      ),
    );
  }
}

BoxDecoration _glass(bool on, bool accent) => BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: on
            ? const [Color(0xFF3B5E96), Color(0xFF1E3358)]
            : (accent ? const [Color(0xFF3A2A22), Color(0xFF1C1412)] : const [Color(0xFF22345A), Color(0xFF101A30)]),
      ),
      border: Border.all(color: accent ? const Color(0xFFD9803A) : const Color(0xFF3A5A8C), width: 2),
      boxShadow: [BoxShadow(color: on ? const Color(0x883A8CFF) : const Color(0x33000000), blurRadius: on ? 16 : 6)],
    );

class _PadBtn extends StatefulWidget {
  final IconData icon;
  final void Function(bool) onChange;
  final double size;
  final bool accent;
  const _PadBtn({required this.icon, required this.onChange, required this.size, this.accent = false});
  @override
  State<_PadBtn> createState() => _PadBtnState();
}

class _PadBtnState extends State<_PadBtn> {
  bool on = false;
  void _set(bool v) {
    if (on == v) return;
    setState(() => on = v);
    widget.onChange(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: _glass(on, widget.accent),
        child: Icon(widget.icon, color: widget.accent ? const Color(0xFFFFC27A) : _ice, size: widget.size * .55),
      ),
    );
  }
}

class _DPad extends StatefulWidget {
  final GameEngine eng;
  const _DPad(this.eng);
  @override
  State<_DPad> createState() => _DPadState();
}

class _DPadState extends State<_DPad> {
  int dir = 0; // -1 يسار، 1 يمين
  static const double w = 150, h = 70;

  void _upd(Offset p) {
    int d = 0;
    if (p.dx < w * .5) {
      d = -1;
    } else {
      d = 1;
    }
    _apply(d);
  }

  void _apply(int d) {
    if (d == dir) return;
    setState(() => dir = d);
    widget.eng.left = d < 0;
    widget.eng.right = d > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _upd(e.localPosition),
      onPointerMove: (e) => _upd(e.localPosition),
      onPointerUp: (_) => _apply(0),
      onPointerCancel: (_) => _apply(0),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(colors: [Color(0xFF22345A), Color(0xFF101A30)]),
          border: Border.all(color: const Color(0xFF3A5A8C), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
        ),
        child: Row(children: [
          Expanded(child: Icon(Icons.chevron_left_rounded, size: 46, color: dir < 0 ? _gold : _ice)),
          Expanded(child: Icon(Icons.chevron_right_rounded, size: 46, color: dir > 0 ? _gold : _ice)),
        ]),
      ),
    );
  }
}
