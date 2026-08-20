import { Route, Routes } from 'react-router-dom';
import { AdminLayout } from './components/AdminLayout';
import { AppLayout } from './components/AppLayout';
import { AdminBookings } from './pages/AdminBookings';
import { AdminEventTypes } from './pages/AdminEventTypes';
import { GuestHome } from './pages/GuestHome';
import { GuestSlotSelection } from './pages/GuestSlotSelection';

export default function App() {
  return (
    <Routes>
      <Route element={<AppLayout />}>
        <Route index element={<GuestHome />} />
        <Route path="event-types/:eventTypeId" element={<GuestSlotSelection />} />
        <Route path="admin" element={<AdminLayout />}>
          <Route index element={<AdminBookings />} />
          <Route path="event-types" element={<AdminEventTypes />} />
        </Route>
      </Route>
    </Routes>
  );
}
