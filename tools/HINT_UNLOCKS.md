# Постепенное открытие подсказок

Для одиночной кампании в каждом языке:

- Комментарий активного слова показан на поле и доступен бесплатно.
- Буквенные подсказки закрыты на уровнях 1–3. Подсказка 50/50 открывается на уровне 3 (настройка «progression.hints.quiz_fifty_fifty_unlocked_from_level»).
- С первого этапа уровня 4 доступны обе буквенные подсказки кроссворда и обе подсказки викторины.
- Открытие определяется уже сохранённым `unlocked_level`; отдельного флага нет.
- Настройка: `progression.hints.all_unlocked_from_level` (номер уровня, начиная с 1).
- Закрытые кнопки используют штатный серый disabled-стейт и замок вместо пиктограммы;
  цена и остаток подсказок скрыты. Нажатия, расход запасов/монет и рекламный повтор
  для закрытых подсказок заблокированы. После открытия действуют обычные ограничения
  использования и оплаты.

Замок: `flash_assets/hint_locked_doodle.png`, отдельный PNG с прозрачным фоном.
Создан по эскизу прежней кнопки комментария.
Промпт: “Closed padlock, solid white silhouette, very thin dark indigo hand-drawn
contour, gently irregular rounded shapes, flat 2D, high legibility at 32px,
closed rounded U-shaped shackle, squat rounded square body, centered indigo keyhole.
No sparkles, text, button circle, gradients or metallic realism. Transparent background.”
Импорт ограничен 256 px для маленькой UI-иконки, исходный PNG сохранён отдельно.

Проверка: `tools/tests/hint_unlocks.gd`. Сценарий записывает и загружает данные: запускать только с проверенной изоляцией профиля, описанной в [TESTS.md](TESTS.md). Прямой запуск на профиле игрока недопустим.
