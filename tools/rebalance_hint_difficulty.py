#!/usr/bin/env python3
"""Keep word hints aligned with the continuous word difficulty scale.

Vague easy clues and over-revealing hard clues are replaced with curated
semantic descriptions.  Clues never expose the answer length or first letter,
because those mechanics already exist separately in the game.  ``--check``
validates the paired datasets; ``--apply`` performs the deterministic update.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EASY_MAX_DIFFICULTY = 0.5
MIN_EASY_HINT_TOKENS = 4
VERY_EASY_MAX_DIFFICULTY = 0.15
MAX_VERY_EASY_HINT_TOKENS = 12
MAX_VERY_EASY_TOKEN_LENGTH = 12
MAX_VERY_EASY_AVERAGE_TOKEN_LENGTH = 6.8


MANUAL_HINTS: dict[str, dict[str, str]] = {
    "ru": {
        # Easy words: replace clues that are technically true but too broad.
        "ГАРПИЯ": "Крупная тропическая хищная птица с мощными лапами и широкими крыльями",
        "САЛАМАНДРА": "Хвостатое земноводное, которое в старых легендах связывали с огнём",
        "ПАПАЙЯ": "Тропический плод с оранжевой мякотью и множеством чёрных семян",
        "ПАРОХОД": "Судно, которое движется благодаря паровой машине",
        "МОТОЦИКЛ": "Двухколёсное моторное транспортное средство с рулём и седлом",
        "РАКЕТА": "Летательный аппарат с реактивным двигателем для полётов в атмосфере или космосе",
        "ВИДЕОКАРТА": "Компонент компьютера, который обрабатывает графику и выводит изображение на экран",
        "ПЕРСИЛАД": "Французская смесь петрушки и чеснока для ароматной приправы или начинки",
        "НАТТО": "Японское блюдо из ферментированных соевых бобов с тягучей текстурой",
        "БАКАЛЕЯ": "Категория сухих продуктов длительного хранения: круп, сахара, муки и специй",
        "ЛАНОЛИН": "Жироподобное вещество из овечьей шерсти, используемое в кремах и мазях",
        "ПИРАМИДА": "Сооружение с широким основанием и гранями, сходящимися к вершине",
        "АРМСТРОНГ": "Американский астронавт, первым ступивший на поверхность Луны",
        "БЕЗРУКОВ": "Российский актёр, сыгравший Сашу Белого в сериале «Бригада»",
        "ГОГОЛЬ": "Русский писатель, автор «Мёртвых душ» и комедии «Ревизор»",
        "ПИТОН": "Крупная неядовитая змея, которая душит добычу кольцами тела",
        "ЛИСИЦА": "Рыжий хищный зверь с вытянутой мордой и пушистым хвостом",
        "МНОГОБОРЬЕ": "Соревнование, где итог складывается из результатов нескольких спортивных дисциплин",
        "СОСТЯЗАНИЕ": "Организованная борьба участников за победу и лучший результат",
        "СЕКУНДАНТ": "Помощник боксёра или фехтовальщика, находящийся рядом во время поединка",
        "АРБИТР": "Судья, следящий за соблюдением правил во время спортивной встречи",
        "ВИНДСЕРФИНГ": "Катание по воде на доске с закреплённым парусом",
        "СНОУБОРД": "Доска для спуска по снегу, к которой обе ноги крепятся боком",
        "БОРЬБА": "Единоборство, где соперника побеждают броском, удержанием или болевым приёмом",
        "ЯПОНИЯ": "Островное государство Восточной Азии, где находятся Токио и гора Фудзи",
        "ХИРОСИМА": "Японский город, переживший атомную бомбардировку в августе 1945 года",
        "КУЗНЕЧИК": "Насекомое с сильными задними ногами, известное дальними прыжками и стрекотом",
        "КАЙМАН": "Крокодиловый хищник из рек и болот Центральной и Южной Америки",
        "МЕДУЗА": "Студенистое морское животное с щупальцами, способными обжечь кожу",
        "МУРАВЕЙ": "Общественное насекомое, которое живёт колониями и строит большие гнёзда",
        "ОНДАТРА": "Полуводный грызун, похожий на крупную крысу и строящий жилища у воды",
        "ПЕСКАРЬ": "Небольшая пресноводная рыба, которая держится у песчаного дна",
        "БАБУИН": "Африканская обезьяна с вытянутой мордой, крупными клыками и наземным образом жизни",
        "БУЙВОЛ": "Массивное стадное животное с широкими изогнутыми рогами",
        "КУЛАН": "Дикий азиатский родственник осла, обитающий в степях и полупустынях",
        "ЛИСТОВЕРТКА": "Гусеница сворачивает листья в трубочки и повреждает плодовые растения",
        "ЛОРИ": "Медлительный ночной примат с большими круглыми глазами",
        "ТАВОЛГА": "Луговое растение с пышными соцветиями мелких душистых белых или розовых цветков",
        "НОСОРОГ": "Крупное толстокожее млекопитающее с одним или двумя рогами на морде",
        "БЕРКУТ": "Крупный орёл, который охотится в горах и степях",
        "ДИНГО": "Одичавшая собака Австралии с рыжеватой шерстью и стоячими ушами",
        "КУКУШКА": "Птица, которая подбрасывает яйца в чужие гнёзда",
        "КАРАКАЛ": "Дикая кошка со стройным телом и длинными чёрными кисточками на ушах",
        "САЙГАК": "Степная антилопа с необычным вздутым и подвижным носом",
        "ТЮЛЕНЬ": "Морское млекопитающее с ластами, отдыхающее на берегу или льду",
        "ИВОЛГА": "Певчая птица, у самца которой ярко-жёлтое оперение с чёрными крыльями",
        "ВЕРБЛЮД": "Пустынное животное с одним или двумя горбами, где хранится запас жира",
        "КАБАН": "Дикий родственник свиньи с клыками и жёсткой щетиной",
        "ДИКОБРАЗ": "Крупный грызун, защищённый длинными острыми иглами",
        "СОБОЛЬ": "Таёжный пушной зверёк из семейства куньих с ценным густым мехом",
        "ЛЯГУШКА": "Земноводное с длинными задними ногами, способное далеко прыгать",
        "ПАВЛИН": "Птица, самец которой раскрывает огромный веерообразный хвост с глазчатыми перьями",
        "КВАДРОЦИКЛ": "Моторное транспортное средство с рулём и четырьмя колёсами для бездорожья",
        "КАТАМАРАН": "Судно из двух параллельных корпусов, соединённых общей палубой",
        "НОУТБУК": "Переносной компьютер со встроенными экраном, клавиатурой и аккумулятором",
        "АНДРОИД": "Робот, внешностью и движениями напоминающий человека",
        "ЛУНОХОД": "Самоходный исследовательский аппарат, работающий на поверхности спутника Земли",
        "ТРАНЗИСТОР": "Полупроводниковый компонент, который усиливает или переключает электрический сигнал",
        "КОМПЬЮТЕР": "Электронное устройство для обработки, хранения и отображения данных",
        "САМОСВАЛ": "Грузовик с кузовом, который наклоняется и самостоятельно выгружает груз",
        "ЛЕДОКОЛ": "Мощное судно с укреплённым корпусом, прокладывающее путь через замёрзшее море",
        "КАЛЬКУЛЯТОР": "Небольшое устройство для быстрого выполнения арифметических вычислений",
        "ПУЛЕМЕТ": "Автоматическое оружие, способное вести длительный огонь очередями",
        "ТЕПЛОВОЗ": "Железнодорожный локомотив, который приводит в движение дизельный двигатель",
        "АВТОБУС": "Многоместный дорожный транспорт, перевозящий пассажиров по установленному маршруту",
        "ЯДЕРНЫЙ РЕАКТОР": "Установка, где поддерживается управляемая цепная реакция деления атомных ядер",
        "ВЕЛОСИПЕД": "Двухколёсный транспорт, который приводят в движение педалями",
        "АВИАЦИЯ": "Совокупность летательных аппаратов и деятельности, связанной с полётами в воздухе",
        "БИНОКЛЬ": "Ручной оптический прибор с двумя окулярами для наблюдения вдаль",
        "ТЕЛЕСКОП": "Прибор, с помощью которого наблюдают далёкие звёзды, планеты и галактики",
        "КОРОЛЕВ": "Советский конструктор ракет, руководивший запусками первого спутника и полётом Гагарина",
        "АВГУСТ": "Первый римский император и наследник политического дела Юлия Цезаря",
        "АРХИМЕД": "Древнегреческий учёный, связанный с законом плавучести и возгласом «Эврика!»",
        "ЕВКЛИД": "Античный математик, систематизировавший геометрию в труде «Начала»",
        "ЙОГУРТ": "Густой кисломолочный продукт, получаемый с помощью специальных бактериальных культур",
        "СОЛЯНКА": "Густой русский суп с мясом или рыбой, солёными огурцами и пряностями",
        "ПИЦЦА": "Итальянская лепёшка с томатным соусом, сыром и запечённой начинкой",
        "МОРОЖЕНОЕ": "Замороженный сладкий десерт из молока, сливок или фруктового пюре",
        "ТИРАМИСУ": "Итальянский десерт из пропитанного кофе печенья, маскарпоне и какао",
        "ВАРЕНИКИ": "Кусочки теста с начинкой, которые отваривают в воде",
        "КАРДАМОН": "Ароматная пряность из семенных коробочек, часто добавляемая в чай и выпечку",
        "ЭСПРЕССО": "Небольшая порция крепкого кофе, приготовленная под давлением",
        "ТЕРИЯКИ": "Японский сладко-солёный соус на основе сои, используемый для глазировки",
        "МОККО": "Сорт арабского кофе, именем которого также называют напиток с шоколадом",
        "АРАБИКА": "Самый распространённый вид кофейного дерева с мягким ароматным вкусом зёрен",
        "ВИНДАЛУ": "Острое индийское карри с португальскими корнями, уксусом и пряностями",
        "ГУЛЯШ": "Венгерское мясное блюдо или густой суп с паприкой",
        "ПОПКОРН": "Зёрна кукурузы, которые при нагревании лопаются и становятся воздушными",
        "ХАЛВА": "Рассыпчатая восточная сладость из семян, орехов и сахарной массы",
        "АДЖИКА": "Острая кавказская приправа из перца, соли, чеснока и пряностей",
        "ЧИЗКЕЙК": "Десерт на основе сливочного сыра или творога, часто с песочной основой",
        "ПЕППЕРОНИ": "Острая колбаса с паприкой, популярная как начинка для американской пиццы",
        "МАНГО": "Тропический плод с крупной косточкой и сладкой жёлто-оранжевой мякотью",
        "КОМПОТ": "Сладкий напиток, сваренный из фруктов или ягод в воде",
        "СОСИСКА": "Небольшое колбасное изделие, которое обычно отваривают или обжаривают целиком",
        "САЛАТ": "Холодное блюдо из нарезанных и смешанных овощей или других продуктов",
        "ПИРОЖНОЕ": "Небольшое отдельное кондитерское изделие с кремом или начинкой",
        "АЙРАН": "Освежающий кисломолочный напиток, разбавленный водой и иногда подсоленный",
        "АКАДЕМИЯ": "Высшее научное или учебное учреждение, объединяющее специалистов одной области",
        "МАГИСТР": "Выпускник второй ступени высшего образования после бакалавриата",
        "ГУМАНОИД": "Существо или робот с человеческим строением тела",
        "ПРОТОН": "Положительно заряженная частица, входящая в состав атомного ядра",
        "ДЕНДРИТ": "Короткий ветвящийся отросток нервной клетки, принимающий сигналы",
        "ХРОНОЛОГИЯ": "Расположение исторических событий по времени их возникновения",
        "РЕМАРКА": "Авторское пояснение в пьесе о действиях, интонации или обстановке сцены",
        "ТЕМНАЯ МАТЕРИЯ": "Невидимая субстанция, о существовании которой судят по её гравитационному влиянию",
        "ЛЕГИОНЕР": "Воин подразделения армии Древнего Рима",
        "КРЕПОСТЬ": "Защищённое стенами и башнями сооружение для обороны территории",
        "ТАРАН": "Тяжёлое бревно, которым в древности проламывали ворота и стены",
        "РОКОКО": "Изысканный европейский стиль XVIII века с завитками, пастельными тонами и обильным декором",
        "ФАРАОН": "Правитель Древнего Египта, считавшийся земным воплощением божества",
        "ЭТНОС": "Исторически сложившаяся общность людей с общей культурой и самосознанием",
        "ИГУМЕН": "Руководитель мужского православного монастыря",
        "БАРОН": "Дворянский титул ниже виконта и графа в европейской иерархии",
        "КОРОЛЬ": "Монарх, который обычно наследует верховную власть в государстве",
        "АРБАЛЕТ": "Оружие, которое выпускает короткую стрелу из лука, закреплённого на ложе",
        "БУРГОМИСТР": "Глава городского управления в некоторых европейских странах",
        "БЕДУИН": "Представитель кочевых арабских племён пустынь Ближнего Востока и Северной Африки",
        "ГОТИКА": "Средневековый стиль с высокими соборами, стрельчатыми арками и витражами",
        "ДОСПЕХ": "Металлическое или кожаное защитное снаряжение средневекового воина",
        "АПОКАЛИПСИС": "Катастрофический конец мира или откровение о последних событиях истории",
        "ГИГАНТ": "Сказочное существо или человек необычайно огромного роста",
        "ЛОБОТРЯС": "Разговорное название ленивого человека, который избегает полезной работы",
        "ЭПОПЕЯ": "Масштабное повествование о важных исторических событиях и судьбах многих героев",
        "ЗАРАБОТОК": "Деньги, полученные человеком за выполненную работу",
        "ФОЛЬКЛОР": "Устное народное творчество: сказки, песни, предания и пословицы",
        "ЖЕНИТЬБА": "Вступление мужчины в брак и связанные с этим свадебные события",
        "СУДЬБА": "Предполагаемый ход жизненных событий, будто заранее предназначенный человеку",
        "ХРЕБЕТ": "Длинная цепь соединённых между собой горных вершин",
        "ПОКОРЕНИЕ": "Подчинение территории, народа или трудной вершины усилиям победителя",
        "ШЕРСТЬ": "Густой волосяной покров овец и некоторых других животных",
        "ДИЗАЙН": "Проектирование внешнего вида, удобства и функций предмета или среды",
        "ЗАВОД": "Крупное промышленное предприятие, где серийно производят или перерабатывают продукцию",
        "ОСТРОВ": "Участок суши, со всех сторон окружённый водой",
        "ТУРИСТ": "Человек, который путешествует ради отдыха, впечатлений или знакомства с новыми местами",
        "НЕДЕЛЯ": "Промежуток времени, состоящий из семи суток",
        "ХВОСТ": "Задний подвижный отдел тела животного, продолжающий позвоночник",
        "ТРЕНИРОВКА": "Регулярное выполнение упражнений для развития навыка, силы или выносливости",
        # Hard words: avoid handing the player a substantial part of the answer.
        "РЫБА-УДИЛЬЩИК": "Глубоководный хищник приманивает добычу светящимся отростком перед пастью",
        "ОВЦЕБЫК": "Крупное арктическое копытное с длинной густой шерстью и загнутыми рогами",
        "БИРУАНГ": "Самый мелкий представитель медведей, живущий в тропиках Юго-Восточной Азии",
        "ЖИЛЕТ УТЯЖЕЛИТЕЛЬ": "Эта тренировочная экипировка добавляет нагрузку при беге и упражнениях",
        "ПОЯС АТЛЕТИЧЕСКИЙ": "Эта широкая экипировка поддерживает корпус при тяжёлых подъёмах",
        "ЛЕНТА СОПРОТИВЛЕНИЯ": "Этот эластичный тренажёр создаёт нагрузку при растяжении",
        "ПЕТЛЯ СОПРОТИВЛЕНИЯ": "Этот замкнутый резиновый тренажёр усложняет упражнения для ног",
        "СКОРОСТНОЙ ПАРАШЮТ": "Этот тренировочный купол создаёт сопротивление позади бегуна и развивает мощность",
        "МАНЕКЕН БОРЦОВСКИЙ": "На этом мягком человекообразном снаряде отрабатывают броски и удержания",
        "КАПИТАНСКАЯ ПОВЯЗКА": "Этот знак на руке обозначает лидера команды",
        "СЕТКА ДЛЯ МЯЧЕЙ": "В этой плетёной сумке переносят сразу несколько спортивных снарядов",
        "ЧЕХОЛ ДЛЯ РАКЕТКИ": "Этот футляр защищает спортивный инвентарь со струнами при переноске",
        "УГЛОВОЙ ФЛАЖОК": "Этот вертикальный маркер стоит в углу футбольного поля",
        "ТАБЛО ЗАМЕН": "На этой электронной панели показывают номера уходящего и выходящего игроков",
        "СЕРЕБРИСТЫЕ ОБЛАКА": "Эти высокие атмосферные образования светятся после заката и выглядят как бледные волны",
        "ГРИБНАЯ СЕТЬ": "Эта подземная паутина нитей мицелия соединяет корни растений и переносит вещества",
        "КВАНТОВЫЙ КОМПЬЮТЕР": "Вычислительная машина использует кубиты, суперпозицию и запутанность",
        "КВАНТОВАЯ СВЯЗЬ": "Передача состояний частиц позволяет обнаруживать попытку перехвата данных",
        "КВАНТОВЫЙ РЕЗОНАТОР": "Это устройство удерживает и усиливает колебания системы на уровне отдельных квантов",
        "КВАНТОВЫЙ КЛЮЧ": "Криптографический секрет передают через состояния частиц так, чтобы обнаружить перехват",
    },
    "en": {
        # Easy words: replace clues that are too generic for their difficulty.
        "SAUDI ARABIA": "A Middle Eastern kingdom that contains Mecca and Medina",
        "PARTRIDGE": "A ground-dwelling game bird with a rounded body and short tail",
        "CARNATION": "A ruffled flower often worn in a buttonhole or used in bouquets",
        "SCALLOP": "A fan-shelled marine mollusk that swims by clapping its shells",
        "TRACTOR": "A powerful farm vehicle used to pull ploughs and machinery",
        "VOLTMETER": "An instrument that measures electrical potential difference",
        "BLUETOOTH": "A short-range wireless standard used to connect nearby devices",
        "FARADAY": "The English scientist associated with electromagnetic induction and the electric motor",
        "SAFFRON": "A costly golden spice made from the stigmas of crocus flowers",
        "SOUP": "A liquid dish made by simmering vegetables, meat, or other ingredients",
        "BACON": "Salt-cured pork commonly served in thin fried slices",
        "CARDAMOM": "An aromatic spice from seed pods, common in chai and curries",
        "GINGER": "A pungent underground stem used fresh or dried as a spice",
        "HAZELNUT": "A small round nut used in praline and chocolate spreads",
        "DIODE": "An electronic component that mainly allows current to flow in one direction",
        "BINOCULAR": "A two-eyed optical device for viewing distant objects",
        "FRONTIER": "The boundary between settled territory and an unexplored or neighbouring region",
        "OUTBREAK": "A sudden rise in cases of a disease in one place",
        "UNDERGROUND": "An urban railway system whose trains often run below street level",
        "SOMERSAULT": "An acrobatic movement in which the body rolls completely over head and heels",
        "TENNIS": "A court sport where players hit a felt-covered ball across a net with racquets",
        "POWERLIFTING": "A strength competition based on the squat, bench press, and deadlift",
        "PEACOCK": "The male peafowl, famous for displaying a huge fan of iridescent tail feathers",
        "LEMMING": "A small northern rodent known in myth for following others over cliffs",
        "GAZELLE": "A slender, swift antelope of African and Asian grasslands",
        "ESCALATOR": "A continuously moving staircase that carries people between floors",
        "DYNAMO": "A machine that converts mechanical rotation into direct electrical current",
        "EINSTEIN": "The physicist who developed relativity and expressed mass-energy equivalence as E=mc²",
        "ARISTOTLE": "The ancient Greek philosopher who taught Alexander the Great and founded the Lyceum",
        "USAIN BOLT": "The Jamaican sprinter who won Olympic titles and set the 100-metre world record",
        "RAISIN": "A grape dried in the sun or by warm air until it becomes small and sweet",
        "TANGERINE": "A small orange citrus fruit with loose skin that is easy to peel",
        "CARROT": "An orange taproot vegetable often eaten raw, boiled, or roasted",
        "ECLAIR": "A long choux pastry filled with cream and topped with icing",
        # Hard words: remove direct repetitions of the answer's components.
        "FLAG FOOTBALL": "In this non-contact gridiron variant, defenders stop a runner by pulling a waist marker",
        "BALANCE BOARD": "This unstable training platform develops equilibrium and ankle control",
        "BOWLING BALL": "This heavy finger-holed sphere is rolled down a polished lane toward pins",
        "EXERCISE BALL": "This large inflatable sphere supports stability and fitness drills",
        "WRESTLING SHOE": "This lightweight high-grip footwear is made for combat-sport mats",
        "WEIGHT PLATE": "This round load slides onto a barbell to increase resistance",
        "GOAL ANCHOR": "This fitting secures a portable scoring frame against tipping",
        "COCONUT CRAB": "This enormous land-dwelling crustacean can crack tropical fruit with powerful claws",
        "GAMING HANDHELD": "This portable computer combines built-in game controls with its own screen",
        "SOLAR BATTERY": "This storage unit keeps electricity generated from sunlight for later use",
        "DATA ENGINEER": "This specialist builds and maintains pipelines that collect, transform, and store information",
        "VIDEO EDITOR": "This specialist selects and arranges recorded footage into a finished sequence",
        "GAME PRODUCER": "This coordinator manages people, schedules, budgets, and milestones during interactive entertainment development",
        "CINNAMON ROLL": "This spiral pastry wraps a sweet brown spice filling inside soft dough",
        "BANANA BREAD": "This quick sweet loaf gets its moisture from mashed yellow fruit",
        "CHIA PUDDING": "This breakfast thickens when tiny seeds absorb milk or another liquid",
        "PROTEIN PANCAKE": "This griddle-cooked breakfast boosts its macronutrient content with enriched ingredients",
        "OVERNIGHT OATS": "This breakfast softens rolled grains in liquid in the refrigerator until morning",
        "TRUFFLE FRIES": "These fried potato strips are finished with an earthy gourmet aroma",
        "ESPRESSO MARTINI": "This cocktail combines vodka, coffee liqueur, and a fresh concentrated coffee shot",
        "CITRUS ZESTER": "This tool removes thin aromatic outer peel from lemons and oranges",
        "TEST TUBE HOLDER": "This laboratory tool grips a hot narrow glass vessel",
        "STAFF SLING": "This weapon extends a flexible projectile launcher with a long wooden shaft",
        "POLE HAMMER": "This long-handled weapon mounts a blunt striking head opposite a spike",
        "LAB GROWN MEAT": "This food is produced from animal cells cultivated outside the animal",
        "CONTACTLESS CARD": "This payment token sends data when held near a terminal",
        "THE SOCIAL NETWORK": "This drama portrays the founding disputes behind Facebook",
        "PONTIFF": "A title for the head of the Roman Catholic Church",
    },
}


# The lowest difficulty tier uses short, everyday wording.  These overrides
# avoid formal, scientific, or encyclopedic phrases even when they are correct.
PLAIN_HINTS: dict[str, dict[str, str]] = {
    "ru": {
        "ОЛИМПИАДА": "Большие мировые игры, перед которыми к стадиону несут огонь",
        "МИНИ-ФУТБОЛ": "Футбол в зале, где играют маленькие команды",
        "НЬЮ-ЙОРК": "Американский город с жёлтыми такси, небоскрёбами и Центральным парком",
        "ЛОНДОН": "Город на Темзе с красными автобусами и башней Биг-Бен",
        "БЕЛАРУСЬ": "Страна между Россией и Польшей, известная лесами и озёрами",
        "ЕГИПЕТ": "Страна пирамид на берегах реки Нил",
        "КОЛЕСО": "Круглая деталь, которая вращается и помогает ехать",
        "АВТОБУС": "Большая машина, которая возит много людей по маршруту",
        "СЕРВЕР": "Компьютер, который хранит данные и отдаёт их другим устройствам",
        "ИНТЕРНЕТ ВЕЩЕЙ": "Сеть вещей, которые сами передают данные через интернет",
        "УМНЫЙ ДОМ": "Дом, где свет, тепло и защита управляются общей системой",
        "УМНЫЙ СВЕТ": "Лампы, которыми можно управлять голосом или через приложение",
        "МЕТРО": "Городские поезда, которые часто ходят под землёй",
        "ЛОКОМОТИВ": "Машина, которая тянет или толкает вагоны по рельсам",
        "АВГУСТ": "Первый император Рима и наследник Юлия Цезаря",
        "РЕСТОРАН": "Место, где посетители выбирают блюда и едят за столом",
        "СПЕКТР": "Набор цветов или других значений, выстроенных по порядку",
        "ВСЕЛЕННАЯ": "Весь космос, все звёзды, планеты и миры",
        "ИССЛЕДОВАНИЕ": "Поиск и проверка новых знаний о выбранной теме",
        "ИСТОРИЯ": "Наука о событиях прошлого и жизни людей",
        "РАСПАД СССР": "Событие 1991 года, после которого союзная страна разделилась",
        "ФОТОГРАФИЯ": "Способ сохранять изображение с помощью камеры и света",
        "ПИСТОЛЕТ": "Небольшое оружие, из которого обычно стреляют одной рукой",
        "ЗАЩИТНИК": "Игрок, который мешает сопернику забить гол или набрать очки",
        "ОБРАЗОВАНИЕ": "Знания и навыки, которые человек получает во время учёбы",
        "СЛОВАРЬ": "Книга со словами и объяснением их значений",
        "СУДЬБА": "Ход жизни, который будто заранее назначен человеку",
        "ДЕПАРТАМЕНТ": "Крупный отдел внутри компании или другой большой службы",
        "ЗЕРКАЛО": "Гладкий предмет, в котором человек видит своё отражение",
        "ДИЗАЙН": "Создание внешнего вида и удобной формы предмета",
        "ПАМЯТНИК": "Статуя или строение в память о человеке или событии",
        "ЗАВОД": "Большое место, где машины и люди делают товары",
        "ЛИТЕРАТУРА": "Книги, рассказы, стихи и другие письменные произведения",
        "РЕАКЦИЯ": "Видео, где автор показывает свои чувства к чужому материалу",
        "ПРЕМИЯ": "Деньги или награда за хороший результат",
        "РЕМОНТ": "Починка или обновление комнаты, вещи или техники",
        "ПРИЛОЖЕНИЕ": "Программа, которую ставят на телефон или компьютер",
        "МИНИ-АЛЬБОМ": "Музыкальный выпуск длиннее сингла, но короче обычного альбома",
        "НЕФТЬ": "Фильм о жадном добытчике топлива в начале двадцатого века",
        "ПОМНИ": "Фильм о человеке, который не запоминает новые события",
        "ДРУГИЕ": "Мистический фильм о семье в тёмном доме с тайной",
    },
    "en": {
        "BASKETBALL": "Players throw a ball through a high hoop",
        "TENNIS": "Players use racquets to hit a ball over a net",
        "ULTIMATE": "A team sport played with a flying disc and end zones",
        "GHANA": "A West African country once called the Gold Coast",
        "ISRAEL": "A Middle Eastern country where modern Hebrew is widely spoken",
        "GERMANY": "A European country known for fast roads, castles, and Christmas markets",
        "CHINA": "The country linked with early paper, printing, and the compass",
        "BRAZIL": "The large South American country where people speak Portuguese",
        "CANADA": "A huge northern country with a red maple leaf flag",
        "BERLIN": "The German capital that was once split by a wall",
        "NETHERLANDS": "A European country known for canals, windmills, and sea walls",
        "GREECE": "The European country where the ancient Olympic Games began",
        "PACIFIC OCEAN": "The largest body of water on Earth",
        "BLUE DRAGON": "A tiny blue sea animal that floats upside down",
        "FLYING FOX": "A very large bat that eats fruit and sleeps in groups",
        "BUSH DOG": "A short-legged wild dog from South America",
        "AYE-AYE": "A night animal from Madagascar with one very long finger",
        "SAND CAT": "A small desert cat with furry paws",
        "SUN BEAR": "The smallest bear, with a pale chest mark and long tongue",
        "NETWORK": "A group of connected points that can share information",
        "FIRE ENGINE": "A red rescue vehicle carrying ladders, hoses, and a siren",
        "ACTION CAMERA": "A small tough camera used during sports and travel",
        "SMART LOCK": "A door lock opened by an app, code, or finger",
        "E-INK": "A screen that looks like paper and uses little power",
        "HOME SERVER": "A home computer that shares files and media with other devices",
        "EINSTEIN": "The scientist known for relativity and the famous E=mc² formula",
        "NEWTON": "The scientist linked with gravity and a falling apple",
        "RESEARCHER": "A person who studies a subject to find new facts",
        "EMMA STONE": "The American actor who starred in La La Land",
        "FLAT WHITE": "Coffee with steamed milk and only a thin layer of foam",
        "CLOUD BREAD": "Very light bread with a soft, airy feel",
        "HOST STAND": "The place where restaurant guests are welcomed and seated",
        "BREAD MAKER": "A machine that mixes dough and bakes a loaf",
        "BACTERIA": "Tiny living things found almost everywhere, including inside the body",
        "DARK MATTER": "Hidden material whose pull can be seen around stars and galaxies",
        "DARK ENERGY": "Unknown energy linked to the universe growing faster",
        "STEM CELL": "A basic cell that can grow into other kinds of cells",
        "LA NINA": "A weather pattern that cools part of the Pacific Ocean",
        "MOON RACE": "A contest to land the first person on the Moon",
        "BERLIN WALL": "The barrier that once split the German capital in two",
        "SPACE RACE": "A contest between two countries to lead in space",
        "COLD WAR": "A long struggle between America, the Soviet Union, and their allies",
        "ARAB SPRING": "A wave of protests across Arab countries in the early 2010s",
        "OPEN SOURCE": "Software whose code anyone may view, change, and share",
        "BLACK DEATH": "A deadly plague that killed many people in old Europe",
        "LIVE AID": "A huge 1985 concert that raised money for famine relief",
        "AI BOOM": "A time when smart computer tools quickly became very popular",
        "SUPPORT": "Help that holds something up or helps someone through trouble",
        "SETTLEMENT": "A new place where people build homes and live",
        "SCRATCH": "A shallow mark left by a claw, branch, or sharp object",
        "IMAGINATION": "The ability to make pictures and stories inside the mind",
        "PAPER": "Thin sheets used for writing, printing, wrapping, and folding",
        "NEWSPAPER": "A daily or weekly paper that reports the news",
        "ANIMAL": "A living being that eats and can usually move",
        "STORIES": "Photos or short clips that vanish from a profile after one day",
        "SHORT VIDEO": "A quick video that usually lasts less than a minute",
        "CHALLENGE": "An online task that many people try and share",
        "REMOTE WORK": "Doing a job away from the main office",
        "PITCH DECK": "A short set of slides explaining a business idea",
        "SCREEN TIME": "The time spent using a phone, computer, or other screen",
        "WALLET": "A small case for money, cards, and personal papers",
        "DIRECTOR": "The person who guides how a film is made",
        "SCENE": "One part of a film set in one place or moment",
        "COMEDY": "A film or play made mainly to make people laugh",
        "MAKEUP": "Color and other products put on a face for a role",
        "THE MATRIX": "A film where a red pill reveals a hidden false world",
        "ROCKY": "A film about an unknown boxer facing the champion",
        "HOME ALONE": "A comedy about a boy defending his home from two thieves",
        "THE LION KING": "An animated film about a young lion returning home",
        "FIGHT CLUB": "A film about an office worker who starts a secret fight group",
        "WALL-E": "An animated film about a lonely robot cleaning an empty Earth",
        "FROZEN": "An animated film about two sisters and dangerous ice magic",
        "HARRY POTTER": "A film series about a boy learning magic at school",
        "PRETTY WOMAN": "A love story about a rich man and a woman he meets",
        "LA LA LAND": "A musical about a musician and actor chasing their dreams",
        "BAD GUY": "A Billie Eilish song with a soft voice and deep bass",
        "FAN SERVICE": "Extra details added mainly to please existing fans",
        "ADAPTATION": "A film or show made from a book, game, or comic",
        "COVER SONG": "A new version of a song first released by someone else",
        "SAMPLE": "A short piece of an old recording used in new music",
        "ARRIVAL": "A film about a woman learning how strange visitors speak",
        "POOR THINGS": "A film about a woman brought back to life",
        "THE BEAR": "A series about a chef running a troubled family restaurant",
        "PAST LIVES": "A love story about childhood friends meeting again years later",
        "SOUL": "An animated film about a musician separated from his body",
        "ALIENS": "A film where soldiers fight creatures on a far colony",
        "GET OUT": "A horror film about a man visiting his girlfriend's strange family",
        "NOPE": "A horror film about siblings facing something strange in the sky",
        "LIFE OF PI": "A film about a young man sharing a boat with a tiger",
    },
}


# A second pass catches short clues that still sound formal because most of
# their words are long or abstract.
VERY_PLAIN_HINTS: dict[str, dict[str, str]] = {
    "ru": {
        "БОРЬБА": "Спорт, где противника бросают на ковёр и удерживают",
        "СОЧИ": "Город у Чёрного моря с пляжами и близкими горами",
        "МАШИНА": "Вещь с деталями, которая помогает делать работу",
        "КОМПЬЮТЕР": "Устройство для работы с данными, играми и программами",
        "ИНТЕРНЕТ": "Сеть, которая связывает людей и устройства по всему миру",
        "АВИАЦИЯ": "Самолёты, вертолёты и всё, что связано с полётами",
        "САМОЛЕТ": "Машина с крыльями, которая летает по воздуху",
        "ВЕРТОЛЕТ": "Летает с помощью большого винта над крышей",
        "РУЛЬ": "Круглая часть машины, которой водитель меняет путь",
        "ПИЛОТ": "Тот, кто ведёт самолёт по небу",
        "АКАДЕМИЯ": "Место, где учатся или вместе работают учёные",
        "СМЕСЬ": "Несколько веществ, которые соединены, но не стали одним новым",
        "КРЕПОСТЬ": "Стены и башни, за которыми люди прятались от врагов",
        "КОРОЛЬ": "Главный правитель страны, который часто получает власть по наследству",
        "РАСПАД СССР": "В 1991 году одна большая страна распалась на несколько новых",
        "КОНФЛИКТ": "Ссора или борьба между людьми, группами или странами",
        "ПОПЫТКА": "Шаг, сделанный ради нужного результата",
        "ИНЖЕНЕР": "Человек, который создаёт и улучшает машины, здания или системы",
        "ОТПУСК": "Дни отдыха, когда человек временно не работает",
        "ХВОСТ": "Задняя часть тела животного, которая обычно двигается",
        "БАЛАНС": "Состояние, когда разные стороны не перевешивают друг друга",
        "КОЛЛЕКЦИЯ": "Собранные вместе вещи одной темы или вида",
        "ПЕСНЯ": "Слова и музыка, которые человек поёт",
        "ПИАНИНО": "Инструмент с клавишами и маленькими молотками внутри",
        "КОНЦЕРТ": "Певцы и музыканты играют перед зрителями",
        "ЧУЖОЙ": "Фильм о команде в космосе и опасном чудовище",
        "СПАРТАК": "Балет о рабе, который поднял бунт против Рима",
        "ОЧЕНЬ СТРАННЫЕ ДЕЛА": "Сериал о детях, тайных опытах и страшном другом мире",
        "ПРОДОЛЖЕНИЕ": "Новая часть истории, которая идёт после первой",
        "НОВАЯ ВЕРСИЯ": "Старый фильм или песня, сделанные заново",
        "МИНИ-СЕРИАЛ": "Сериал, в котором всего несколько серий",
        "ЖИВОЙ АЛЬБОМ": "Запись песен, которые играли перед зрителями",
        "ВО ВСЕ ТЯЖКИЕ": "Сериал об учителе химии, который начал делать наркотики",
        "ОДНИ ИЗ НАС": "Двое людей идут через мир после страшной болезни",
        "БРАТ": "Фильм о бывшем солдате, который попал в мир бандитов",
    },
    "en": {
        "YOGA": "Exercise with body poses, slow breathing, and calm focus",
        "THERMAL CAMERA": "A camera that shows warm and cold areas",
        "BLACK MIRROR": "A series about technology causing dark and strange problems",
    },
}


# Replace specialist terms that can hide inside an otherwise short sentence.
EVERYDAY_HINTS: dict[str, dict[str, str]] = {
    "ru": {
        "ДВИГАТЕЛЬ": "Часть машины, которая даёт ей силу для движения",
        "РАКЕТА": "Летает в небо или космос за счёт мощной струи газа",
        "КОМПЬЮТЕР": "Машина для игр, программ и работы с данными",
        "ТЕЛЕФОН": "Позволяет людям говорить друг с другом на расстоянии",
        "ИНТЕРНЕТ": "Сеть, которая связывает людей и технику по всему миру",
        "СЕРВЕР": "Компьютер, который хранит файлы и даёт к ним доступ",
        "УМНЫЙ ДОМ": "Дом, где свет, тепло и замки могут работать сами",
        "ПРОДЮСЕР": "Человек, который собирает команду и деньги для фильма",
        "ОПЕРАТОР": "Человек, который снимает фильм или передачу на камеру",
        "ФОТОГРАФ": "Человек, который делает снимки камерой",
        "РЕДАКТОР": "Человек, который ищет и правит ошибки в тексте",
        "ИНЖЕНЕР": "Человек, который создаёт машины, здания и другие полезные вещи",
        "КАМЕРА": "На съёмках она записывает всё, что видит через объектив",
    },
    "en": {
        "HORSE RACING": "A sport where riders race horses around a track",
        "SWIMMING": "Moving through water with the arms and legs",
        "WARM-UP": "Easy moves that get the body ready for exercise",
        "COOL-DOWN": "Easy moves after exercise that help the body rest",
        "TURKEY": "A country between Europe and Asia, home to Istanbul",
        "SOLAR PANEL": "A flat panel that turns sunlight into electric power",
        "SMART HOME": "A home where lights, heat, and locks can work by themselves",
        "BOX TRUCK": "A truck with a large closed box for carrying goods",
        "ENGINE": "A machine that turns fuel or power into movement",
        "STEPHEN KING": "A famous writer of horror and fantasy books",
        "FILM EDITOR": "A person who joins filmed shots into the final movie",
        "PRODUCER": "A person who finds money and a team for a media project",
        "HEAD CHEF": "The cook who leads a kitchen and plans its menu",
        "BARBER": "A person who cuts and shapes hair and beards",
        "CHEF KNIFE": "A wide kitchen knife used for many cutting jobs",
        "GENE": "A piece of DNA that helps decide a body trait",
        "GENE THERAPY": "A treatment that changes genes to help fight disease",
        "AMBASSADOR": "A person who speaks for one country in another country",
        "INVASION": "When an army enters another land by force",
        "CHOCOLATE": "A sweet food made from roasted cacao beans",
        "FREEDOM": "Being able to live and act without unfair limits",
        "TREND": "Something that becomes popular for a time",
        "PASSPORT": "A travel booklet that proves who you are and your country",
        "MESSENGER": "An app for messages, calls, photos, and videos",
        "BLACK MIRROR": "A dark series about how new tech can harm people",
        "STOP MOTION": "Animation made by moving real objects a little between photos",
        "HEAT": "A crime film about a police officer chasing a skilled robber",
    },
}


COMPLEX_VOCABULARY_ROOTS: dict[str, tuple[str, ...]] = {
    "ru": (
        "специалист",
        "устройств",
        "совокуп",
        "деятельност",
        "учрежден",
        "организац",
        "производств",
        "функц",
        "механическ",
        "техническ",
        "автоматич",
        "промышлен",
        "физическ",
        "философ",
        "проект",
        "систем",
        "аппарат",
        "равновес",
        "оборон",
        "электрон",
        "обработк",
        "отображен",
    ),
    "en": (
        "professional",
        "technique",
        "technology",
        "mechanical",
        "physical",
        "consequence",
        "networked",
        "recreational",
        "intrusion",
        "encroachment",
        "liberation",
        "deliverance",
        "confinement",
        "bondage",
        "envoy",
        "diplomat",
        "inherited",
        "instruction",
        "application",
        "behaviour",
        "associated",
        "temperature",
        "difference",
        "converted",
        "electricity",
        "versatile",
        "preparation",
        "gradually",
        "recovery",
        "rectangular",
        "contemporary",
        "destination",
        "organized",
        "official",
        "systematically",
        "microorganism",
        "unspecialised",
        "identification",
        "anthology",
    ),
}


def tokens(text: str) -> list[str]:
    return re.findall(r"[a-zа-яё0-9]+", text.lower())


def normalized(text: str) -> str:
    return " ".join(tokens(text))


def load_rows(language: str) -> tuple[dict, dict, list[tuple[str, int, str, float]]]:
    words_path = ROOT / "data" / f"words_{language}.json"
    hints_path = ROOT / "data" / f"hints_{language}.json"
    words_data = json.loads(words_path.read_text(encoding="utf-8-sig"))
    hints_data = json.loads(hints_path.read_text(encoding="utf-8-sig"))
    hint_themes = hints_data.get("themes", [])
    rows: list[tuple[str, int, str, float]] = []

    if language == "ru":
        theme_items = list(words_data["words"].items())
    else:
        theme_items = [(theme["type"], theme["words"]) for theme in words_data["themes"]]

    if len(theme_items) != len(hint_themes):
        raise ValueError(f"{language}: word and hint theme counts differ")
    for theme_index, (theme_name, words) in enumerate(theme_items):
        difficulties = words_data["difficulty"][theme_name]
        hints = hint_themes[theme_index]
        if len(words) != len(difficulties) or len(words) != len(hints):
            raise ValueError(f"{language}/{theme_name}: word, difficulty, and hint counts differ")
        for word_index, (word, difficulty) in enumerate(zip(words, difficulties)):
            rows.append((theme_name, word_index, word, float(difficulty)))
    return words_data, hints_data, rows


def rebalance_language(language: str, apply_changes: bool) -> tuple[int, int]:
    _, hints_data, rows = load_rows(language)
    hints = hints_data["themes"]
    manual = {
        **MANUAL_HINTS[language],
        **PLAIN_HINTS[language],
        **VERY_PLAIN_HINTS[language],
        **EVERYDAY_HINTS[language],
    }
    seen_manual: set[str] = set()
    changed = 0

    theme_index_by_name: dict[str, int] = {}
    for theme_name, _, _, _ in rows:
        if theme_name not in theme_index_by_name:
            theme_index_by_name[theme_name] = len(theme_index_by_name)

    for theme_name, word_index, word, difficulty in rows:
        theme_index = theme_index_by_name[theme_name]
        hint = str(hints[theme_index][word_index]).strip()
        manual_key = word.upper()
        replacement = manual.get(manual_key)
        if replacement is not None:
            seen_manual.add(manual_key)
            expected = replacement
        else:
            expected = hint

        if hint != expected:
            changed += 1
            if apply_changes:
                hints[theme_index][word_index] = expected

    missing_manual = set(manual) - seen_manual
    if missing_manual:
        raise ValueError(f"{language}: manual hints reference missing words: {sorted(missing_manual)}")

    if apply_changes and changed:
        hints_path = ROOT / "data" / f"hints_{language}.json"
        text = "\ufeff" + json.dumps(hints_data, ensure_ascii=False, indent=2) + "\n"
        hints_path.write_text(text, encoding="utf-8")

    # Reload current data for validation after applying changes.
    _, current_hints_data, current_rows = load_rows(language)
    current_hints = current_hints_data["themes"]
    theme_index_by_name.clear()
    for theme_name, _, _, _ in current_rows:
        if theme_name not in theme_index_by_name:
            theme_index_by_name[theme_name] = len(theme_index_by_name)

    hard_answer_leaks = 0
    hard_component_leaks = 0
    weak_easy_hints = 0
    mechanical_hint_leaks = 0
    very_easy_readability_issues = 0
    for theme_name, word_index, word, difficulty in current_rows:
        hint = str(current_hints[theme_index_by_name[theme_name]][word_index]).strip()
        if not hint:
            raise ValueError(f"{language}/{theme_name}/{word}: empty hint")
        if not 0.0 <= difficulty <= 1.0:
            raise ValueError(f"{language}/{theme_name}/{word}: difficulty is outside [0, 1]")
        if difficulty <= EASY_MAX_DIFFICULTY and len(tokens(hint)) < MIN_EASY_HINT_TOKENS:
            weak_easy_hints += 1
        if (
            ("Начинается с «" in hint and "длина —" in hint)
            or ("Starts with “" in hint and "letters." in hint)
        ):
            mechanical_hint_leaks += 1
        hint_tokens = tokens(hint)
        if difficulty <= VERY_EASY_MAX_DIFFICULTY and (
            len(hint_tokens) > MAX_VERY_EASY_HINT_TOKENS
            or any(len(token) > MAX_VERY_EASY_TOKEN_LENGTH for token in hint_tokens)
            or (
                sum(len(token) for token in hint_tokens) / float(len(hint_tokens))
                > MAX_VERY_EASY_AVERAGE_TOKEN_LENGTH
            )
            or any(
                token.startswith(root)
                for token in hint_tokens
                for root in COMPLEX_VOCABULARY_ROOTS[language]
            )
        ):
            very_easy_readability_issues += 1
        if difficulty > EASY_MAX_DIFFICULTY and normalized(word) in normalized(hint):
            hard_answer_leaks += 1
        answer_parts = [part for part in tokens(word) if len(part) >= 4 and part != "the"]
        hint_parts = set(tokens(hint))
        if (
            difficulty > EASY_MAX_DIFFICULTY
            and len(answer_parts) >= 2
            and all(part in hint_parts for part in answer_parts)
        ):
            hard_component_leaks += 1

    if weak_easy_hints:
        raise ValueError(f"{language}: {weak_easy_hints} easy hints remain too short")
    if mechanical_hint_leaks:
        raise ValueError(f"{language}: {mechanical_hint_leaks} hints duplicate letter or length mechanics")
    if very_easy_readability_issues:
        raise ValueError(
            f"{language}: {very_easy_readability_issues} very easy hints use wording that is too complex"
        )
    if hard_answer_leaks:
        raise ValueError(f"{language}: {hard_answer_leaks} hard hints contain the complete answer")
    if hard_component_leaks:
        raise ValueError(f"{language}: {hard_component_leaks} hard hints repeat every answer component")
    return len(current_rows), changed


def main() -> None:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true", help="rewrite hint datasets")
    mode.add_argument("--check", action="store_true", help="validate datasets without rewriting")
    args = parser.parse_args()

    total = 0
    changed = 0
    for language in ("ru", "en"):
        language_total, language_changed = rebalance_language(language, args.apply)
        total += language_total
        changed += language_changed
    if args.check and changed:
        raise SystemExit(f"Hint datasets need rebalancing: {changed} pending changes")
    print(f"Validated {total} semantic hints; changed {changed}")


if __name__ == "__main__":
    main()
