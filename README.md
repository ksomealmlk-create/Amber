# الجمرة التائهة (Flutter / Dart)

لعبة منصات ثنائية الأبعاد بمجسمات ثلاثية الأبعاد (محوّلة إلى sprites عالية الجودة).

## بناء الـ APK على GitHub
1. ارفع كل محتويات هذا المجلد على مستودع GitHub جديد (فرع `main`).
2. افتح تبويب **Actions** — يبدأ البناء تلقائياً (أو اضغط Run workflow).
3. بعد ~5 دقائق: افتح التشغيلة ← **Artifacts** ← `Amber-apk` ← حمّل `Amber.apk`.
4. للنشر كـ Release: `git tag v1.0.0 && git push --tags`.

## تشغيل محلي
```
flutter create --platforms=android .
flutter run
```

المجسمات CC0 (انظر `credits.txt`).
