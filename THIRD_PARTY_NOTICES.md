# Hangman 2.0: third-party licenses / Сторонние лицензии

The root `LICENSE` and its Russian translation `LICENSE.ru.txt` apply only to
material whose relevant rights belong to Nikita Lukanin. They do not replace,
restrict or revoke licenses for third-party components, including applicable
permissions for modified versions of those components. Third-party copyright
and license notices must be preserved as required by their respective licenses.

Корневые `LICENSE` и `LICENSE.ru.txt` относятся только к материалам,
соответствующие права на которые принадлежат Никите Луканину. Они не заменяют,
не ограничивают и не отменяют лицензии сторонних компонентов, включая применимые
разрешения для их изменённых версий. Уведомления об авторских правах и лицензиях
сторонних компонентов необходимо сохранять согласно условиям этих лицензий.

## Existing license files / Существующие файлы лицензий

| Component / Компонент | License / Лицензия | Local notice / Файл |
| --- | --- | --- |
| GodotAndroidYandexAds plugin | MIT; Copyright (c) 2022 DARK NIGHT | [addons/GodotAndroidYandexAds/LICENSE](addons/GodotAndroidYandexAds/LICENSE) |
| Roboto Flex font | SIL Open Font License 1.1; The Roboto Flex Project Authors | [fonts/RobotoFlex-OFL.txt](fonts/RobotoFlex-OFL.txt) |
| Balsamiq Sans fonts | SIL Open Font License 1.1; The Balsamiq Sans Project Authors | [fonts/OFL-BalsamiqSans.txt](fonts/OFL-BalsamiqSans.txt) |

## Engine and runtime dependencies / Движок и зависимости

Hangman 2.0 uses Godot Engine. Godot's MIT license does not require the original
game code to be open source. Godot and its bundled third-party libraries retain
their own copyright notices and license requirements:

- [Godot Engine license](https://godotengine.org/license/)
- [Godot license compliance documentation](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)

Hangman 2.0 использует Godot Engine. Лицензия MIT движка не требует открывать
оригинальный код игры. Для Godot и встроенных в него сторонних библиотек
сохраняются их собственные уведомления и лицензионные требования.

The MIT license of the GodotAndroidYandexAds plugin does not license the Yandex
Mobile Ads SDK or its transitive dependencies. Those components remain subject
to their own applicable licenses and terms supplied by their providers.

Лицензия MIT плагина GodotAndroidYandexAds не является лицензией на Yandex Mobile
Ads SDK и его транзитивные зависимости. Для этих компонентов действуют их
собственные применимые лицензии и условия поставщиков.

This file is an index of identified notices, not a complete audit of every asset
or dependency. Adding it to Git does not by itself make all required notices
available inside a distributed game. Release builds must separately include or
make available the notices required for the actual components they distribute.

Этот файл — указатель выявленных уведомлений, а не полный аудит всех ассетов
и зависимостей. Его добавление в Git само по себе не делает все необходимые
уведомления доступными в распространяемой игре. При выпуске необходимо отдельно
включить или предоставить доступ к уведомлениям, требуемым для фактически
распространяемых компонентов.
