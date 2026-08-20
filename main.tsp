import "@typespec/http";

using TypeSpec.Http;

@service(#{ title: "Календарь звонков" })
@doc("""
Внешнее поведение сервиса «Календарь звонков».

Роли (регистрации и авторизации нет):
- Владелец календаря — один заранее заданный профиль, по умолчанию используется
  в админской части (маршруты /admin).
- Гость — бронирует слоты без создания аккаунта и без входа в систему.

Общие правила:
- Окно записи: слоты формируются на 14 дней, начиная с текущей даты (включительно).
- Занятость: на одно и то же время нельзя создать две записи, даже разных типов
  событий — занятым считается пересечение интервалов [startsAt, endsAt)
  с учётом длительности бронирования.
- Сетка слотов: ежедневно внутри диапазона типа события [availableFrom, availableTo)
  слоты идут подряд с шагом durationMinutes, начиная с availableFrom; последний
  слот должен целиком уместиться в диапазон.
""")
namespace CallCalendar;

// ---------------------------------------------------------------------------
// Модели
// ---------------------------------------------------------------------------

@doc("Допустимая длительность слота в минутах")
enum SlotDuration {
  min15: 15,
  min30: 30,
  min45: 45,
  min60: 60,
}

@doc("Тип события (вид брони)")
model EventType {
  @doc("Идентификатор, присваивается системой при создании")
  id: string;

  @doc("Название")
  name: string;

  @doc("Описание")
  description: string;

  @doc("Длительность слота в минутах")
  durationMinutes: SlotDuration;

  @doc("Начало ежедневного диапазона, в котором формируются слоты (время суток)")
  availableFrom: plainTime;

  @doc("Конец ежедневного диапазона, в котором формируются слоты (время суток)")
  availableTo: plainTime;
}

@doc("Данные для создания типа события")
model EventTypeCreate {
  @doc("Название")
  name: string;

  @doc("Описание")
  description: string;

  @doc("Длительность слота в минутах")
  durationMinutes: SlotDuration;

  @doc("Начало ежедневного диапазона, в котором формируются слоты (время суток)")
  availableFrom: plainTime;

  @doc("Конец ежедневного диапазона, в котором формируются слоты (время суток)")
  availableTo: plainTime;
}

@doc("Данные для редактирования типа события; все поля опциональны")
model EventTypeUpdate {
  @doc("Название")
  name?: string;

  @doc("Описание")
  description?: string;

  @doc("Длительность слота в минутах")
  durationMinutes?: SlotDuration;

  @doc("Начало ежедневного диапазона, в котором формируются слоты (время суток)")
  availableFrom?: plainTime;

  @doc("Конец ежедневного диапазона, в котором формируются слоты (время суток)")
  availableTo?: plainTime;
}

@doc("Бронирование слота")
model Booking {
  @doc("Идентификатор, присваивается системой")
  id: string;

  @doc("Идентификатор типа события")
  eventTypeId: string;

  @doc("Дата и время начала")
  startsAt: utcDateTime;

  @doc("""
  Дата и время окончания. Фиксируется при создании как startsAt + длительность
  типа события на момент бронирования; при последующем редактировании типа
  события не пересчитывается.
  """)
  endsAt: utcDateTime;

  @doc("Имя гостя")
  guestName: string;

  @doc("Email гостя")
  @format("email")
  guestEmail: string;
}

@doc("Данные для создания бронирования")
model BookingCreate {
  @doc("Идентификатор выбранного типа события")
  eventTypeId: string;

  @doc("Дата и время начала; должно совпадать с началом допустимого слота")
  startsAt: utcDateTime;

  @doc("Имя гостя")
  guestName: string;

  @doc("Email гостя")
  @format("email")
  guestEmail: string;
}

@doc("Свободный слот")
model Slot {
  @doc("Дата и время начала")
  startsAt: utcDateTime;

  @doc("Дата и время окончания")
  endsAt: utcDateTime;
}

// ---------------------------------------------------------------------------
// Ошибки
// ---------------------------------------------------------------------------

@doc("Ресурс не найден")
@error
model NotFoundError {
  @statusCode statusCode: 404;
  @doc("Описание ошибки")
  message: string;
}

@doc("""
Слот занят: интервал новой брони [startsAt, endsAt) пересекается с интервалом
существующего бронирования (любого типа события).
""")
@error
model SlotConflictError {
  @statusCode statusCode: 409;
  @doc("Описание ошибки")
  message: string;
}

@doc("""
Слот недопустим: не совпадает с сеткой слотов типа события, выходит за пределы
ежедневного диапазона, находится в прошлом или за пределами окна в 14 дней.
""")
@error
model InvalidSlotError {
  @statusCode statusCode: 422;
  @doc("Описание ошибки")
  message: string;
}

// ---------------------------------------------------------------------------
// Гостевая часть
// ---------------------------------------------------------------------------

@route("/event-types")
interface EventTypes {
  @get
  @doc("Гость: страница видов брони — список типов событий (название, описание, длительность)")
  list(): EventType[];

  @get
  @route("/{eventTypeId}/slots")
  @doc("""
  Гость: свободные слоты выбранного типа события.

  Слоты формируются на 14 дней, начиная с текущей даты (включительно):
  ежедневно внутри диапазона [availableFrom, availableTo), подряд с шагом
  durationMinutes начиная с availableFrom; последний слот должен целиком
  уместиться в диапазон.

  Слот доступен, если он не в прошлом и его интервал не пересекается ни с одним
  существующим бронированием (любого типа события).
  """)
  slots(@path eventTypeId: string): Slot[] | NotFoundError;
}

@route("/bookings")
interface Bookings {
  @post
  @doc("""
  Гость: создать бронирование на выбранный слот.

  startsAt обязан совпадать с началом допустимого слота (сетка типа события,
  окно 14 дней) — иначе 422. На одно и то же время нельзя создать две записи,
  даже разных типов событий: при пересечении интервалов — 409.
  """)
  create(@body booking: BookingCreate): {
    @statusCode statusCode: 201;
    @body body: Booking;
  } | NotFoundError | InvalidSlotError | SlotConflictError;
}

// ---------------------------------------------------------------------------
// Админская часть (владелец календаря)
// ---------------------------------------------------------------------------

@route("/admin/event-types")
interface AdminEventTypes {
  @post
  @doc("Владелец: создать тип события. id присваивается системой.")
  create(@body eventType: EventTypeCreate): {
    @statusCode statusCode: 201;
    @body body: EventType;
  };

  @patch(#{implicitOptionality: false})
  @route("/{eventTypeId}")
  @doc("""
  Владелец: редактировать тип события.

  Изменение длительности или диапазона влияет только на формирование новых
  слотов; уже созданные бронирования не изменяются.
  """)
  update(
    @path eventTypeId: string,
    @body patch: EventTypeUpdate,
  ): EventType | NotFoundError;

  @delete
  @route("/{eventTypeId}")
  @doc("""
  Владелец: удалить тип события. Все бронирования этого типа удаляются
  вместе с ним (каскадно).
  """)
  delete(@path eventTypeId: string): {
    @statusCode statusCode: 204;
  } | NotFoundError;
}

@route("/admin/bookings")
interface AdminBookings {
  @get
  @doc("""
  Владелец: страница предстоящих встреч — единый список бронирований всех
  типов событий, начиная с текущего момента, по возрастанию времени начала.
  """)
  upcoming(): Booking[];

  @delete
  @route("/{bookingId}")
  @doc("Владелец: отменить бронирование")
  cancel(@path bookingId: string): {
    @statusCode statusCode: 204;
  } | NotFoundError;
}
