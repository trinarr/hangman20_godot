# Сборка Android

Целевая платформа — Android; команды приведены для PowerShell на Windows. Начало работы — в [README](../README.md). Прежние параметры и изменения фильтров доступны в истории Git.

## Подготовка среды

1. Установите выбранный редактор Godot и export templates **той же версии**. Последние настольные тесты выполнены на 4.7.2 stable; RuStore Debug APK проверен на Android 14 (03.11.2026), release на этой версии пока не подтверждён. Открытые проблемы нативных SDK перечислены в [аудите](../docs/PROJECT_AUDIT.md).
2. Установите OpenJDK 17 и Android SDK. В Editor Settings → Export → Android задайте Java SDK Path и Android SDK Path. Подготовка описана в [документации Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).
3. Через меню Project установите Android/Gradle Build Template выбранного редактора. Он создаёт `android/build/`; Gradle используется для подключённых Android-библиотек. См. [Gradle builds](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html). Перед заменой вручную изменённого шаблона сохраните нужные локальные правки.
4. Установите Platform Tools, Command-line Tools, SDK Platform и Build Tools, требуемые фактическим `android/build/config.gradle`. Для NDK/CMake сверяйтесь с шаблоном и выбранным редактором. Пример из документации другой версии не задаёт параметры локальной сборки.

`android/` игнорируется Git и не придёт с чистым checkout. При проверке документации локальный `android/.build_version` содержал `4.7.2.stable`, а `config.gradle` задавал compile SDK 36, Build Tools 36.1.0, Java 17 и NDK 29.0.14206865. Это снимок локального шаблона: после переустановки читайте его новый файл, а не копируйте числа из этого абзаца.

## Пресет и зависимости

Текущие значения определяет [export_presets.cfg](../export_presets.cfg):

- Release-пресет — `Hangman 2.0 RuStore`, формат AAB; отладочный — `Hangman 2.0 RuStore Debug`, формат APK. Для Google Play предусмотрены `Hangman 2.0 Google Play` (AAB) и `Hangman 2.0 Google Play Debug` (APK). Во всех четырёх включён Gradle. Расширение выходного файла должно соответствовать формату выбранного пресета. При изменении общих Android-параметров обновляйте все четыре пресета.
- Package ID — `com.trinarr.Hangman20`; не меняйте его для очередной версии приложения. Версии и Android version code сверяйте в пресете перед релизом; для обновления нужен новый version code.
- Все четыре пресета задают minimum SDK 24 и target SDK 36. Target SDK берётся из пресета, compile SDK — из Gradle-шаблона; сверяйте их отдельно. Перед публикацией отдельно сверяйте требования выбранного магазина.
- Включены четыре ABI и Internet, Android backup выключен. Выбор ABI меняйте осознанно под канал распространения.
- Пути `export_path` ведут в игнорируемый `builds/` и различаются по магазину и типу сборки.

`addons/GodotAndroidYandexAds/export_plugin.gd` подключает debug/release AAR из `bin/` и Maven-зависимость Yandex Mobile Ads. Текущую версию зависимости читайте в этом файле; описание SDK — в [README плагина](../addons/GodotAndroidYandexAds/README.md). Первая Gradle-сборка требует доступа к репозиториям зависимостей. Изменение Java в `source/` не пересобирает AAR автоматически.

## Магазины и рекламные ID

Ответ поддержки «Простой монетизации» от 03.11.2026: для каждого магазина приложение добавляется отдельно. Пресеты задают ровно один custom feature: `rustore` либо `google_play`. Runtime выбирает соответствующий профиль из `data/ad_store_profiles.json`; отсутствие или конфликт меток не подставляет ID другого магазина. Редактор и debug-сборки используют demo-ID независимо от магазина.

Текущие боевые ID относятся к RuStore. Профиль Google Play намеренно пуст: заполните его после регистрации отдельного приложения у менеджера. Если для этого канала подключена Google Ads, задайте `google_ads_enabled=true` и выданный `google_application_id`; экспортный плагин добавит его в Android manifest только для выбранного магазина. До подтверждения подключения не включайте этот флаг. Firebase `google-services.json` и рекламный Google Application ID — разные настройки.

Перед выпуском используйте проверяющий запускатель, который отказывается экспортировать незаполненный профиль, повторно использованные RuStore-ID в Google Play и Google Ads без Application ID:

```powershell
python tools/export_android.py --preset 'Hangman 2.0 RuStore' --check-only
python tools/export_android.py --preset 'Hangman 2.0 Google Play' --check-only
```

