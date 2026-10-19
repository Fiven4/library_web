import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/library_card.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../repositories/reader_repository.dart';
import '../state/entity_form_notifier.dart';
import '../state/reference_notifier.dart';
import '../widgets/form/entity_form_view.dart';
import '../widgets/form/field_specs.dart';

String _text(FormValues v, String key) => (v[key] as String? ?? '').trim();
int _int(FormValues v, String key) => int.tryParse(_text(v, key)) ?? 0;
String _dateText(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Форма книги: все три типа связей в одном экране.
/// Издательство (многие к одному) выбирается списком, авторы и жанры
/// (многие ко многим) множественным выбором.
class BookFormScreen extends StatelessWidget {
  final int? id;

  const BookFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ReferenceNotifier>();

    List<Option> publisherOptions(FormValues v) {
      final options = [for (final p in ref.publishers) (p.id, p.name)];
      final current = v['publisherId'] as int?;
      if (current != null && !options.any((o) => o.$1 == current)) {
        options.add((current, '${ref.publisherName(current)} (удалено)'));
      }
      return options;
    }

    /// Каскад: после выбора издательства список авторов сужается до тех,
    /// кто уже выпускал книги в нём. Уже выбранные авторы остаются в списке.
    List<Option> authorOptions(FormValues v) {
      var authors = ref.authors;
      final publisherId = v['publisherId'] as int?;
      if (publisherId != null && (v['narrowAuthors'] as bool? ?? false)) {
        final allowed = ref.authorIdsOfPublisher(publisherId);
        final selected = (v['authorIds'] as List?)?.cast<int>() ?? const [];
        authors = [
          for (final a in authors)
            if (allowed.contains(a.id) || selected.contains(a.id)) a,
        ];
      }
      return [for (final a in authors) (a.id, a.fullName)];
    }

    return ChangeNotifierProvider(
      key: ValueKey('book-form-$id'),
      create: (context) =>
          EntityFormNotifier<Book>(context.read<BookRepository>(), id)..load(),
      child: Builder(
        builder: (context) => EntityFormView<Book>(
          notifier: context.read<EntityFormNotifier<Book>>(),
          createTitle: 'Новая книга',
          editTitle: (b) => 'Изменение: ${b.title}',
          listPath: '/books',
          initialValues: (b) => {
            'title': b?.title ?? '',
            'isbn': b?.isbn ?? '',
            'year': b == null ? '' : '${b.year}',
            'pages': b == null ? '' : '${b.pages}',
            'publisherId': b?.publisherId,
            'narrowAuthors': true,
            'authorIds': List<int>.of(b?.authorIds ?? const []),
            'genreIds': List<int>.of(b?.genreIds ?? const []),
            'copiesTotal': b == null ? '' : '${b.copiesTotal}',
            'copiesAvailable': b == null ? '' : '${b.copiesAvailable}',
          },
          specs: (editing) => [
            TextSpec(
              key: 'title',
              label: 'Название',
              required: true,
              validator: plain(
                V.combine([
                  V.required('Укажите название'),
                  V.length(min: 2, max: 200),
                ]),
              ),
            ),
            TextSpec(
              key: 'isbn',
              label: 'ISBN',
              required: true,
              hint: '978-5-17-118366-4',
              validator: plain(
                V.combine([V.required('Укажите ISBN'), V.isbn()]),
              ),
            ),
            TextSpec(
              key: 'year',
              label: 'Год издания',
              required: true,
              keyboard: TextInputType.number,
              validator: plain(
                V.combine([V.required('Укажите год'), V.year(min: 1450)]),
              ),
            ),
            TextSpec(
              key: 'pages',
              label: 'Страниц',
              required: true,
              keyboard: TextInputType.number,
              validator: plain(
                V.combine([
                  V.required('Укажите число страниц'),
                  V.integer(min: 1, max: 10000),
                ]),
              ),
            ),
            DropdownSpec(
              key: 'publisherId',
              label: 'Издательство',
              required: true,
              requiredMessage: 'Выберите издательство',
              options: publisherOptions,
            ),
            // Переключатель каскада виден, когда издательство уже выбрано.
            if (ref.publishers.isNotEmpty)
              const SwitchSpec(
                key: 'narrowAuthors',
                label: 'Авторы только из этого издательства',
              ),
            MultiSpec(
              key: 'authorIds',
              label: 'Авторы',
              helper:
                  'Необязательно: у технических изданий авторов может не быть',
              options: authorOptions,
            ),
            MultiSpec(
              key: 'genreIds',
              label: 'Жанры',
              required: true,
              requiredMessage: 'Выберите хотя бы один жанр',
              options: (_) => [for (final g in ref.genres) (g.id, g.name)],
            ),
            TextSpec(
              key: 'copiesTotal',
              label: 'Количество экземпляров',
              required: true,
              keyboard: TextInputType.number,
              validator: plain(
                V.combine([
                  V.required('Укажите количество'),
                  V.positive(max: 1000),
                ]),
              ),
            ),
            if (editing)
              TextSpec(
                key: 'copiesAvailable',
                label: 'Доступно экземпляров',
                required: true,
                keyboard: TextInputType.number,
                // Проверка по двум полям: доступных не больше, чем всего.
                validator: (value, values) {
                  final base = V.combine([
                    V.required('Укажите количество'),
                    V.integer(min: 0, max: 1000),
                  ])(value);
                  if (base != null) return base;
                  final total = int.tryParse(_text(values, 'copiesTotal'));
                  final available = int.parse(value!.trim());
                  if (total != null && available > total) {
                    return 'Не больше общего числа экземпляров ($total)';
                  }
                  return null;
                },
              ),
          ],
          build: (v, existing) => Book(
            id: existing?.id ?? 0,
            title: _text(v, 'title'),
            isbn: _text(v, 'isbn'),
            year: _int(v, 'year'),
            pages: _int(v, 'pages'),
            publisherId: v['publisherId'] as int? ?? 0,
            authorIds: List<int>.of((v['authorIds'] as List).cast<int>()),
            genreIds: List<int>.of((v['genreIds'] as List).cast<int>()),
            copiesTotal: _int(v, 'copiesTotal'),
            copiesAvailable: existing == null
                ? _int(v, 'copiesTotal')
                : _int(v, 'copiesAvailable'),
            deletedAt: existing?.deletedAt,
          ),
        ),
      ),
    );
  }
}

