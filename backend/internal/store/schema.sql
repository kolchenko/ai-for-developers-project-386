CREATE TABLE IF NOT EXISTS event_types (
  id               TEXT PRIMARY KEY,
  name             TEXT NOT NULL,
  description      TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes IN (15, 30, 45, 60)),
  available_from   TEXT NOT NULL,
  available_to     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS bookings (
  id            TEXT PRIMARY KEY,
  event_type_id TEXT NOT NULL REFERENCES event_types(id) ON DELETE CASCADE,
  starts_at     TEXT NOT NULL,
  ends_at       TEXT NOT NULL,
  guest_name    TEXT NOT NULL,
  guest_email   TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_bookings_event_type_id ON bookings(event_type_id);
CREATE INDEX IF NOT EXISTS idx_bookings_starts_at ON bookings(starts_at);
