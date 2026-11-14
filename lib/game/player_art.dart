import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;
import 'engine.dart' show Player;
import 'player_sprites.dart';

class PlayerArt {
  static final Map<String, List<Image>> _img = {};
  static bool ready = false, _loading = false;

  static Future<void> ensure() async {
    if (ready || _loading) return;
    _loading = true;
    try {
      for (final a in const ['idle', 'run', 'attack1', 'attack2']) {
        final list = <Image>[];
        for (final f in kPlayerFrames['${a}_right']!) {
          final data = await rootBundle.load(playerFrame(f));
          final codec = await instantiateImageCodec(data.buffer.asUint8List());
          list.add((await codec.getNextFrame()).image);
        }
        _img[a] = list;
      }
      ready = true;
    } catch (_) {
      _loading = false;
    }
  }

  // يرجع true إذا رسم الشخصية الجديدة، وإلا يرجع الرسم القديم
  static bool draw(Canvas c, Player p, double px, double py, num t) {
    if (!ready) {
      ensure();
      return false;
    }
    final ti = t.toInt();
    String a;
    int i;
    if (p.atk > 0) {
      a = 'attack1';
      int k = 20 - p.atk;
      if (k < 0) k = 0;
      if (k > 19) k = 19;
      i = k * 8 ~/ 20;
    } else if (p.dash > 0) {
      a = 'attack2';
      i = 4;
    } else if (!p.g) {
      a = 'run';
      i = 3;
    } else if (p.vx.abs() > 0.3) {
      a = 'run';
      i = (ti ~/ 5) % 8;
    } else {
      a = 'idle';
      i = (ti ~/ 9) % 8;
    }
    final img = _img[a]![i];
    const s = 1.15;
    c.save();
    c.translate(px + 7, py + 22);
    c.scale(p.f.toDouble(), 1);
    c.drawOval(Rect.fromCenter(center: const Offset(0, 0.5), width: 14, height: 3), Paint()..color = const Color(0x55000000));
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(-46 * s, -58 * s, 96 * s, 80 * s),
      Paint()..filterQuality = FilterQuality.none,
    );
    c.restore();
    return true;
  }
}
