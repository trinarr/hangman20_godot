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

## Известные ограничения

Открытые сбои и непроверенные сценарии описаны в [аудите проекта](../docs/PROJECT_AUDIT.md). Успех отдельных наборов не подтверждает готовность Android-релиза. Прежние результаты и изменения запускателей доступны в Git.