class AuthorFormScreen extends StatelessWidget {
  final int? id;

  const AuthorFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey('author-form-$id'),
      create: (context) =>
          EntityFormNotifier<Author>(context.read<AuthorRepository>(), id)
            ..load(),
      child: Builder(
        builder: (context) => EntityFormView<Author>(
          notifier: context.read<EntityFormNotifier<Author>>(),
          createTitle: 'Новый автор',
          editTitle: (a) => 'Изменение: ${a.fullName}',
          listPath: '/authors',
          initialValues: (a) => {
            'fullName': a?.fullName ?? '',
            'birthYear': a == null ? '' : '${a.birthYear}',
            'country': a?.country ?? '',
          },
          specs: (_) => [
            TextSpec(
              key: 'fullName',
              label: 'ФИО',
              required: true,
              hint: 'Толстой Л. Н.',
              validator: plain(
                V.combine([
                  V.required('Укажите ФИО'),
                  V.length(min: 2, max: 100),
                ]),
              ),
            ),
            TextSpec(
              key: 'birthYear',
              label: 'Год рождения',
              required: true,
              keyboard: TextInputType.number,
              validator: plain(
                V.combine([V.required('Укажите год рождения'), V.year(min: 1)]),
              ),
            ),
            TextSpec(
              key: 'country',
              label: 'Страна',
              required: true,
              validator: plain(
                V.combine([
                  V.required('Укажите страну'),
                  V.length(min: 2, max: 60),
                ]),
              ),
            ),
          ],
          build: (v, existing) => Author(
            id: existing?.id ?? 0,
            fullName: _text(v, 'fullName'),
            birthYear: _int(v, 'birthYear'),
            country: _text(v, 'country'),
            deletedAt: existing?.deletedAt,
          ),
        ),
      ),
    );
  }
}

class GenreFormScreen extends StatelessWidget {
  final int? id;

  const GenreFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey('genre-form-$id'),
      create: (context) =>
          EntityFormNotifier<Genre>(context.read<GenreRepository>(), id)
            ..load(),
      child: Builder(
        builder: (context) => EntityFormView<Genre>(
          notifier: context.read<EntityFormNotifier<Genre>>(),
          createTitle: 'Новый жанр',
          editTitle: (g) => 'Изменение: ${g.name}',
          listPath: '/genres',
          initialValues: (g) => {
            'name': g?.name ?? '',
            'description': g?.description ?? '',
          },
          specs: (_) => [
            TextSpec(
              key: 'name',
              label: 'Название',
              required: true,
              validator: plain(
                V.combine([
                  V.required('Укажите название'),
                  V.length(min: 2, max: 50),
                ]),
              ),
            ),
            TextSpec(
              key: 'description',
              label: 'Описание',
              maxLines: 3,
              validator: plain(V.length(max: 255)),
            ),
          ],
          build: (v, existing) => Genre(
            id: existing?.id ?? 0,
            name: _text(v, 'name'),
            description: _text(v, 'description'),
            deletedAt: existing?.deletedAt,
          ),
        ),
      ),
    );
  }
}

class PublisherFormScreen extends StatelessWidget {
  final int? id;