Вторая команда сейчас ожидаемо завершается ошибкой: Google Play ещё не настроен. Debug Google Play можно проверять с `--debug --check-only`. Прямой экспорт через Godot обходит эту предварительную проверку; готовность к публикации им не подтверждается. Общие package ID, Firebase, сохранения, version code и подпись остаются общими: разные пресеты не создают две параллельные установки на одном Android-профиле.

## Проверки и экспорт

После установки или замены Android-шаблона подготовьте единую медиацию Яндекса и Firebase:

```powershell
python tools/prepare_yandex_android.py
python tools/prepare_yandex_android.py --check
python tools/prepare_startup_android.py
python tools/prepare_startup_android.py --check
```

Подготовка startup устанавливает `HomeStartupGate` и два JNI-метода в генерируемый `GodotApp.java`. Два общих MSDF-профиля экспортируются с заранее отрисованными глифами RU/EN: после изменения переводов выполните `python tools/build_ui_msdf_fonts.py --imports-only --godot <path>` и проверку `--check`. При входе через Home системный сплеш ждёт построения и двух кадров отрисовки Home без ожидания прогрева шрифтов и фоновых загрузок; вступление начинается после подтверждённого удаления сплеша. Новый профиль входит напрямую в первое слово: два начальных кадра готовятся под сплешем, а бумага и буквы начинают вступление после подтверждённого удаления сплеша; обязательное согласие блокирует игру, Home не создаётся. Восстановление сохранённого слова завершает вступление под сплешем. Условие ожидания не блокирует UI-поток; аварийный предел удержания после старта движка — 30 секунд. Рекламу и сеть этот gate не ожидает. Повторяйте подготовку после замены Android-шаблона. `export_android.py` перед реальным экспортом проверяет наличие актуального gate и после сборки проверяет методы моста в DEX готового APK/AAB; `--check-only` по-прежнему проверяет только настройки магазина без SDK. Прямой экспорт из редактора требует заранее подготовленного шаблона.

Подготовка Яндекса закрепляет AGP 8.10.1 в `android/build/config.gradle`. Штатный Gradle wrapper 8.11.1 и JDK 17 совместимы с этой версией; SDK 36 поддерживается. Maven-зависимость `mobileads-mediation:8.6.0.0` и репозитории адаптеров подключает экспортный плагин, а не ручные изменения генерируемого Gradle-файла. Android-мост компилируется против базового API `mobileads:8.6.0`; полный набор адаптеров разрешается при экспорте приложения.

