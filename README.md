# الجمرة التائهة (Flutter / Dart)

لعبة منصات ثنائية الأبعاد بمجسمات ثلاثية الأبعاد محوّلة إلى sprites.

## المحتوى الحالي
- العالم 1 «المغارة المنسية»: 10 مراحل (المرحلة 1 هي الأصلية بدون أي تغيير).
- العالم 2 «الغابة الملعونة»: 10 مراحل + زعيم «ملك العناكب».
- العوالم 3–11: قابلة للعب للتجربة بألوان وخلفيات خاصة (بدون زعيم خاص بعد).
- للتجربة كل العوالم والمراحل مفتوحة والمتجر برصيد 5000: غيّر `SaveData.unlockAll` إلى false في save.dart عند النشر.

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


## تحديث ديكورات العوالم

تم تحديث مولّد الديكور في `lib/game/art.dart` ليختار مجموعات مجسمات مختلفة حسب رقم العالم، مع توزيع ثابت مرتبط ببذرة المرحلة. تستخدم النسخة الحالية ملفات PNG المضمّنة في `assets/sprites/` وتعرضها كعناصر ثنائية الأبعاد ذات مظهر مجسّم (وليست نماذج 3D تفاعلية). تشمل الهويات البصرية: المغارة، الغابة، الفطر السام، الهياكل، الحمم، الجليد، المقبرة، المعبد، منجم الكريستال، قلعة الظلام، والعالم الأخير.


## External 3D environment models
- Added Quaternius Stylized Nature MegaKit (FREE Standard, 68/116 models), CC0 1.0.
- Selected glTF source files are preserved under `tools/external_models_source/glTF/`.
- Transparent 2D render sprites derived from the models are under `assets/world_models/` and are loaded by the game painter.
- Each of the 11 worlds selects a different mix of trees, rocks, mushrooms, plants, and flowers.
