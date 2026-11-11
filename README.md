# الجمرة التائهة (Flutter / Dart)

لعبة منصات ثنائية الأبعاد بمجسمات ثلاثية الأبعاد محوّلة إلى sprites.

## المحتوى الحالي
- العالم 1 «المغارة المنسية»: 10 مراحل (المرحلة 1 هي الأصلية بدون أي تغيير).
- العالم 2 «الغابة الملعونة»: 10 مراحل + زعيم «ملك العناكب».
- العوالم 3–11 معرّفة في شاشة الاختيار وتظهر «قريباً».

## هيكل الكود
- `lib/game/level.dart` : LevelConfig + ثيمات العوالم + مصنع المراحل (LevelFactory) + قائمة العوالم.
- `lib/game/engine.dart`: المحرك (يقرأ LevelConfig): فيزياء، أعداء، منصات متحركة/منهارة، أشواك، صناديق، زعيم.
- `lib/game/painter.dart`, `art.dart`: الرسم والخلفيات حسب الثيم.
- `lib/game/save.dart`: حفظ التقدم (shared_preferences).
- `lib/game/ui.dart`: الرئيسية، العوالم، المراحل، المتجر، شاشات اللعب.

## إضافة عالم جديد
1. أضف WorldTheme جديداً في level.dart وفعّل `ready: true` في Worlds.all.
2. أضف أسماء المراحل في LevelFactory ووسّع `_generate` (أو أنشئ مراحل يدوية).
3. أضف زعيماً (BossSpec) وارسمه في painter.dart.

## بناء الـ APK على GitHub
ارفع المشروع على فرع main ← تبويب Actions ← Build APK ← Artifacts ← Amber-apk.

المجسمات CC0 (انظر `credits.txt`).