  const PublisherFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey('publisher-form-$id'),
      create: (context) =>
          EntityFormNotifier<Publisher>(context.read<PublisherRepository>(), id)
            ..load(),
      child: Builder(
        builder: (context) => EntityFormView<Publisher>(
          notifier: context.read<EntityFormNotifier<Publisher>>(),
          createTitle: 'Новое издательство',
          editTitle: (p) => 'Изменение: ${p.name}',
          listPath: '/publishers',
          initialValues: (p) => {
            'name': p?.name ?? '',
            'city': p?.city ?? '',
            'foundedYear': p == null ? '' : '${p.foundedYear}',
          },
          specs: (_) => [
            TextSpec(
              key: 'name',
              label: 'Название',
              required: true,
              validator: plain(
                V.combine([
                  V.required('Укажите название'),
                  V.length(min: 2, max: 100),
                ]),
              ),
            ),
            TextSpec(
              key: 'city',
              label: 'Город',
              required: true,
              validator: plain(
                V.combine([
                  V.required('Укажите город'),
                  V.length(min: 2, max: 60),
                ]),
              ),
            ),
            TextSpec(
              key: 'foundedYear',
              label: 'Год основания',
              required: true,
              keyboard: TextInputType.number,
              validator: plain(
                V.combine([
                  V.required('Укажите год основания'),
                  V.year(min: 1400),
                ]),
              ),
            ),
          ],
          build: (v, existing) => Publisher(
            id: existing?.id ?? 0,
            name: _text(v, 'name'),
            city: _text(v, 'city'),
            foundedYear: _int(v, 'foundedYear'),
            deletedAt: existing?.deletedAt,
          ),
        ),
      ),
    );
  }
}

/// Форма читателя. Читательский билет (связь «один к одному») редактируется
/// прямо здесь вложенной группой полей, отдельного экрана для него нет.
class ReaderFormScreen extends StatelessWidget {
  final int? id;

  const ReaderFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey('reader-form-$id'),
      create: (context) =>
          EntityFormNotifier<Reader>(context.read<ReaderRepository>(), id)
            ..load(),
      child: Builder(
        builder: (context) => EntityFormView<Reader>(
          notifier: context.read<EntityFormNotifier<Reader>>(),
          createTitle: 'Новый читатель',
          editTitle: (r) => 'Изменение: ${r.fullName}',
          listPath: '/readers',
          initialValues: (r) {
            final now = DateTime.now();
            return {
              'fullName': r?.fullName ?? '',
              'email': r?.email ?? '',
              'phone': r?.phone ?? '',
              'card.number': r?.card.number ?? '',
              'card.issuedAt': _dateText(r?.card.issuedAt ?? now),
              'card.expiresAt': _dateText(
                r?.card.expiresAt ?? DateTime(now.year + 1, now.month, now.day),
              ),
            };
          },
          specs: (_) => [
            TextSpec(
              key: 'fullName',
              label: 'ФИО',
              required: true,
              hint: 'Смирнов П. А.',
              validator: plain(
                V.combine([
                  V.required('Укажите ФИО'),
                  V.length(min: 2, max: 100),
                ]),
              ),
            ),
            TextSpec(
              key: 'email',
              label: 'Электронная почта',
              required: true,
              keyboard: TextInputType.emailAddress,
              validator: plain(
                V.combine([V.required('Укажите почту'), V.email()]),
              ),
            ),
            TextSpec(
              key: 'phone',
              label: 'Телефон',
              hint: '+7 900 000-00-00',
              keyboard: TextInputType.phone,
              validator: plain(V.phone()),
            ),
            GroupSpec(
              title: 'Читательский билет',
              fields: [
                TextSpec(
                  key: 'card.number',
                  label: 'Номер билета',
                  required: true,
                  hint: 'RC-000007',
                  validator: plain(
                    V.combine([
                      V.required('Укажите номер билета'),
                      V.cardNumber(),
                    ]),
                  ),
                ),
                DateSpec(
                  key: 'card.issuedAt',
                  label: 'Дата выдачи',
                  required: true,
                  validator: plain(
                    V.combine([V.required('Укажите дату выдачи'), V.date()]),
                  ),
                ),
                DateSpec(
                  key: 'card.expiresAt',
                  label: 'Действует до',
                  required: true,
                  validator: (value, values) {
                    final base = V.combine([
                      V.required('Укажите срок действия'),
                      V.date(),
                    ])(value);
                    if (base != null) return base;
                    final issued = DateTime.tryParse(
                      _text(values, 'card.issuedAt'),
                    );
                    final expires = DateTime.parse(value!.trim());
                    if (issued != null && !expires.isAfter(issued)) {
                      return 'Срок действия должен быть позже даты выдачи';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ],
          build: (v, existing) => Reader(
            id: existing?.id ?? 0,
            fullName: _text(v, 'fullName'),
            email: _text(v, 'email'),
            phone: _text(v, 'phone'),
            card: LibraryCard(
              id: existing?.card.id ?? 0,
              number: _text(v, 'card.number'),
              issuedAt: DateTime.parse(_text(v, 'card.issuedAt')),
              expiresAt: DateTime.parse(_text(v, 'card.expiresAt')),
            ),
            deletedAt: existing?.deletedAt,
          ),
        ),
      ),
    );
  }
}