Для выпуска в RuStore Google App ID не требуется: по подтверждению менеджера «Простой монетизации» от 03.11.2026 сеть Google в этом канале не используется. Не добавляйте тестовый Google App ID в RuStore-сборку. Если для другого канала менеджер подключит Google Ads, потребуется выданный им `com.google.android.gms.ads.APPLICATION_ID`; ID продавца из app-ads.txt его не заменяет. Инструкция: [единая медиация](https://ads.yandex.com/helpcenter/ru/easy/integration/android/integration/single-mediation).

Подготовка Firebase:

```powershell
python tools/prepare_firebase_android.py
python tools/prepare_firebase_android.py --check
```

Скрипт проверяет package ID из release-пресета, копирует клиентский `config/firebase/google-services.json` в app-модуль и подключает Google Services Gradle plugin. Его повторный запуск не дублирует правки. `android/` остаётся генерируемым каталогом; исходная конфигурация и скрипт подготовки отслеживаются Git. Исходный JSON и исходники/бинарники addon исключены из игровых assets; нативные ресурсы Firebase и классы входят в APK через Gradle. Google Analytics должен быть включён для проекта в консоли Firebase.

Для пересборки **обоих** Android-мостов (Firebase и Yandex ILRD), укажите Gradle 8.11.1 и Android SDK 36; JDK 17 должен быть доступен через `JAVA_HOME`/`PATH`:

```powershell
python tools/build_android_plugins.py --gradle 'C:/path/to/gradle-8.11.1/bin/gradle.bat' --sdk 'C:/SDK/Android'
```

Скрипт собирает debug/release и обновляет AAR в `addons/*/bin/`. Определения сборки — `tools/android_plugins/`, временные результаты — `builds/android-plugins/`. Для приложения и Android-мостов используется AGP 8.10.1. Для мостов явно закреплены Build Tools 36.1.0, как в шаблоне приложения, чтобы AGP не запрашивал дополнительную установку версии 35. После замены шаблона повторяйте подготовку Яндекса и Firebase.

Подробная рекламная диагностика выключена по умолчанию. Для её проверки добавьте `logging_enabled=true` в секцию `[yandex_ads]` перед debug-экспортом, затем верните настройку. Один флаг управляет BannerDiag, подробными сообщениями Java-моста и `YandexAds.enableLogging`; release принудительно выключает их. Ошибки загрузки баннера сохраняют код без описания SDK, описание доступно только при включённой диагностике. Флаг не гарантирует отключение собственных логов всех сторонних SDK.

Для проверки Firebase на Android явно разрешите тестовый сбор настройкой `firebase_analytics/debug_enabled=true` перед debug-экспортом (секция `[firebase_analytics]`, строка `debug_enabled=true` в `project.godot`). Примите новую редакцию документов в тестовой установке и включите DebugView:

```powershell
adb shell setprop debug.firebase.analytics.app com.trinarr.Hangman20
# После проверки:
adb shell setprop debug.firebase.analytics.app .none.
```

Отмечайте тестовый трафик фильтром разработчика в Google Analytics; настройку `firebase_analytics/debug_enabled` удаляйте после проверки. Без неё Android debug не отправляет события. Проверьте отсутствие Firebase до принятия документов, события прогресса, поздние/повторные рекламные callback, реальные ILRD value/currency и баннерный refresh. Политики из `docs/` должны быть опубликованы по адресам приложения до выпуска версии с новой редакцией. Локальное изменение HTML не публикует GitHub Pages.

Для отчётов GA4 зарегистрируйте нужные параметры `placement`, `ad_format`, `stage_type`, `hint_type`, `game_mode`, `content_language`, `ui_language`, `outcome`, `source`, `purpose`, `currency`, `level_number` как event-scoped custom dimensions; `wait_ms`, `amount`, `completed`, `perfect`, `won_stages`, `total_stages` — как custom metrics по потребности отчёта. `amount` суммируйте отдельно по `currency`; суммирование монет с жизнями или подсказками не имеет смысла. В DebugView параметры доступны для первичной проверки до настройки отчётов. Не используйте отдельные имена событий для каждого уровня или рекламного запроса. Настройки консоли не создаются изменением клиентского кода.

Google Analytics доступен без оплаты в Spark; экономить общий объём событий ради отдельного Spark-пакета не требуется. Сохраняйте небольшой фиксированный набор имён, значения режима/исхода/назначения передавайте параметрами, не регистрируйте ID и seed как измерения. Основные лимиты сбора: 500 различных имён событий на пользователя приложения, 25 параметров на событие и 100 000 событий на пользователя в сутки; это ограничения Analytics, а не квота платных записей Firestore. Дедупликация UI и объединение одинаковых экономических операций одного сохранения сокращают шум без выборочного удаления результатов/дохода. Актуальные условия: [Firebase Analytics](https://firebase.google.com/products/analytics), [лимиты сбора GA4](https://support.google.com/analytics/answer/9267744).

После изменения `project.godot`, плагинов или `export_presets.cfg` закройте и заново откройте Godot: уже открытый редактор может экспортировать прежние настройки и перезаписать обновлённый пресет. Включите плагин Release Guard и убедитесь, что доступны четыре пресета. Выполните нужные [проверки проекта](TESTS.md) и разберите ошибки. Затем импортируйте ресурсы и создайте каталог сборок:

```powershell
$godotExe = 'C:/path/to/Godot.exe'
& $godotExe --headless --editor --import --path .
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
New-Item -ItemType Directory -Force builds
python tools/export_android.py --godot $godotExe --preset 'Hangman 2.0 RuStore Debug' --debug --output 'builds/Hangman20_rustore_debug.apk'
if ($LASTEXITCODE -ne 0) { throw 'Android debug export failed' }
```

После каждого вызова проверяйте журнал и `$LASTEXITCODE`; при ошибке остановитесь. Для release сначала настройте собственный keystore и подпись в диалоге экспорта либо через поддерживаемые [переменные окружения](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html#environment-variables). Ключи и пароли храните вне Git и журналов; `export_credentials.cfg` и локальные `.env` игнорируются.

```powershell
python tools/export_android.py --godot $godotExe --preset 'Hangman 2.0 RuStore' --output 'builds/Hangman20_rustore.aab'
if ($LASTEXITCODE -ne 0) { throw 'Android release export failed' }
```

Для отдельной проверки ресурсов:

```powershell
& $godotExe --headless --path . --export-pack 'Hangman 2.0 RuStore' 'builds/Hangman20_release_resources.zip'
if ($LASTEXITCODE -ne 0) { throw 'PCK export failed' }
python tools/verify_release_export.py 'builds/Hangman20_release_resources.zip' --check-presets
if ($LASTEXITCODE -ne 0) { throw 'Release resource verification failed' }
```

Флаг `--check-presets` проверяет совпадение общих Android options четырёх пресетов, release-фильтры и отсутствие dev-features. Формат экспорта проверяется отдельно: AAB для release и APK для debug.

ZIP/PCK не заменяет APK/AAB и не подтверждает подключение Android SDK или рекламы. `verify_release_export.py` поддерживает ZIP ресурсов, APK и AAB, включая Godot assets в `assetPackInstallTime`. Для AAB укажите `--bundletool 'C:/path/to/bundletool-all.jar' --java 'C:/path/to/java.exe'`: проверяются ресурсы, структура bundle и базовый release-манифест без ранних providers. Подпись AAB и установку/запуск APK, полученных из него, проверяйте отдельно. Несколько `project.binary` в разных модулях отклоняются как неоднозначный пакет.

Если для распространения или проверки нужен release APK, создайте копию release-пресета `Hangman 2.0 RuStore` с именем `Hangman 2.0 RuStore APK`, выберите в ней формат APK и сохраните те же фильтры ресурсов, общие Android-параметры и release-подпись. Затем экспортируйте и проверьте APK:

```powershell
python tools/export_android.py --godot $godotExe --preset 'Hangman 2.0 RuStore APK' --output 'builds/Hangman20_rustore_release.apk'
if ($LASTEXITCODE -ne 0) { throw 'Android release APK export failed' }
python tools/verify_release_export.py 'builds/Hangman20_rustore_release.apk' --aapt 'C:/SDK/Android/build-tools/36.1.0/aapt.exe'
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

## Конфиденциальность при выпуске единой медиации

Редакция документов 3 описывает сторонние рекламные сети и передачу рекламного выбора в медиацию. До выпуска опубликуйте обе страницы `docs/privacy-policy.html` и `docs/privacy-policy-en.html` по действующим адресам приложения. Принятие старой редакции не открывает рекламу и Firebase. При успешном принятии редакции 3 прежний положительный выбор персонализации сбрасывается, прежний отказ сохраняется; далее применяется существующая региональная модель. Ошибка сохранения откатывает и принятие, и рекламный выбор.

Проверьте декларации данных в используемых магазинах по фактическому составу адаптеров в итоговом APK/AAB: идентификаторы устройства, IP/приблизительный регион, взаимодействия с рекламой, назначение обработки и передача рекламным партнёрам. Описание только Yandex больше не покрывает всю медиацию. Для Google Ads сверяйте требования к форме согласия с менеджером и правилами выбранного магазина; наличие `setUserConsent` само по себе не подтверждает выполнение требований каждого партнёра. Не заявляйте отсутствие сбора данных всеми сторонними SDK на основании настроек Firebase: его рекламный ID и персонализация отключены отдельно.

На чистой тестовой установке подтвердите по Android Logcat отсутствие рекламной инициализации/запросов до принятия текущих документов и игрового разрешения рекламы. Экспортный плагин задаёт `com.yandex.mobile.ads.AUTOMATIC_SDK_INITIALIZATION=false` и удаляет startup providers Yandex/AppLovin/StartApp, сохраняя SDK и адаптеры. У Yandex 8.6.0 debug-проверка интеграции запускает статическую подготовку Pangle даже при этом флаге; используется ручной публичный initialize после игрового gate. Для myTarget добавляется `com.my.target.autoInitMode` с целым значением `0`, не boolean false. В готовом APK проверьте отсутствие этих трёх providers и числовой тип metadata. Перед инициализацией должны передаваться выбранные `true`/`false`; повторите запуск и отзыв через настройки. При принятии новой редакции документов уже разблокированная реклама должна запуститься без перезапуска приложения даже с кешированным регионом/явным отказом от персонализации. Desktop fake bridge не подтверждает отсутствие ранней активности нативных SDK. На устройстве проверьте закрытие без награды, полный просмотр, поздние/повторные callback и Firebase `ad_impression` с фактическими `network.name`, доходом и валютой ILRD. Значение за показ не делите на 1000 и не заменяйте отсутствующие доход/сеть вымышленными значениями.
