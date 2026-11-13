import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'art.dart';
import 'engine.dart';
import 'level.dart';
import 'painter.dart';
import 'save.dart';

const _gold = Color(0xFFFFD27A);
const _ice = Color(0xFFCFE4FF);
const _bg = Color(0xFF05070D);

enum _Screen { home, worlds, levels, play }

Widget _title(String s, {double size = 34}) => Text(s,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: const Color(0xFFFFE3A8),
      fontSize: size,
      fontWeight: FontWeight.w900,
      shadows: const [Shadow(color: Color(0xCCFF9A3C), blurRadius: 24), Shadow(color: Color(0x88FFB347), blurRadius: 6)],
    ));

Widget _btn(String s, VoidCallback? f, {bool secondary = false, double fs = 18, double hp = 36}) {
  final off = f == null;
  return GestureDetector(
    onTap: f,
    child: Opacity(
      opacity: off ? .45 : 1,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hp, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: secondary ? const [Color(0xFF1B2640), Color(0xFF16223A)] : const [Color(0xFFFFB347), Color(0xFFE0703A)]),
          border: Border.all(color: secondary ? const Color(0xFF3A5A8C) : const Color(0xFFFFE3A8), width: 1.5),
          boxShadow: (secondary || off) ? null : const [BoxShadow(color: Color(0x99FF9A3C), blurRadius: 22)],
        ),
        child: Text(s, style: TextStyle(color: secondary ? _ice : const Color(0xFF2A1208), fontSize: fs, fontWeight: FontWeight.w800)),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Map<String, ui.Image>? sprites;
  SaveData? save;
  final GameEngine eng = GameEngine();
  Art? art;
  GamePainter? painter;
  LevelConfig? cfg;
  _Screen screen = _Screen.home;
  int selWorld = 1;
  bool loading = false, rewarded = false;
  int lastGain = 0;
  int playKey = 0;

  @override
  void initState() {
    super.initState();
    eng.addListener(_onEngine);
    Future(() async {
      final sp = await Sprites.load();
      final sv = await SaveData.load();
      if (!mounted) return;
      setState(() {
        sprites = sp;
        save = sv;
      });
    });
  }

  @override
  void dispose() {
    eng.removeListener(_onEngine);
    super.dispose();
  }

  void _onEngine() {
    if (eng.phase == Phase.won && !rewarded && cfg != null && save != null) {
      rewarded = true;
      lastGain = save!.complete(cfg!.world, cfg!.index, eng.collected, eng.playFrames ~/ 60);
      if (eng.deaths == 0) {
        save!.coins += 5; // مكافأة إنهاء المرحلة دون خسارة حياة
        lastGain += 5;
      }
      save!.save();
      if (mounted) setState(() {});
    }
  }

  Future<void> _play(int w, int l) async {
    if (loading || sprites == null) return;
    setState(() => loading = true);
    final c = LevelFactory.build(w, l);
    final newArt = await Art.build(sprites!, c);
    final old = art;
    eng.loadLevel(c, hearts: save!.maxHearts, dashCooldown: save!.dashCooldown, hammer: save!.hammerDamage);
    save!.last = c.id;
    if (!mounted) return;
    setState(() {
      art = newArt;
      painter = GamePainter(eng, newArt);
      cfg = c;
      rewarded = false;
      lastGain = 0;
      playKey++;
      screen = _Screen.play;
      loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  void _back() {
    setState(() {
      if (screen == _Screen.play) {
        eng.left = eng.right = eng.jump = eng.dash = eng.atk = false;
        screen = _Screen.levels;
      } else if (screen == _Screen.levels) {
        screen = _Screen.worlds;
      } else if (screen == _Screen.worlds) {
        screen = _Screen.home;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (sprites == null || save == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 38, height: 38, child: CircularProgressIndicator(color: _gold, strokeWidth: 3)),
            SizedBox(height: 18),
            Text('جاري إشعال الجمرة...', style: TextStyle(color: _ice, fontSize: 16)),
          ]),
        ),
      );
    }
    return PopScope(
      canPop: screen == _Screen.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          Positioned.fill(child: _body()),
          if (loading)
            Positioned.fill(
              child: Container(
                color: const Color(0xCC000000),
                alignment: Alignment.center,
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 38, height: 38, child: CircularProgressIndicator(color: _gold, strokeWidth: 3)),
                  SizedBox(height: 16),
                  Text('جاري تجهيز المرحلة...', style: TextStyle(color: _ice, fontSize: 16)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _body() {
    switch (screen) {
      case _Screen.home:
        return _home();
      case _Screen.worlds:
        return _worlds();
      case _Screen.levels:
        return _levels();
      case _Screen.play:
        return _PlayView(
          key: ValueKey(playKey),
          eng: eng,
          painter: painter!,
          cfg: cfg!,
          gain: lastGain,
          save: save!,
          onMenu: _back,
          onRetry: () => _play(cfg!.world, cfg!.index),
          onNext: _nextAction(),
        );
    }
  }

  VoidCallback? _nextAction() {
    final c = cfg;
    if (c == null) return null;
    if (c.index < SaveData.levelsPerWorld) return () => _play(c.world, c.index + 1);
    if (c.world < Worlds.all.length && Worlds.of(c.world + 1).ready) return () => _play(c.world + 1, 1);
    return null;
  }

  // ---------------- الرئيسية
  Widget _backdrop({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF03050B), Color(0xFF0A1630), Color(0xFF12335A)]),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
        Positioned.fill(child: SafeArea(child: child)),
      ]),
    );
  }

  Widget _home() {
    final sv = save!;
    final hasProgress = sv.done.isNotEmpty;
    return _backdrop(
      child: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _title('الجمرة التائهة', size: 40),
            const SizedBox(height: 10),
            const Text('اجمع الجمرات، حطّم الأعداء، واعبر العوالم', style: TextStyle(color: _ice, fontSize: 15)),
            const SizedBox(height: 28),
            _btn('ابدأ اللعب', () => setState(() => screen = _Screen.worlds), fs: 22, hp: 54),
            const SizedBox(height: 14),
            if (hasProgress)
              _btn('متابعة', () {
                final m = RegExp(r'w(\d+)l(\d+)').firstMatch(sv.last);
                final w = m == null ? 1 : int.parse(m.group(1)!);
                final l = m == null ? 1 : int.parse(m.group(2)!);
                if (sv.levelUnlocked(w, l) && Worlds.of(w).ready) {
                  _play(w, l);
                } else {
                  _play(1, 1);
                }
              }, secondary: true, hp: 60),
            const SizedBox(height: 14),
            _btn('المتجر', () => _shop(), secondary: true, hp: 60),
            const SizedBox(height: 22),
            _coinChip(),
            const SizedBox(height: 18),
            const SizedBox(
              width: 300,
              child: Text('مجسمات CC0: Avramania · Virtual Museums of Małopolska · Galway3D · Cleveland Museum of Art · شخصية: Shadow Character 1 - The Enforcer',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0x66CFE4FF), fontSize: 10)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _coinChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: const Color(0x55101828), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x66FFD27A))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: _gold, boxShadow: [BoxShadow(color: Color(0xAAFF9A3C), blurRadius: 8)])),
          const SizedBox(width: 8),
          Text('${save!.coins}', style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _header(String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Row(children: [
          GestureDetector(
            onTap: _back,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0x55101828), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x663A5A8C))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_forward_rounded, color: _ice, size: 20),
                SizedBox(width: 6),
                Text('رجوع', style: TextStyle(color: _ice, fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          Expanded(child: Center(child: _title(title, size: 24))),
          trailing ?? const SizedBox(width: 80),
        ]),
      );

  // ---------------- العوالم
  Widget _worlds() {
    final sv = save!;
    return _backdrop(
      child: Column(children: [
        _header('اختر العالم', trailing: _coinChip()),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            itemCount: Worlds.all.length + 1,
            itemBuilder: (_, i) {
              if (i == Worlds.all.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(child: _btn('المتجر', _shop, secondary: true, fs: 16, hp: 40)),
                );
              }
              final w = Worlds.all[i];
              final unlocked = sv.worldUnlocked(w.id);
              final done = sv.worldDone(w.id);
              final pct = (done * 100 / SaveData.levelsPerWorld).round();
              final canEnter = w.ready && unlocked;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x99101828),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: canEnter ? const Color(0x88FFD27A) : const Color(0x443A5A8C), width: 1.4),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(width: 92, height: 116, child: Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: _ThumbPainter(w))),
                      if (!canEnter)
                        Positioned.fill(child: Container(color: const Color(0x99000000), child: Icon(w.ready ? Icons.lock_rounded : Icons.hourglass_top_rounded, color: _ice, size: 30))),
                    ])),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('العالم ${w.id}', style: const TextStyle(color: Color(0x99CFE4FF), fontSize: 12)),
                      Text(w.name, style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 19, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(w.desc, style: const TextStyle(color: _ice, fontSize: 12, height: 1.4)),
                      const SizedBox(height: 6),
                      if (w.ready) ...[
                        Text('المراحل: ${SaveData.levelsPerWorld}   ·   الإنجاز: $pct%', style: const TextStyle(color: _ice, fontSize: 12)),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: done / SaveData.levelsPerWorld, minHeight: 6, backgroundColor: const Color(0x33FFFFFF), color: _gold),
                        ),
                        if (w.id > 2) const Padding(padding: EdgeInsets.only(top: 4), child: Text('نسخة تجريبية: الزعيم الخاص قريباً', style: TextStyle(color: Color(0xFFFFB347), fontSize: 11))),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _btn(unlocked ? 'دخول العالم' : 'مقفل', unlocked ? () => setState(() { selWorld = w.id; screen = _Screen.levels; }) : null, fs: 14, hp: 22),
                        ),
                      ] else ...[
                        Text('الزعيم: ${w.bossName}', style: const TextStyle(color: Color(0x99CFE4FF), fontSize: 12)),
                        const SizedBox(height: 6),
                        const Text('قريباً في التحديث القادم', style: TextStyle(color: Color(0xFFFFB347), fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ---------------- المراحل
  Widget _levels() {
    final sv = save!;
    final w = Worlds.of(selWorld);
    return _backdrop(
      child: Column(children: [
        _header(w.name, trailing: _coinChip()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('أكملت ${sv.worldDone(w.id)} من ${SaveData.levelsPerWorld} مراحل', style: const TextStyle(color: _ice, fontSize: 13)),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(14),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.3,
            children: [
              for (int l = 1; l <= SaveData.levelsPerWorld; l++) _levelTile(sv, w, l),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _levelTile(SaveData sv, WorldInfo w, int l) {
    final open = sv.levelUnlocked(w.id, l);
    final done = sv.levelDone(w.id, l);
    final boss = w.id == 2 && l == 10;
    final best = sv.bestEmbers[SaveData.id(w.id, l)];
    final total = LevelFactory.build(w.id, l).totalEmbers;
    return GestureDetector(
      onTap: open ? () => _play(w.id, l) : null,
      child: Opacity(
        opacity: open ? 1 : .5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: done ? const [Color(0xFF2A3A24), Color(0xFF16221A)] : const [Color(0xFF1B2A48), Color(0xFF101A30)]),
            border: Border.all(color: boss ? const Color(0xFFFF6A50) : (open ? const Color(0xAAFFD27A) : const Color(0x443A5A8C)), width: 1.6),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x55000000), border: Border.all(color: const Color(0x66FFD27A))),
              child: open
                  ? (done ? const Icon(Icons.check_rounded, color: Color(0xFF8CFFB0), size: 22) : Text('$l', style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 18, fontWeight: FontWeight.w900)))
                  : const Icon(Icons.lock_rounded, color: _ice, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(LevelFactory.nameOf(w.id, l), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(boss ? 'مواجهة الزعيم' : (best != null ? 'الجمرات: $best / $total' : 'مرحلة $l'),
                    style: TextStyle(color: boss ? const Color(0xFFFF8A70) : const Color(0x99CFE4FF), fontSize: 11)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ---------------- المتجر
  void _shop() {
    final sv = save!;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        Widget item(String name, String desc, int lvl, int maxLvl, int cost, bool maxed, VoidCallback buy) {
          final can = !maxed && sv.coins >= cost;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0x66101828), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x443A5A8C))),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(desc, style: const TextStyle(color: _ice, fontSize: 12)),
                  Text('المستوى $lvl / $maxLvl', style: const TextStyle(color: Color(0x99CFE4FF), fontSize: 11)),
                ]),
              ),
              _btn(maxed ? 'مكتمل' : 'شراء $cost', can
                  ? () {
                      sv.coins -= cost;
                      buy();
                      sv.save();
                      setD(() {});
                      setState(() {});
                    }
                  : null, fs: 13, hp: 16),
            ]),
          );
        }

        return Dialog(
          backgroundColor: const Color(0xFF0A1220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x88FFD27A))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _title('المتجر', size: 26),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('رصيدك: ', style: TextStyle(color: _ice, fontSize: 15)),
                Text('${sv.coins}', style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 18, fontWeight: FontWeight.w900)),
                const Text(' جمرة', style: TextStyle(color: _ice, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              item('قلب إضافي', 'يزيد أقصى صحة (حالياً ${sv.maxHearts})', sv.heartUp, 3, sv.costHeart(), sv.heartMax, () => sv.heartUp++),
              item('اندفاع أسرع', 'يقلل زمن انتظار الاندفاع', sv.dashUp, 3, sv.costDash(), sv.dashMax, () => sv.dashUp++),
              item('مطرقة أقوى', 'يزيد ضرر المطرقة (حالياً ${sv.hammerDamage})', sv.hammerUp, 2, sv.costHammer(), sv.hammerMax, () => sv.hammerUp++),
              const SizedBox(height: 6),
              _btn('إغلاق', () => Navigator.of(ctx).pop(), secondary: true, fs: 15, hp: 30),
            ]),
          ),
        );
      }),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = mkr(9);
    for (int i = 0; i < 90; i++) {
      c.drawCircle(Offset(r() * s.width, r() * s.height * .8), .6 + r() * 1.1, Paint()..color = Color.fromRGBO(210, 230, 255, .2 + r() * .6));
    }
    c.drawCircle(Offset(s.width * .8, s.height * .14), 26, Paint()..shader = ui.Gradient.radial(Offset(s.width * .8, s.height * .14), 60, const [Color(0xFFF6FAFF), Color(0x00AAC8FF)], const [.35, 1]));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ThumbPainter extends CustomPainter {
  final WorldInfo w;
  _ThumbPainter(this.w);
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), w.thumb));
    final r = mkr(w.id * 17 + 3);
    for (int i = 0; i < 18; i++) {
      c.drawCircle(Offset(r() * s.width, r() * s.height * .5), .5 + r(), Paint()..color = Color.fromRGBO(220, 235, 255, .4 + r() * .5));
    }
    c.drawCircle(Offset(s.width * .72, s.height * .2), 9, Paint()..color = const Color(0xCCF0F6FF));
    final m = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += 3) {
      m.lineTo(x, s.height * .62 - (r() * 3) - 12 * (0.5 + 0.5 * (x / s.width > .5 ? (1 - x / s.width) : x / s.width) * 2));
    }
    m.lineTo(s.width, s.height);
    m.close();
    c.drawPath(m, Paint()..color = const Color(0xCC050810));
    c.drawRect(Rect.fromLTWH(0, s.height * .84, s.width, s.height * .16), Paint()..color = w.ground);
    c.drawRect(Rect.fromLTWH(0, s.height * .84, s.width, 2), Paint()..color = const Color(0x6678B4FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ---------------- شاشة اللعب
class _PlayView extends StatefulWidget {
  final GameEngine eng;
  final GamePainter painter;
  final LevelConfig cfg;
  final SaveData save;
  final int gain;
  final VoidCallback onMenu, onRetry;
  final VoidCallback? onNext;
  const _PlayView({super.key, required this.eng, required this.painter, required this.cfg, required this.save, required this.gain, required this.onMenu, required this.onRetry, required this.onNext});
  @override
  State<_PlayView> createState() => _PlayViewState();
}

class _PlayViewState extends State<_PlayView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  bool banner = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(widget.eng.tick)..start();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => banner = false);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  GameEngine get eng => widget.eng;

  @override
  Widget build(BuildContext context) {
    final land = MediaQuery.of(context).orientation == Orientation.landscape;
    final game = Stack(children: [
      Positioned.fill(child: CustomPaint(painter: widget.painter)),
      Positioned.fill(child: AnimatedBuilder(animation: eng, builder: (_, __) => _overlay())),
      Positioned(
        top: 70,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: banner ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: Column(children: [
              Text('العالم ${widget.cfg.world} · المرحلة ${widget.cfg.index}', style: const TextStyle(color: Color(0xCCCFE4FF), fontSize: 13)),
              _title(widget.cfg.name, size: 24),
            ]),
          ),
        ),
      ),
    ]);
    if (land) {
      return Stack(children: [
        Positioned.fill(child: game),
        Positioned.fill(
          child: SafeArea(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Opacity(
                  opacity: .85,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _DPad(eng),
                    _actions(),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]);
    }
    return SafeArea(
      child: Column(children: [
        Expanded(
          child: Center(
            child: AspectRatio(aspectRatio: kW / kH, child: game),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
              _DPad(eng),
              _actions(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _actions() {
    return Row(children: [
      _PadBtn(icon: Icons.keyboard_double_arrow_right_rounded, onChange: (v) => eng.dash = v, size: 62),
      const SizedBox(width: 2),
      _PadBtn(icon: Icons.local_fire_department_rounded, onChange: (v) => eng.atk = v, size: 70, accent: true),
      const SizedBox(width: 2),
      _PadBtn(icon: Icons.keyboard_arrow_up_rounded, onChange: (v) => eng.jump = v, size: 82),
    ]);
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      decoration: const BoxDecoration(gradient: RadialGradient(radius: 1.0, colors: [Color(0xB0050810), Color(0xE6020308)])),
      padding: const EdgeInsets.all(22),
      child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisSize: MainAxisSize.min, children: children))),
    );
  }

  Widget _overlay() {
    if (eng.paused) {
      return _panel(children: [
        _title('متوقفة'),
        const SizedBox(height: 14),
        _btn('متابعة', eng.togglePause),
        const SizedBox(height: 10),
        _btn('إعادة المرحلة', widget.onRetry, secondary: true),
        const SizedBox(height: 10),
        _btn('قائمة المراحل', widget.onMenu, secondary: true),
      ]);
    }
    switch (eng.phase) {
      case Phase.dead:
        return GestureDetector(
          onTap: eng.restart,
          child: Container(
            color: const Color(0xAA000000),
            alignment: Alignment.center,
            child: const Text('انطفأت الجمرة...', style: TextStyle(color: Color(0xFFFFB347), fontSize: 26, fontWeight: FontWeight.w800)),
          ),
        );
      case Phase.won:
        final s = eng.playFrames ~/ 60;
        final time = '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
        final boss = widget.cfg.boss != null;
        return _panel(children: [
          _title(boss ? 'سقط ${widget.cfg.boss!.name}!' : 'وصلت للبوابة!', size: 30),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++) Icon(i < eng.stars ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFFFD27A), size: 34),
          ]),
          if (eng.deaths == 0) const Padding(padding: EdgeInsets.only(top: 4), child: Text('مكافأة: بدون خسارة حياة +5', style: TextStyle(color: Color(0xFFFFE3A8), fontSize: 13))),
          const SizedBox(height: 10),
          Text('الجمرات: ${eng.collected} / ${eng.totalEmbers}', style: const TextStyle(color: _ice, fontSize: 17)),
          const SizedBox(height: 4),
          Text('الأعداء: ${eng.kills}      الوقت: $time', style: const TextStyle(color: _ice, fontSize: 17)),
          const SizedBox(height: 4),
          Text(widget.gain > 0 ? 'ربحت ${widget.gain} جمرة للمتجر' : 'لا جمرات جديدة للمتجر', style: const TextStyle(color: Color(0xFFFFE3A8), fontSize: 15)),
          if (boss) const SizedBox(height: 4),
          if (boss) const Text('تم فتح العالم التالي عند توفره', style: TextStyle(color: Color(0x99CFE4FF), fontSize: 12)),
          const SizedBox(height: 16),
          if (widget.onNext != null) _btn('المرحلة التالية', widget.onNext),
          if (widget.onNext != null) const SizedBox(height: 10),
          _btn('إعادة المرحلة', widget.onRetry, secondary: true),
          const SizedBox(height: 10),
          _btn('قائمة المراحل', widget.onMenu, secondary: true),
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
    widget.onChange(v);
    setState(() => on = v);
  }

  @override
  Widget build(BuildContext context) {
    // منطقة اللمس أكبر من الشكل المرئي لسهولة الضغط
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Transform.scale(
          scale: on ? .93 : 1,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: _glass(on, widget.accent),
            child: Icon(widget.icon, color: widget.accent ? const Color(0xFFFFC27A) : _ice, size: widget.size * .55),
          ),
        ),
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
  static const double w = 176, h = 78, pad = 14;

  void _upd(Offset p) {
    final mid = (w + 2 * pad) / 2;
    int d = 0;
    if (p.dx < mid - 4) {
      d = -1;
    } else if (p.dx > mid + 4) {
      d = 1;
    } else {
      d = dir == 0 ? 1 : dir;
    }
    _apply(d);
  }

  void _apply(int d) {
    if (d == dir) return;
    widget.eng.left = d < 0;
    widget.eng.right = d > 0;
    setState(() => dir = d);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _upd(e.localPosition),
      onPointerMove: (e) => _upd(e.localPosition),
      onPointerUp: (_) => _apply(0),
      onPointerCancel: (_) => _apply(0),
      child: Padding(
        padding: const EdgeInsets.all(pad),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(42),
            gradient: const LinearGradient(colors: [Color(0xFF22345A), Color(0xFF101A30)]),
            border: Border.all(color: const Color(0xFF3A5A8C), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
          ),
          child: Row(children: [
            Expanded(child: Icon(Icons.chevron_left_rounded, size: 52, color: dir < 0 ? _gold : _ice)),
            Expanded(child: Icon(Icons.chevron_right_rounded, size: 52, color: dir > 0 ? _gold : _ice)),
          ]),
        ),
      ),
    );
  }
}
