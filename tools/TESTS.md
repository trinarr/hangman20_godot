# Запуск тестов на Windows и Linux

Игра предназначена для Android. Эти команды проверяют её логику на настольном Godot и не заменяют проверку сборки на телефоне.

После импорта ресурсов выбранной версией Godot, из корня проекта:

```powershell
python tools/run_content_tests.py --godot 'C:/path/to/Godot.exe'
python tools/run_reward_tests.py --godot 'C:/path/to/Godot.exe' --suite rewards
python tools/run_reward_tests.py --godot 'C:/path/to/Godot.exe' --suite save_recovery
python tools/run_reward_tests.py --godot 'C:/path/to/Godot.exe' --suite resume_flow
python tools/run_reward_tests.py --godot 'C:/path/to/Godot.exe' --suite runtime_optimizations
python tools/verify_game_design_config.py
python tools/verify_optimization.py
python -m unittest discover -s tools/tests -p 'test_*.py'
```

На Linux команды те же, с Linux-бинарником в `--godot`. Отдельный контентный сценарий выбирается через `--suite <name>`; список смотри в `--help`. Перед запуском ресурсы должны быть импортированы, например `Godot.exe --headless --editor --import --path .`.

`godot_test_runner.py` создаёт временный профиль, задаёт APPDATA/LOCALAPPDATA только дочернему процессу на Windows либо XDG-каталоги на Linux. До запуска игровых autoload отдельный минимальный проект с теми же настройками `[application]` проверяет реальный `OS.get_user_data_dir()`. Путь вне временного профиля, ошибка движка или отсутствие отчёта прерывают запуск. Локальный `override.cfg` также блокирует запуск, поскольку он может изменить проверенные настройки. Исходный проект и настройки Android не меняются. Механизм Windows соответствует [реализации путей Godot](https://github.com/godotengine/godot/blob/master/platform/windows/os_windows.cpp) и дополнительно проверяется самим используемым бинарником.

Все фазы `save_recovery` используют один профиль для проверки перезапусков; разные контентные сценарии получают разные профили. Поддерживающая флаг сеть Supabase отключена. stdout и файл журнала Godot проверяются вместе, включая GUI-бинарники Windows без доступного stdout. Exit code 0 без ожидаемого итогового отчёта не считается успехом. Предупреждения ObjectDB остаются видимыми.

Чтение/запись текстовых файлов инструментами использует явную UTF-8. Установка `PYTHONUTF8=1` больше не требуется для корректного чтения каталогов.

Для регрессии изоляции с настоящим движком:

```powershell
$env:HANGMAN_TEST_GODOT = 'C:/path/to/Godot.exe'
python -m unittest discover -s tools/tests -p test_project_tools.py
```

Проверяется отказ при небезопасном пути, сохранение между двумя процессами, чистота следующего профиля и неизменность окружения родителя. Без `HANGMAN_TEST_GODOT` тест реального движка пропускается; остальные регрессии работают без Godot.

## Профиль игрока

Профиль игрока: `profile_bootstrap` проверяет первый запуск, сетевой запрет до обучения, серверный суффикс и защиту ручного имени; `profile_ui` — скрытие/появление аватара, сохранение из попапа и отказ записи; `save_recovery` — миграцию и восстановление; `leaderboard` — отправку и повторы. Каталоги предложенных ников проверяет `python -m unittest discover -s tools/tests -p test_profile_nicknames.py`. Локальные SQL-тесты `tools/tests/player_profiles_sql.cjs` и `leaderboard_local_fillers_sql.cjs` запускаются через Node.js с доступным `@electric-sql/pglite` (при необходимости задайте `NODE_PATH`). Они создают временную БД в памяти и не подключаются к Supabase.

Обновление серверных фейковых ников: `python tools/build_leaderboard_filler_refresh.py --check` проверяет каталог v3 и миграцию 012; `tools/tests/leaderboard_filler_refresh_sql.cjs` через Node.js/PGlite проверяет обновление обоих окружений, повторное применение, ограничения длины, права, стили, языковые пропорции и сохранность ID/звёзд/реальных профилей. Тест использует только БД в памяти.

Внешность заполнителей: `python tools/build_leaderboard_filler_appearance.py --check` проверяет каталог v4 и миграцию 013. Тот же SQL-тест дополнительно проверяет сохранение номеров внешности, ограничения и чтение RPC именно из таблицы. `leaderboard_local_fillers` проверяет дополнение прежнего кеша, `leaderboard_ui` — порядок полей, общий кеш портретов, счётчик звёзд и перекрытие скроллирующего текста закреплённой строкой.

## Известные ограничения

Открытые сбои и непроверенные сценарии описаны в [аудите проекта](../docs/PROJECT_AUDIT.md). Успех отдельных наборов не подтверждает готовность Android-релиза. Прежние результаты и изменения запускателей доступны в Git.
