// الشخصية الرئيسية: Adventurer (FREE Adventurer 2D Pixel Art)
// كل حركة 8 إطارات، حجم الإطار 96x80 بكسل. القدمان عند y≈58 تقريباً ومركز الجسم x≈46.
// للعبة جانبية استعمل الاتجاهين right و left فقط (up/down للعب من الأعلى).
// استعمل FilterQuality.none لإبقاء البكسل حاداً.
const Map<String, List<String>> kPlayerFrames = {
    'idle_right': ['idle_right_00.png', 'idle_right_01.png', 'idle_right_02.png', 'idle_right_03.png', 'idle_right_04.png', 'idle_right_05.png', 'idle_right_06.png', 'idle_right_07.png'],
    'idle_left': ['idle_left_00.png', 'idle_left_01.png', 'idle_left_02.png', 'idle_left_03.png', 'idle_left_04.png', 'idle_left_05.png', 'idle_left_06.png', 'idle_left_07.png'],
    'idle_up': ['idle_up_00.png', 'idle_up_01.png', 'idle_up_02.png', 'idle_up_03.png', 'idle_up_04.png', 'idle_up_05.png', 'idle_up_06.png', 'idle_up_07.png'],
    'idle_down': ['idle_down_00.png', 'idle_down_01.png', 'idle_down_02.png', 'idle_down_03.png', 'idle_down_04.png', 'idle_down_05.png', 'idle_down_06.png', 'idle_down_07.png'],
    'run_right': ['run_right_00.png', 'run_right_01.png', 'run_right_02.png', 'run_right_03.png', 'run_right_04.png', 'run_right_05.png', 'run_right_06.png', 'run_right_07.png'],
    'run_left': ['run_left_00.png', 'run_left_01.png', 'run_left_02.png', 'run_left_03.png', 'run_left_04.png', 'run_left_05.png', 'run_left_06.png', 'run_left_07.png'],
    'run_up': ['run_up_00.png', 'run_up_01.png', 'run_up_02.png', 'run_up_03.png', 'run_up_04.png', 'run_up_05.png', 'run_up_06.png', 'run_up_07.png'],
    'run_down': ['run_down_00.png', 'run_down_01.png', 'run_down_02.png', 'run_down_03.png', 'run_down_04.png', 'run_down_05.png', 'run_down_06.png', 'run_down_07.png'],
    'attack1_right': ['attack1_right_00.png', 'attack1_right_01.png', 'attack1_right_02.png', 'attack1_right_03.png', 'attack1_right_04.png', 'attack1_right_05.png', 'attack1_right_06.png', 'attack1_right_07.png'],
    'attack1_left': ['attack1_left_00.png', 'attack1_left_01.png', 'attack1_left_02.png', 'attack1_left_03.png', 'attack1_left_04.png', 'attack1_left_05.png', 'attack1_left_06.png', 'attack1_left_07.png'],
    'attack1_up': ['attack1_up_00.png', 'attack1_up_01.png', 'attack1_up_02.png', 'attack1_up_03.png', 'attack1_up_04.png', 'attack1_up_05.png', 'attack1_up_06.png', 'attack1_up_07.png'],
    'attack1_down': ['attack1_down_00.png', 'attack1_down_01.png', 'attack1_down_02.png', 'attack1_down_03.png', 'attack1_down_04.png', 'attack1_down_05.png', 'attack1_down_06.png', 'attack1_down_07.png'],
    'attack2_right': ['attack2_right_00.png', 'attack2_right_01.png', 'attack2_right_02.png', 'attack2_right_03.png', 'attack2_right_04.png', 'attack2_right_05.png', 'attack2_right_06.png', 'attack2_right_07.png'],
    'attack2_left': ['attack2_left_00.png', 'attack2_left_01.png', 'attack2_left_02.png', 'attack2_left_03.png', 'attack2_left_04.png', 'attack2_left_05.png', 'attack2_left_06.png', 'attack2_left_07.png'],
    'attack2_up': ['attack2_up_00.png', 'attack2_up_01.png', 'attack2_up_02.png', 'attack2_up_03.png', 'attack2_up_04.png', 'attack2_up_05.png', 'attack2_up_06.png', 'attack2_up_07.png'],
    'attack2_down': ['attack2_down_00.png', 'attack2_down_01.png', 'attack2_down_02.png', 'attack2_down_03.png', 'attack2_down_04.png', 'attack2_down_05.png', 'attack2_down_06.png', 'attack2_down_07.png'],
};

const int kPlayerFrameW = 96;
const int kPlayerFrameH = 80;
const double kPlayerFootY = 58;   // خط القدمين داخل الإطار
const Map<String, double> kPlayerStepTime = {
  'idle': 0.14, 'run': 0.08, 'attack1': 0.07, 'attack2': 0.07,
};

String playerFrame(String f) => 'assets/player/$f';
