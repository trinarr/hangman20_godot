# Сборка Android

Актуальная инструкция для checkout на 18 октября 2026. Целевая платформа — Android; команды приведены для PowerShell на Windows. Начало работы — в [README](../README.md). Прежний отчёт patch 04 сохранён в [истории экспорта](../docs/history/export_patch04.md).

## Подготовка среды

1. Установите выбранный редактор Godot и export templates **той же версии**. Последние настольные тесты выполнены на 4.7.2 stable; успешный Android-релиз на этой версии пока не зафиксирован.
2. Установите OpenJDK 17 и Android SDK. В Editor Settings → Export → Android задайте Java SDK Path и Android SDK Path. Подготовка описана в [документации Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).
3. Через меню Project установите Android/Gradle Build Template выбранного редактора. Он создаёт `android/build/`; Gradle используется для подключённых Android-библиотек. См. [Gradle builds](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html). Перед заменой вручную изменённого шаблона сохраните нужные локальные правки.
4. Установите Platform Tools, Command-line Tools, SDK Platform и Build Tools, требуемые фактическим `android/build/config.gradle`. Для NDK/CMake сверяйтесь с шаблоном и выбранным редактором. Пример из документации другой версии не задаёт параметры локальной сборки.

`android/` игнорируется Git и не придёт с чистым checkout. При проверке документации локальный `android/.build_version` содержал `4.7.2.stable`, а `config.gradle` задавал compile SDK 36, Build Tools 36.1.0, Java 17 и NDK 29.0.14206865. Это снимок локального шаблона: после переустановки читайте его новый файл, а не копируйте числа из этого абзаца.

## Пресет и зависимости

Текущие значения определяет [export_presets.cfg](../export_presets.cfg):

- Пресет — `Hangman 2.0`; Gradle включён, выбран APK. Для AAB выберите соответствующий формат в пресете и выходной файл `.aab`.
- Package ID — `com.trinarr.Hangman20`; не меняйте его для очередной версии приложения. Версии и Android version code сверяйте в пресете перед релизом; для обновления нужен новый version code.
- Пресет задаёт minimum SDK 24 и target SDK 35. Target SDK отличается от compile SDK: локальное значение compile 36 не меняет target 35 из пресета. Перед публикацией отдельно сверяйте требования выбранного магазина.
- Включены четыре ABI и Internet, Android backup выключен. Выбор ABI меняйте осознанно под канал распространения.
- Сохранённый `export_path` ведёт в пользовательский Downloads. Команды ниже явно используют игнорируемый `builds/`.

`addons/GodotAndroidYandexAds/export_plugin.gd` подключает debug/release AAR из `bin/` и Maven-зависимость Yandex Mobile Ads. Текущую версию зависимости читайте в этом файле; описание SDK — в [README плагина](../addons/GodotAndroidYandexAds/README.md). Первая Gradle-сборка требует доступа к репозиториям зависимостей. Изменение Java в `source/` не пересобирает AAR автоматически.

## Проверки и экспорт

Выполните нужные [проверки проекта](TESTS.md) и разберите ошибки. Затем импортируйте ресурсы и создайте каталог сборок:

```powershell
$godotExe = 'C:/path/to/Godot.exe'
& $godotExe --headless --editor --import --path .
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
New-Item -ItemType Directory -Force builds
& $godotExe --headless --path . --export-debug 'Hangman 2.0' 'builds/Hangman20_debug.apk'
if ($LASTEXITCODE -ne 0) { throw 'Android debug export failed' }
```

После каждого вызова проверяйте журнал и `$LASTEXITCODE`; при ошибке остановитесь. Для release сначала настройте собственный keystore и подпись в диалоге экспорта либо через поддерживаемые [переменные окружения](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html#environment-variables). Ключи и пароли храните вне Git и журналов; `export_credentials.cfg` и локальные `.env` игнорируются.

```powershell
& $godotExe --headless --path . --export-release 'Hangman 2.0' 'builds/Hangman20_release.apk'
if ($LASTEXITCODE -ne 0) { throw 'Android release export failed' }
```

Для отдельной проверки ресурсов:

```powershell
& $godotExe --headless --path . --export-pack 'Hangman 2.0' 'builds/Hangman20.pck'
if ($LASTEXITCODE -ne 0) { throw 'PCK export failed' }
```

PCK не заменяет APK/AAB и не подтверждает подключение Android SDK или рекламы.

## Содержимое экспорта

Фильтры задаёт `export_presets.cfg`, а не `.gitignore`. Сейчас исключены `supabase/*`, `tools/*`, `docs/*`, `data/*manifest.json`, редакторские каталоги слов/викторины и редакторский `export_plugin.gd`. Игре нужны runtime JSON, переводы, используемые шрифты/изображения и рекламный сервис. В include-фильтре явно оставлена миграция контента; не удаляйте её вместе с редакторскими исходниками.

При изменении фильтров проверьте реальный пакет: необходимые ресурсы доступны, служебные документы и секреты отсутствуют. Корневые README/AGENTS сами по себе не подтверждают включение или исключение из пакета. Размер исходных PNG и историческая экономия PCK не равны размеру текущего APK.

## Проверка на Android

На устройстве проверьте установку и запуск, оба языка, портретную адаптацию, сохранение/продолжение после перезапуска и выдачу наград. После изменения ресурсов проверьте шрифты, логотипы, сундук и иконки из экспортированной сборки.

Отдельно проверьте баннер, interstitial и rewarded-рекламу через нативный SDK, согласие и повторные/поздние сигналы награды. Сейчас в `project.godot` заданы demo-рекламные ID; перед публикацией настройте реальные ID и проверьте нужное окружение backend. Настольные mocks не подтверждают SDK на телефоне.

Для проверенной сборки фиксируйте commit, версию Godot, параметры шаблона/SDK, debug/release, устройство и результат. Пока такого отчёта нет, Android-экспорт на текущей версии остаётся непроверенным. Лицензии и уведомления перечислены в [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
