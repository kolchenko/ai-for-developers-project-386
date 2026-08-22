package api

import (
	"log"
	"net/http"
	"time"

	"callcalendar/backend/internal/store"
)

type Server struct {
	store *store.Store
	now   func() time.Time
}

func NewServer(st *store.Store) http.Handler {
	return (&Server{store: st, now: time.Now}).routes()
}

func (s *Server) routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /event-types", s.listEventTypes)
	mux.HandleFunc("GET /event-types/{eventTypeId}/slots", s.getSlots)
	mux.HandleFunc("POST /bookings", s.createBooking)
	mux.HandleFunc("POST /admin/event-types", s.adminCreateEventType)
	mux.HandleFunc("PATCH /admin/event-types/{eventTypeId}", s.adminUpdateEventType)
	mux.HandleFunc("DELETE /admin/event-types/{eventTypeId}", s.adminDeleteEventType)
	mux.HandleFunc("GET /admin/bookings", s.adminUpcomingBookings)
	mux.HandleFunc("DELETE /admin/bookings/{bookingId}", s.adminCancelBooking)

	return withLogging(mux)
}

func NewTestServer(st *store.Store, now func() time.Time) http.Handler {
	return (&Server{store: st, now: now}).routes()
}

func withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(start).Round(time.Millisecond))
	})
}
