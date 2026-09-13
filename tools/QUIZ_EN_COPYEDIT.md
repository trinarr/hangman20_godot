# English quiz copyedit — 2026-09-13

База: предыдущий патч `hangman_quiz_explanations_transition_and_ru_20260913.patch`.

Прочитаны все 1100 английских вопросов и 4400 вариантов ответов.
Изменены 115 записей: 87 формулировок вопросов и 91 отдельных вариантов ответа.

Исправлены тяжёлый синтаксис, неточные переводы терминов, повторы, нехватка
контекста и несогласованные формулировки вариантов. Правки записаны и в
`data/quiz_catalog.json`, и в `data/quiz_questions_en.json`.

ID, темы, порядок вопросов, позиции правильных ответов и численные значения
сложности сохранены. Смысл правильных ответов сохранён, включая синонимическую
замену `Blocked shot` на `Block`. Русские записи не изменены.

Это языковая редактура вопросов и вариантов ответа, а не новый полный фактчек.
Отдельная база пояснений не входила в проверку: актуальный JSON с пояснениями
не был доступен в рабочей копии. Патч его не изменяет.

## Проверка

- `python tools/verify_quiz_catalog.py`: синхронизация каталога и runtime,
  число вопросов, ID, четыре различных варианта, отсутствие прямых подсказок.
- Godot 4.6.1: 1100 вопросов и 4400 вариантов проверены с текущими шрифтами
  и размерами блоков. Максимальная высота вопроса — 133 из 224 px,
  варианта ответа — 51 из 52 px. Измерение вариантов выполнено с отключённым
  только в проверке `clip_text`, чтобы обрезка не скрывала переполнение.
- Существующая проверка `res://tools/tests/quiz_editorial.tscn`:
  восстановление вопросов, перестановка ответов и сохранение купленных подсказок.
- Проверено применение incremental-патча и точное совпадение итоговых файлов.

## Примеры

### ID 11

Было: Before what count must a knocked-down boxer get up to avoid a knockout?

Стало: A knocked-down boxer must get up before the referee counts to which number to avoid a knockout?

### ID 53

Было: Why is a fuller added to a blade?

Стало: Why do some blades have a long groove called a fuller?

### ID 368

Вариант: The boundary of no return → The boundary beyond which light cannot escape

### ID 115

Было: Which year is traditionally given as the founding of Rome?

Стало: According to tradition, in what year was Rome founded?

### ID 427

Было: Where is play restarted when the ball crosses the goal line without a goal after a defender touched it last?

Стало: In football, a defender deflects the ball over their own goal line, outside the goal. Where does play restart?

### ID 530

Было: Who created the over-five-meter-tall David housed in the Accademia Gallery in Florence?

Стало: Who sculpted the marble David, over five meters tall, displayed in Florence's Accademia Gallery?

### ID 947

Вариант: Amplifies every surrounding sound → It amplifies every surrounding sound

Вариант: Only boosts the bass → It only boosts the bass

Вариант: Only seals the ear with a tight cushion → It only seals the ear with a tight cushion

Вариант: Generates a signal that weakens unwanted outside audio → It produces sound waves that counteract unwanted sounds

### ID 1004

Было: What is a coating batter?

Стало: What is batter in cooking?

Вариант: A liquid dough-like mixture → A liquid mixture, usually containing flour

### ID 1125

Вариант: Casts actors → Chooses actors for the roles

Вариант: Assembles recorded footage into a sequence → Selects and arranges footage to create the finished film

