# Сборка Android

Целевая платформа — Android; команды приведены для PowerShell на Windows. Начало работы — в [README](../README.md). Прежние параметры и изменения фильтров доступны в истории Git.

## Подготовка среды

1. Установите выбранный редактор Godot и export templates **той же версии**. Последние настольные тесты выполнены на 4.7.2 stable; успешный Android-релиз на этой версии пока не зафиксирован.
2. Установите OpenJDK 17 и Android SDK. В Editor Settings → Export → Android задайте Java SDK Path и Android SDK Path. Подготовка описана в [документации Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).
3. Через меню Project установите Android/Gradle Build Template выбранного редактора. Он создаёт `android/build/`; Gradle используется для подключённых Android-библиотек. См. [Gradle builds](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html). Перед заменой вручную изменённого шаблона сохраните нужные локальные правки.
4. Установите Platform Tools, Command-line Tools, SDK Platform и Build Tools, требуемые фактическим `android/build/config.gradle`. Для NDK/CMake сверяйтесь с шаблоном и выбранным редактором. Пример из документации другой версии не задаёт параметры локальной сборки.

`android/` игнорируется Git и не придёт с чистым checkout. При проверке документации локальный `android/.build_version` содержал `4.7.2.stable`, а `config.gradle` задавал compile SDK 36, Build Tools 36.1.0, Java 17 и NDK 29.0.14206865. Это снимок локального шаблона: после переустановки читайте его новый файл, а не копируйте числа из этого абзаца.

## Пресет и зависимости

Текущие значения определяет [export_presets.cfg](../export_presets.cfg):

- Release-пресет — `Hangman 2.0`, отладочный — `Hangman 2.0 Debug`; Gradle включён, выбран APK. Для AAB выберите соответствующий формат в пресете и выходной файл `.aab`. При изменении общих Android-параметров обновляйте оба пресета.
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
& $godotExe --headless --path . --export-debug 'Hangman 2.0 Debug' 'builds/Hangman20_debug.apk'
if ($LASTEXITCODE -ne 0) { throw 'Android debug export failed' }
```

После каждого вызова проверяйте журнал и `$LASTEXITCODE`; при ошибке остановитесь. Для release сначала настройте собственный keystore и подпись в диалоге экспорта либо через поддерживаемые [переменные окружения](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html#environment-variables). Ключи и пароли храните вне Git и журналов; `export_credentials.cfg` и локальные `.env` игнорируются.

```powershell
& $godotExe --headless --path . --export-release 'Hangman 2.0' 'builds/Hangman20_release.apk'
if ($LASTEXITCODE -ne 0) { throw 'Android release export failed' }
```

Для отдельной проверки ресурсов:

```powershell
& $godotExe --headless --path . --export-pack 'Hangman 2.0' 'builds/Hangman20_release_resources.zip'
if ($LASTEXITCODE -ne 0) { throw 'PCK export failed' }
python tools/verify_release_export.py 'builds/Hangman20_release_resources.zip'
if ($LASTEXITCODE -ne 0) { throw 'Release resource verification failed' }
```

ZIP/PCK не заменяет APK/AAB и не подтверждает подключение Android SDK или рекламы. Для проверки готового APK:

```powershell
python tools/verify_release_export.py 'builds/Hangman20_release.apk' --aapt 'C:/SDK/Android/build-tools/36.1.0/aapt.exe'
if ($LASTEXITCODE -ne 0) { throw 'Release APK verification failed' }
```

Путь к `aapt.exe` берите из установленного SDK. Проверка APK дополнительно запрещает `application-debuggable` и сверяет package ID.

## Содержимое экспорта

Фильтры задаёт `export_presets.cfg`, а не `.gitignore`. Исключены инструменты, документация разработки, редакторские каталоги и манифесты, локальные сборки/секреты, исходники Java и AAR как ресурсы игры. Нативный рекламный AAR подключается отдельно Android export plugin: release-вариант для release, debug-вариант для debug. Миграция контента и лицензионные уведомления явно включены; не удаляйте их вместе с редакторскими исходниками.

Release-пресет исключает `addons/dev-console/*` и `scripts/debug/*` до компиляции скриптов. `addons/release_guard/` включён только как плагин редактора: при release-экспорте удаляет из упакованных настроек autoload консоли/логгера, параметры dev-сервисов, настройки консоли и устаревшие demo-ID. Из экспортируемого JSON удаляются два тестовых поля турнира с сохранением полной точности остальных чисел. Исходные настройки и порядок игровых autoload сохраняются; плагин не записывает `project.godot`. Для отладочной сборки с консолью используйте отдельный Debug-пресет.

`verify_release_export.py` читает фактический ZIP/APK, включая `project.binary`, ищет исходные и скомпилированные debug-файлы, проверяет autoload, кеш классов, назначения remap/import, обязательные runtime-данные и лицензии. Экспортный баланс сверяется с исходным за исключением удалённых debug-полей. Ошибка проверки блокирует приёмку артефакта, даже если Godot завершился с кодом 0.

При изменении фильтров проверьте реальный пакет: необходимые ресурсы доступны, служебные документы и секреты отсутствуют. Корневые README/AGENTS сами по себе не подтверждают включение или исключение из пакета. Размер исходных PNG и историческая экономия PCK не равны размеру текущего APK.

## Проверка на Android

На устройстве проверьте установку и запуск, оба языка, портретную адаптацию, сохранение/продолжение после перезапуска и выдачу наград. После изменения ресурсов проверьте шрифты, логотипы, сундук и иконки из экспортированной сборки.

Отдельно проверьте баннер, interstitial и rewarded-рекламу через нативный SDK, согласие и повторные/поздние сигналы награды. `yandex_ads.gd` выбирает боевые ID по placement в release, demo-ID — только в debug/editor; устаревшие demo-настройки из `project.godot` в release удаляются. Backend выбирает production RPC и обычный порог статистики, турнир использует release-длительность. Настольные mocks и проверка архива не подтверждают SDK на телефоне.

Для проверенной сборки фиксируйте commit, версию Godot, параметры шаблона/SDK, debug/release, устройство и результат. Пока такого отчёта нет, Android-экспорт на текущей версии остаётся непроверенным. Лицензии и уведомления перечислены в [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
