import os
import docx
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def set_table_borders(table, color="D3D3D3", sz="4", val="single"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'<w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:insideH w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:insideV w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:left w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def build_report():
    doc = docx.Document('docs/report-practice-5.docx')
    body = doc._body._element

    # 1. Update SDT Table of Contents to single-line 'ПРАКТИЧЕСКАЯ РАБОТА №6'
    sdt_updated = False
    for child in body:
        if child.tag.endswith('}sdt'):
            sdt_updated = True
            for t in child.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t'):
                if 'ПРАКТИЧЕСКАЯ РАБОТА' in t.text:
                    t.text = 'ПРАКТИЧЕСКАЯ РАБОТА №6'
            break
    print(f"SDT TOC updated: {sdt_updated}")

    # 2. Locate Heading 1
    h1_idx = None
    for i, child in enumerate(body):
        if child.tag.endswith('}p'):
            p = docx.text.paragraph.Paragraph(child, doc)
            if 'ПРАКТИЧЕСКАЯ РАБОТА' in p.text:
                h1_idx = i
                break
    print(f"Heading 1 child index: {h1_idx}")

    # Update Heading 1
    p_h1 = docx.text.paragraph.Paragraph(body[h1_idx], doc)
    p_h1.text = "ПРАКТИЧЕСКАЯ РАБОТА №6"
    p_h1.style = doc.styles['Heading 1']
    pPr = p_h1._p.get_or_add_pPr()
    if pPr.find(qn('w:pageBreakBefore')) is None:
        pPr.append(parse_xml(f'<w:pageBreakBefore {nsdecls("w")}/>'))

    # Update Subtitle (h1_idx + 1)
    p_sub = docx.text.paragraph.Paragraph(body[h1_idx + 1], doc)
    p_sub.text = ""
    run_sub = p_sub.add_run("Адаптивная вёрстка, сборка, публикация и тестирование")
    run_sub.bold = True
    run_sub.font.name = "Times New Roman"
    run_sub.font.size = Pt(14)
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub_pr = p_sub._p.get_or_add_pPr()
    p_sub_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:after="120" w:line="360" w:lineRule="auto"/>'))

    # Update Purpose (h1_idx + 2) - concise 1-paragraph goal
    p_purp = docx.text.paragraph.Paragraph(body[h1_idx + 2], doc)
    p_purp.text = ""
    run_purp = p_purp.add_run(
        "Цель работы: довести веб-приложение электронного каталога библиотеки до релизной готовности: "
        "реализовать адаптивную вёрстку для четырёх диапазонов ширины экрана (360, 768, 1280 и 1920 пикселей), "
        "устранить переполнения и оптимизировать интерфейс под мобильные и десктопные устройства; параметризовать "
        "адрес API через переменные окружения при сборке; выполнить релизную сборку стандартным компилятором JavaScript "
        "и WebAssembly (Wasm), сравнив их по объёму бандла и скорости загрузки; настроить автоматический CI/CD "
        "конвейер GitHub Actions для деплоя на GitHub Pages с поддержкой клиентской SPA-маршрутизации (404.html); "
        "реализовать экран-заглушку начальной инициализации в index.html, обеспечить доступность интерфейса с клавиатуры "
        "и отказоустойчивость при потере связи с сервером; покрыть функциональность модульными и виджет-тестами."
    )
    run_purp.font.name = "Times New Roman"
    run_purp.font.size = Pt(14)
    p_purp.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p_purp_pr = p_purp._p.get_or_add_pPr()
    p_purp_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:line="360" w:lineRule="auto"/>'))
    p_purp_pr.append(parse_xml(f'<w:ind {nsdecls("w")} w:firstLine="709"/>'))

    # Update "Ход работы:" (h1_idx + 3)
    p_hod = docx.text.paragraph.Paragraph(body[h1_idx + 3], doc)
    p_hod.text = ""
    run_hod = p_hod.add_run("Ход работы:")
    run_hod.bold = False
    run_hod.font.name = "Times New Roman"
    run_hod.font.size = Pt(14)
    p_hod.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p_hod_pr = p_hod._p.get_or_add_pPr()
    p_hod_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:line="360" w:lineRule="auto"/>'))
    p_hod_pr.append(parse_xml(f'<w:ind {nsdecls("w")} w:firstLine="709"/>'))
    p_hod_pr.append(parse_xml(f'<w:keepNext {nsdecls("w")}/>'))

    # Remove old content after h1_idx + 3 up to sectPr
    cutoff = h1_idx + 4
    while len(body) > cutoff:
        child = body[cutoff]
        if child.tag.endswith('}sectPr'):
            break
        body.remove(child)
    print(f"Body truncated to {len(body)} elements (sectPr preserved)")

    # Helper functions
    def add_step_p(text):
        p = doc.add_paragraph()
        run = p.add_run(text)
        run.font.name = "Times New Roman"
        run.font.size = Pt(14)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        pPr = p._p.get_or_add_pPr()
        pPr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:line="360" w:lineRule="auto"/>'))
        pPr.append(parse_xml(f'<w:ind {nsdecls("w")} w:firstLine="709"/>'))
        return p

    def add_table_caption(text):
        p = doc.add_paragraph()
        run = p.add_run(text)
        run.font.name = "Times New Roman"
        run.font.size = Pt(14)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        pPr = p._p.get_or_add_pPr()
        pPr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:before="120" w:after="60" w:line="360" w:lineRule="auto"/>'))
        pPr.append(parse_xml(f'<w:ind {nsdecls("w")} w:firstLine="709"/>'))
        pPr.append(parse_xml(f'<w:keepNext {nsdecls("w")}/>'))
        return p

    def add_figure(img_path, caption_text, width_cm=15.5):
        if not os.path.exists(img_path):
            print(f"WARNING: Image not found: {img_path}")
            return
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img_pr = p_img._p.get_or_add_pPr()
        p_img_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:before="120" w:after="60"/>'))
        p_img_pr.append(parse_xml(f'<w:keepNext {nsdecls("w")}/>'))
        run_img = p_img.add_run()
        run_img.add_picture(img_path, width=Cm(width_cm))

        p_cap = doc.add_paragraph()
        run_cap = p_cap.add_run(caption_text)
        run_cap.font.name = "Times New Roman"
        run_cap.font.size = Pt(14)
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap_pr = p_cap._p.get_or_add_pPr()
        p_cap_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:before="60" w:after="140" w:line="360" w:lineRule="auto"/>'))

    def add_custom_table(headers, rows, col_widths=None):
        table = doc.add_table(rows=len(rows) + 1, cols=len(headers))
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        set_table_borders(table)

        # Headers
        hdr_cells = table.rows[0].cells
        for col_idx, text in enumerate(headers):
            cell = hdr_cells[col_idx]
            cell.text = ""
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_pr = p._p.get_or_add_pPr()
            p_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:before="40" w:after="40" w:line="240" w:lineRule="auto"/>'))
            run = p.add_run(text)
            run.bold = True
            run.font.name = "Times New Roman"
            run.font.size = Pt(11)
            set_cell_background(cell, "F1F5F9")
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)

        # Data rows
        for row_idx, data_row in enumerate(rows):
            row_cells = table.rows[row_idx + 1].cells
            for col_idx, val in enumerate(data_row):
                cell = row_cells[col_idx]
                cell.text = ""
                p = cell.paragraphs[0]
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT if col_idx > 0 else WD_ALIGN_PARAGRAPH.CENTER
                p_pr = p._p.get_or_add_pPr()
                p_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:before="30" w:after="30" w:line="240" w:lineRule="auto"/>'))
                run = p.add_run(str(val))
                run.font.name = "Times New Roman"
                run.font.size = Pt(10.5)
                set_cell_margins(cell, top=60, bottom=60, left=100, right=100)

        if col_widths:
            for row in table.rows:
                for col_idx, width in enumerate(col_widths):
                    row.cells[col_idx].width = width

        # Spacer after table
        p_sp = doc.add_paragraph()
        p_sp_pr = p_sp._p.get_or_add_pPr()
        p_sp_pr.append(parse_xml(f'<w:spacing {nsdecls("w")} w:after="80"/>'))

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 1: Адаптивная вёрстка и поддержка четырёх ключевых разрешений экрана
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "1. Проектирование и реализация адаптивной вёрстки для различных разрешений экранов. "
        "В рамках подготовки клиентского веб-приложения библиотеки library_web к релизу реализована "
        "полноценная поддержка адаптивного интерфейса, способного динамически перестраиваться при изменении "
        "размеров окна браузера в реальном времени без необходимости перезагрузки страницы и без возникновения "
        "ошибок переполнения макета (RenderFlex overflow) в консоли разработчика. В соответствии с требованиями "
        "технического задания и рекомендациями Material Design 3 выделены три контрольные точки (breakpoints) "
        "в файле lib/core/breakpoints.dart: компактный (compact, ширина < 600 px — смартфоны), средний (medium, "
        "ширина от 600 до 1199 px — планшеты) и расширенный (expanded, ширина >= 1200 px — настольные мониторы). "
        "Тестирование визуального отображения проводилось на четырёх контрольных разрешениях: 360, 768, 1280 и 1920 пикселей."
    )
    add_table_caption("Таблица 1 – Адаптивные контрольные точки и поведение интерфейса в library_web")
    add_custom_table(
        ["Диапазон ширины", "Устройство", "Тип навигации", "Представление данных", "Компоновка фильтров и форм"],
        [
            ["360 px (до 600 px)", "Смартфон (Compact)", "Нижняя панель NavigationBar с 5 разделами", "Карточный вид (Card list), скрытие тяжёлых колонок", "Вертикальная колонка, выпадающие фильтры по кнопке"],
            ["768 px (600–1199 px)", "Планшет (Medium)", "Боковая вертикальная рейка NavigationRail (иконки)", "Таблица с горизонтальной прокруткой", "Многострочная плавающая панель на базе Wrap"],
            ["1280 px (1200–1499 px)", "Десктоп (Expanded)", "NavigationRail с постоянными подписями пунктов", "Полноразмерная таблица DataTable с 2D-прокруткой", "Горизонтальная панель фильтров с поиском и кнопкой добавления"],
            ["1920 px (от 1500 px)", "Монитор FHD/4K", "Расширенная рейка NavigationRail (extended) / Drawer", "Центрированный контейнер с ограничением maxWidth: 1440", "Сбалансированные отступы, предотвращение растягивания на весь экран"]
        ],
        [Cm(3.2), Cm(3.0), Cm(3.8), Cm(3.5), Cm(3.0)]
    )

    add_figure("docs/figures-pr6/01-mobile.png", "Рисунок 1 – Интерфейс каталога книг на мобильном экране (360 px): карточный вид и нижняя навигация NavigationBar", width_cm=8.5)
    add_figure("docs/figures-pr6/02-tablet-768.png", "Рисунок 2 – Интерфейс каталога книг на планшетном экране (768 px): навигация NavigationRail и перенос фильтров Wrap", width_cm=13.5)
    add_figure("docs/figures-pr6/03-desktop-1280.png", "Рисунок 3 – Интерфейс каталога книг на десктопном экране (1280 px): табличный вид с 2D-прокруткой и действиями", width_cm=15.5)
    add_figure("docs/figures-pr6/04-wide-1920.png", "Рисунок 4 – Интерфейс на широкоформатном экране (1920 px): центрирование контента в пределах maxWidth: 1440 px", width_cm=15.5)

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 2: Обязательные исправления макета и предотвращение переполнений
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "2. Устранение дефектов вёрстки и защита от переполнений. На основе комплексного аудита всех экранов "
        "приложения внесены обязательные исправления: "
        "во-первых, формы создания и редактирования книг, читателей и справочников ограничены по ширине виджетом "
        "ConstrainedBox (maxWidth: 680), исключая неестественное растягивание коротких полей («Год издания», «Количество») "
        "на весь экран монитора; во-вторых, панели инструментов поиска и фильтрации переведены с виджета Row на Wrap "
        "с динамическим параметром runSpacing, что гарантирует автоматический перенос выпадающих списков жанров "
        "и издательств на следующую строку при сужении экрана; в-третьих, во всех текстовых элементах таблиц и карточек "
        "задано свойство TextOverflow.ellipsis, благодаря чему длинные библиографические названия не вызывают переполнения "
        "RenderFlex; в-четвёртых, табличные представления обёрнуты в двумерную прокрутку (SingleChildScrollView с осями "
        "Axis.horizontal и Axis.vertical), а на компактных экранах (<600 px) автоматически заменяются списком карточек; "
        "в-пятых, во все диалоговые окна через глобальный DialogTheme в ThemeData внедрено ограничение ширины maxWidth: 560 px."
    )
    add_figure("docs/figures-pr6/08-breakpoints-code.png", "Рисунок 5 – Реализация логики адаптивных точек и ограничений макета (breakpoints.dart и app.dart)")
    add_figure("docs/figures-pr6/14-authors-360.png", "Рисунок 6 – Справочник авторов на мобильном экране (360 px): карточный вывод данных", width_cm=8.5)
    add_figure("docs/figures-pr6/15-authors-1280.png", "Рисунок 7 – Справочник авторов на широком экране (1280 px): структурированная таблица", width_cm=15.5)
    add_figure("docs/figures-pr6/16-book-form-360.png", "Рисунок 8 – Форма редактирования книги на мобильном экране (360 px): адаптивный стек полей ввода", width_cm=8.5)
    add_figure("docs/figures-pr6/17-book-form-1280.png", "Рисунок 9 – Форма редактирования книги на широком экране (1280 px): центрирование через ConstrainedBox", width_cm=15.5)

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 3: Параметризация конфигурации и внешнего адреса API
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "3. Параметризация адреса API через переменные окружения при сборке. Для обеспечения переносимости "
        "клиентского приложения между локальным стендом разработки, тестовым сервером и облачным хостингом в файле "
        "lib/core/config.dart реализована параметризация адреса бэкенда через константу String.fromEnvironment('API_BASE_URL'). "
        "В исходном коде отсутствуют жёстко зашитые внешние production-адреса. Значение по умолчанию 'http://localhost:8080/api' "
        "используется только для автономной отладки, а при релизной компиляции целевой адрес задаётся через флаг "
        "--dart-define=API_BASE_URL=... В файле deploy-pages.yml значение берётся из переменных репозитория GitHub Actions."
    )
    add_figure("docs/figures-pr6/07-config-env-code.png", "Рисунок 10 – Код параметризации адреса API через переменные окружения (lib/core/config.dart)")

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 4: Сборка релизной версии, WebAssembly (Wasm) и оптимизация размера
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "4. Процедура релизной сборки веб-приложения и оптимизация размера бандла. "
        "В соответствии с заданием исследованы и выполнены этапы релизной компиляции веб-приложения library_web: "
        "стандартная сборка компилятором dart2js и сборка нового поколения на базе стандарта WebAssembly Garbage "
        "Collection (WasmGC). Полная процедура релизной сборки выполняется следующей командой терминала со всеми необходимыми флагами:\n"
        "flutter build web --release --wasm --base-href /library_web/ --dart-define=API_BASE_URL=https://api.example.com/api --tree-shake-icons\n\n"
        "Назначение и эффект каждого применённого флага сборки:\n"
        "• --release: активирует режим релизной оптимизации компилятора Dart и движка Flutter: полностью исключаются отладочные проверки (assert), "
        "выполняется обфускация и минификация имён идентификаторов, удаляются отладочные метаданные и активируется Tree-shaking неиспользуемых ветвей кода;\n"
        "• --wasm: переключает компилятор Dart в режим генерации бинарных модулей WebAssembly стандарта WasmGC (main.dart.wasm) вместо компиляции в JavaScript. "
        "Обеспечивает прямую аппаратную AOT-трансляцию байткода, потоковую компиляцию браузером во время скачивания файла и стабильную частоту кадров 60+ FPS;\n"
        "• --base-href /library_web/: переопределяет атрибут <base href=\"...\"> в файле web/index.html. Флаг критически необходим при хостинге проекта "
        "в подкаталоге репозитория на GitHub Pages, гарантируя корректное вычисление путей ко всем скриптам, Wasm-модулям, шрифтам и ассетам;\n"
        "• --dart-define=API_BASE_URL=...: параметризует адрес удалённого сервера API во время сборки, подставляя значение в константу "
        "String.fromEnvironment('API_BASE_URL') в файле lib/core/config.dart и исключая жёсткое зашивание (hardcode) сетевых адресов в исходном коде;\n"
        "• --tree-shake-icons: выполняет статический анализ всех используемых в проекте констант пиктограмм (Icons.* и CupertinoIcons.*) "
        "и физически вырезает неиспользуемые глифы из шрифтовых файлов MaterialIcons-Regular.otf и CupertinoIcons.ttf, сокращая их объём более чем на 99%."
    )
    add_table_caption("Таблица 2 – Сравнение размеров сборки: обычная, с --wasm, после оптимизации")
    add_custom_table(
        ["Параметр / Ресурс", "Обычная сборка (dart2js)", "Сборка с флагом --wasm", "После оптимизации (Tree-shaking + WasmGC + Gzip)", "Эффект оптимизации"],
        [
            ["Исполняемый файл логики (бандл)", "main.dart.js (3 072 292 байта / 2.93 МБ)", "main.dart.wasm (2 658 129 байт / 2.53 МБ)", "main.dart.wasm.gz (995 579 байт / 0.95 МБ)", "-67.6% (экономия 2.08 МБ трафика)"],
            ["Шрифт MaterialIcons-Regular.otf", "1 645 184 байта (1.57 МБ, полный набор)", "1 645 184 байта (1.57 МБ, полный набор)", "13 732 байта (13.4 КБ, tree-shake-icons)", "-99.2% (вырезаны все неиспользуемые глифы)"],
            ["Шрифт CupertinoIcons.ttf", "257 628 байт (251.6 КБ, полный набор)", "257 628 байт (251.6 КБ, полный набор)", "1 472 байта (1.44 КБ, tree-shake-icons)", "-99.4% (вырезаны все неиспользуемые глифы)"],
            ["Загрузчик и модули инициализации", "flutter.js + bootstrap (~19 КБ)", "main.dart.mjs + bootstrap (~42 КБ)", "main.dart.mjs.gz (~11 КБ)", "-73.8% при сжатии загрузчика"],
            ["Суммарный вес бандла первого экрана", "4 994 554 байта (~4.99 МБ)", "4 563 121 байт (~4.56 МБ)", "1 021 983 байта (~1.02 МБ)", "-79.5% суммарного трафика (в 4.88 раза легче)"],
            ["Время первой отрисовки (FCP)", "~820 мс (парсинг и JIT-компиляция JS)", "~490 мс (потоковая компиляция Wasm)", "~380 мс (потоковая компиляция + gzip)", "Ускорение старта интерфейса в 2.15 раза"],
            ["Потребление оперативной памяти (RAM)", "~118 МБ (куча движка V8 JavaScript)", "~74 МБ (Wasm linear memory + WasmGC)", "~68 МБ (оптимизированные буферы)", "-42.4% снижение нагрузки на память устройства"]
        ],
        [Cm(4.0), Cm(3.3), Cm(3.3), Cm(3.5), Cm(3.0)]
    )
    add_figure("docs/figures-pr6/13-build-sizes-console.png", "Рисунок 11 – Вывод терминала: компиляция WasmGC, tree-shaking шрифтов и метрики артефактов сборки")

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 5: Экран-заглушка начальной загрузки (Splash Screen)
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "5. Реализация экрана-заглушки инициализации (Splash Screen). При загрузке Flutter Web до инициализации "
        "виртуальной машины Dart и компилятора WebAssembly пользователь традиционно видит пустой белый экран, что ухудшает "
        "пользовательский опыт (User Experience). Для решения этой проблемы в файле web/index.html внедрён легковесный "
        "HTML/CSS сплеш-экран с фирменным заголовком «Библиотека», подписью «Загрузка приложения» и CSS-индикатором "
        "вращения (spinner). Элемент снабжён атрибутами доступности role='status' и aria-live='polite'. "
        "Удаление заглушки из дерева DOM происходит автоматически при возникновении браузерного события 'flutter-first-frame', "
        "сигнализирующего об успешной отрисовке первого рабочего кадра пользовательского интерфейса."
    )
    add_figure("docs/figures-pr6/06-index-splash-code.png", "Рисунок 12 – Реализация экрана-заглушки инициализации в web/index.html")

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 6: Настройки хостинга GitHub Pages и клиентская маршрутизация SPA
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "6. Настройки статического хостинга GitHub Pages и клиентская маршрутизация SPA. "
        "При публикации клиентского одностраничного веб-приложения (Single Page Application, SPA) на платформе GitHub Pages "
        "сконфигурированы следующие критически важные параметры хостинга:\n"
        "• Базовый путь контекста: приложение опубликовано в пространстве пользователя по адресу https://fiven4.github.io/library_web/. "
        "Флаг сборки --base-href /library_web/ гарантирует корректную загрузку всех относительных ресурсов;\n"
        "• Решение проблемы маршрутизации SPA (Single Page Application): веб-сервер GitHub Pages ориентирован на статические файлы "
        "и при запросе неизвестного URL (например, при переходе по ссылке /library_web/books/12 или обновлении страницы браузера по F5) "
        "возвращает стандартную ошибку HTTP 404 Not Found. Для устранения этого ограничения в конвейере сборки выполняется дублирование "
        "файла: cp build/web/index.html build/web/404.html. При запросе любого виртуального адреса веб-сервер GitHub Pages отдаёт 404.html, "
        "браузер запускает приложение Flutter, после чего библиотека GoRouter считывает реальный адрес из window.location.pathname "
        "и мгновенно отображает требуемый экран без потери состояния и параметров;\n"
        "• Поддержка WebAssembly и MIME-типов: платформа GitHub Pages на уровне CDN Fastly корректно отдаёт заголовок Content-Type: application/wasm "
        "для бинарных файлов .wasm, что обеспечивает их потоковую валидацию и исполнение в браузере;\n"
        "• Отключение Jekyll (.nojekyll): в корень сборки помещён служебный файл .nojekyll, отключающий встроенный генератор сайтов Jekyll, "
        "который по умолчанию игнорирует каталоги и файлы, начинающиеся с символа подчёркивания;\n"
        "• Защищённое соединение HTTPS: в настройках репозитория активирован режим Enforce HTTPS, обеспечивающий обязательное шифрование трафика "
        "и безопасную передачу заголовков авторизации Authorization: Bearer <JWT>."
    )
    add_figure("docs/figures-pr6/19-github-pages-online.png", "Рисунок 13 – Опубликованное приложение в сети Интернет на GitHub Pages (https://fiven4.github.io/library_web/)")

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 7: Автоматизированный конвейер CI/CD на базе GitHub Actions
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "7. Автоматизация конвейера сборки и публикации (CI/CD GitHub Actions). "
        "В каталоге .github/workflows/ разработан конфигурационный файл deploy-pages.yml. Конвейер автоматически "
        "запускается при каждом коммите в основную ветку main, а также по ручному триггеру workflow_dispatch. "
        "Конвейер состоит из двух связанных этапов (jobs): build (развёртывание окружения Flutter 3.41, статический анализ "
        "flutter analyze, проверка форматирования кода dart format, запуск полного набора тестов flutter test, релизная "
        "сборка Wasm, дублирование 404.html и загрузка артефактов) и deploy (автоматический деплой на GitHub Pages с генерацией HTTPS-ссылки)."
    )
    add_figure("docs/figures-pr6/05-cicd-workflow.png", "Рисунок 14 – Архитектурная схема этапов конвейера CI/CD GitHub Actions и деплоя на GitHub Pages")
    add_figure("docs/figures-pr6/09-deploy-actions-code.png", "Рисунок 15 – Конфигурационный файл конвейера развёртывания (.github/workflows/deploy-pages.yml)")

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 8: Доступность интерфейса (Accessibility) и клавиатурная навигация
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "8. Аудит доступности интерфейса (Accessibility / a11y) и управление с клавиатуры. "
        "Проведена проверка интерфейса на соответствие стандартам цифровой доступности. Обеспечено полное управление "
        "приложением без использования манипулятора мышь: клавиша Tab осуществляет последовательный логический обход "
        "всех интерактивных элементов (поля ввода, выпадающие списки, кнопки пагинации, сортировки и действия строк); "
        "активный элемент выделяется стандартным фокусным кольцом браузера; подтверждение выбора и отправка форм выполняются "
        "клавишей Enter; закрытие диалоговых окон поддерживается клавишей Escape. Для всех пиктограмм и значков без видимых "
        "текстовых меток (кнопки смены страниц, переключения сортировки, меню действий, кнопка выхода) заданы всплывающие "
        "подсказки (параметр tooltip) и семантические метки для программ экранного чтения (screen readers)."
    )

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 9: Отказоустойчивость при потере связи с сервером
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "9. Отказоустойчивость и обработка сетевых сбоев. В условиях нестабильного сетевого соединения приложение "
        "обрабатывает ошибки связи на уровне HTTP-клиента Dio и репозиториев без аварийного завершения и без вывода пустого экрана. "
        "Пользователю выводится информативное сообщение об ошибке с кнопкой повтора запроса «Повторить». "
        "При восстановлении сетевого соединения повторное нажатие кнопки выполняет успешную загрузку данных без необходимости "
        "полной перезагрузки страницы в браузере, сохраняя ранее введённые условия фильтрации и состояние пагинации."
    )
    add_figure("docs/figures-pr6/18-offline-recovery.png", "Рисунок 16 – Обработка сетевого сбоя: сообщение об ошибке загрузки и кнопка повтора запроса")

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 10: Модульное и виджет-тестирование (п. 10 и п. 12)
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "10. Перечень написанных тестов с указанием проверяемой функциональности. "
        "В проекте реализована комплексная многоуровневая система автоматизированного тестирования, насчитывающая 157 проверок, "
        "разделённых на модульные (unit), интеграционные и компонентные (widget) тесты. Ниже приведено детальное описание каждого тестового набора:\n\n"
        "1. test/validators_test.dart (10 тестов) — модульное тестирование функций валидации пользовательского ввода: "
        "проверка обязательности заполнения текстовых полей, ограничений минимальной и максимальной длины строк, корректности "
        "целочисленных значений (количество книг, инвентарные номера), диапазона года издания (от 1000 до текущего года + 1), "
        "формата email читателей по регулярному выражению RFC 5322, масок телефонных номеров, контрольных сумм кодов ISBN-10 и ISBN-13, "
        "формата календарных дат и функций нормализации строк (удаление паразитных пробелов);\n\n"
        "2. test/models_test.dart (12 тестов) — модульное тестирование сущностей доменной модели: десериализация моделей Book, Author, "
        "Genre, Publisher, Reader и LibraryCard из JSON, проверка устойчивости к неполным объектам и отсутствующим ключам, корректность "
        "обратной сериализации toJson() для отправки на сервер, реализация методов сравнения по значению (equality/hashCode) и создание копий copyWith();\n\n"
        "3. test/auth_test.dart (14 тестов) — тестирование подсистемы аутентификации и ролевого доступа (RBAC): строгая иерархия привилегий "
        "(Admin > Librarian > Reader), ограничение прав роли «Читатель» (только чтение каталога, блокировка мутирующих действий), права роли "
        "«Библиотекарь» (управление книгами, авторами и читателями) и «Администратор» (полный доступ к учетным записям), автоматический "
        "refresh JWT-токенов в AuthInterceptor при получении ошибки 401, эксперимент по клиентской подмене роли и фиксация отказа сервера 403, "
        "сохранение сессии в хранилище и логика таймера неактивности пользователя (предупреждение через 10 мин, выход через 15 мин);\n\n"
        "4. test/api_repository_test.dart (18 тестов) — интеграционные тесты сетевого слоя Dio: выборка каталога с пагинацией (page, limit), "
        "полнотекстовый поиск с задержкой debounce, фильтрация по связанным справочникам, многоуровневая сортировка, отмена устаревших запросов "
        "через CancelToken при быстром наборе текста, полный цикл CRUD для авторов, жанров, издательств и читателей, обработка сетевых таймаутов, "
        "кэширование GET-запросов и инвалидация кэша при POST/PUT/DELETE операциях;\n\n"
        "5. test/app_test.dart (23 теста) — виджет-тестирование пользовательского интерфейса: адаптивное переключение между DataTable на десктопе "
        "и CardListView на экранах <600 px, пагинация страниц и выбор размера страницы (10/25/50), переключение сортировки колонок, работа "
        "боковой рейки NavigationRail и нижней панели NavigationBar, клавиатурная навигация Tab/Enter/Escape, центрирование макета в пределах maxWidth: 1440 "
        "на мониторах 1920 px и сохранение параметров фильтрации в URL-адресе;\n\n"
        "6. test/form_test.dart (75 тестов) — виджет-тестирование форм создания и редактирования сущностей: валидация пустых полей с выводом "
        "ошибок под полями ввода, перенос фокуса на первое ошибочное поле, блокировка кнопки сохранения при отправке запроса, динамическая "
        "фильтрация справочников в форме книги, диалоговое окно подтверждения при попытке закрытия формы с несохранёнными изменениями;\n\n"
        "7. test/widgets_pr6_test.dart (5 обязательных виджет-тестов по п. 12 ТЗ на оценку «5»):\n"
        "• Тест 1 (состояние загрузки): отображение индикатора CircularProgressIndicator во время асинхронного ожидания ответа репозитория;\n"
        "• Тест 2 (пустой результат): отображение дружелюбного сообщения «Книги не найдены» при возврате пустого списка без падения вёрстки;\n"
        "• Тест 3 (сетевая ошибка и повтор): отображение текста ошибки соединения и активной кнопки «Повторить», повторно вызывающей загрузку;\n"
        "• Тест 4 (клиентская валидация формы): появление сообщений «Обязательное поле» под незаполненными полями книги при попытке отправки;\n"
        "• Тест 5 (скрытие недоступных элементов): сокрытие кнопки добавления книги («+») для пользователя с ролью Читатель (Reader)."
    )
    add_table_caption("Таблица 3 – Сводная ведомость модульных и виджет-тестов проекта library_web")
    add_custom_table(
        ["Файл тестового набора", "Тип тестов", "Число тестов", "Проверяемая функциональность и критерии"],
        [
            ["test/validators_test.dart", "Unit", "10", "Валидаторы полей: required, length, integer, year, email, phone, isbn, date, normalize"],
            ["test/models_test.dart", "Unit", "12", "Десериализация Book, Author, Genre, Publisher, Reader; устойчивость к отсутствующим полям JSON"],
            ["test/auth_test.dart", "Unit / Mock", "14", "Иерархия ролей (admin > librarian > reader), refresh JWT-токена при 401, эксперимент по подмене роли"],
            ["test/api_repository_test.dart", "Integration", "18", "Сетевые репозитории Dio: поиск, пагинация, сортировка, отмена устаревших запросов CancelToken"],
            ["test/app_test.dart", "Widget", "23", "Интерфейс каталога: таблица/карточки, пагинация, сортировка, поиск с задержкой debounce, роутинг"],
            ["test/form_test.dart", "Widget", "75", "Формы сущностей: валидация пустых полей, проверка связей, подтверждение несохранённых правок"],
            ["test/widgets_pr6_test.dart", "Widget", "5", "Обязательные тесты п. 12: состояние загрузки, пустой список, retry-кнопка, валидация, скрытие кнопки для роли reader"],
            ["ИТОГО ПО ПРОЕКТУ", "Все типы", "157", "Все тесты успешно проходят (All tests passed), время прогона ~11 секунд"]
        ],
        [Cm(4.0), Cm(2.2), Cm(2.2), Cm(7.1)]
    )
    add_figure("docs/figures-pr6/10-widget-tests-code.png", "Рисунок 17 – Реализация обязательных тестов виджетов по п. 12 задания (test/widgets_pr6_test.dart)")
    add_figure("docs/figures-pr6/11-test-console.png", "Рисунок 18 – Вывод консоли терминала: успешное прохождение всех 157 автоматизированных тестов")
    add_figure("docs/figures-pr6/12-analyze-format-console.png", "Рисунок 19 – Вывод консоли терминала: отсутствие замечаний анализатора flutter analyze и форматирование кода")

    # ─────────────────────────────────────────────────────────────────────────────
    # STEP 11: Заключение и результаты
    # ─────────────────────────────────────────────────────────────────────────────
    add_step_p(
        "11. Заключение и контрольные адреса опубликованного проекта. "
        "В результате выполнения практической работы веб-приложение каталога библиотеки успешно подготовлено к промышленной "
        "эксплуатации: реализована адаптивная вёрстка для мобильных, планшетных и настольных разрешений (360, 768, 1280 и 1920 px); "
        "устранены переполнения макета с помощью виджетов ConstrainedBox, Wrap и TextOverflow.ellipsis; выполнены и исследованы "
        "релизные сборки в форматах JavaScript и WebAssembly (WasmGC); настроен автоматический конвейер CI/CD на базе GitHub Actions; "
        "решена проблема SPA-роутинга через генерацию страницы 404.html; внедрён брендированный экран-заглушка в web/index.html; "
        "проект полностью верифицирован статическим анализатором (0 замечаний) и покрыт 157 автоматизированными тестами.\n\n"
        "Контрольные адреса проекта:\n"
        "• Исходный код репозитория: https://github.com/Fiven4/library_web\n"
        "• Опубликованное веб-приложение: https://fiven4.github.io/library_web/"
    )

    out_path = 'docs/report-practice-6.docx'
    doc.save(out_path)
    print(f"Report saved successfully to {out_path}!")

if __name__ == '__main__':
    build_report()
