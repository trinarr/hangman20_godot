# Постепенное открытие подсказок

Для одиночной кампании в каждом языке:

- Уровни 1–3: комментарий в виселице, 50/50 в викторине.
- С первого этапа уровня 4: все три подсказки виселицы и обе подсказки викторины.
- Открытие определяется уже сохранённым `unlocked_level`; отдельного флага нет.
- Настройка: `progression.hints.all_unlocked_from_level` (номер уровня, начиная с 1).
- Закрытые кнопки используют штатный серый disabled-стейт и замок вместо пиктограммы;
  цена и остаток подсказок скрыты. Нажатия, расход запасов/монет и рекламный повтор
  для закрытых подсказок заблокированы. После открытия действуют обычные ограничения
  использования и оплаты.
- Классический режим и отдельная викторина вне кампании не меняются.

Замок: `flash_assets/hint_locked_doodle.png`, отдельный PNG с прозрачным фоном.
Создан встроенной генерацией изображений по референсу `hint_comment_unlock_doodle.png`.
Промпт: “Closed padlock, solid white silhouette, very thin dark indigo hand-drawn
contour, gently irregular rounded shapes, flat 2D, high legibility at 32px,
closed rounded U-shaped shackle, squat rounded square body, centered indigo keyhole.
No sparkles, text, button circle, gradients or metallic realism. Transparent background.”
Импорт ограничен 256 px для маленькой UI-иконки, исходный PNG сохранён отдельно.

Проверка: `tools/tests/hint_unlocks.gd`, 77 проверок. Запускать с отдельным
`XDG_DATA_HOME`, поскольку тест записывает и загружает тестовый сейв.
