import { Button, Group } from '@mantine/core';
import { IconCalendarEvent, IconClipboardList } from '@tabler/icons-react';
import { Link, Outlet, useLocation } from 'react-router-dom';

export function AdminLayout() {
  const { pathname } = useLocation();

  return (
    <>
      <Group mb="md" gap="xs">
        <Button
          variant={pathname === '/admin' ? 'filled' : 'subtle'}
          component={Link}
          to="/admin"
          leftSection={<IconCalendarEvent size={16} />}
        >
          Предстоящие встречи
        </Button>
        <Button
          variant={pathname.startsWith('/admin/event-types') ? 'filled' : 'subtle'}
          component={Link}
          to="/admin/event-types"
          leftSection={<IconClipboardList size={16} />}
        >
          Типы событий
        </Button>
      </Group>
      <Outlet />
    </>
  );
}
