import {
  Button,
  Grid,
  Modal,
  Select,
  Stack,
  Text,
  TextInput,
} from '@mantine/core';
import { TimePicker } from '@mantine/dates';
import { useState } from 'react';
import { useCreateEventType, useUpdateEventType } from '../api/hooks';
import { SLOT_DURATIONS } from '../api/types';
import type { EventType } from '../api/types';
import { toTimeValue } from '../utils/time';

interface EventTypeFormModalProps {
  opened: boolean;
  onClose: () => void;
  eventType?: EventType;
}

interface FormState {
  name: string;
  description: string;
  durationMinutes: string;
  availableFrom: string;
  availableTo: string;
}

const DURATION_OPTIONS = SLOT_DURATIONS.map((d) => ({
  value: String(d),
  label: `${d} минут`,
}));

export function EventTypeFormModal({ opened, onClose, eventType }: EventTypeFormModalProps) {
  const createEventType = useCreateEventType();
  const updateEventType = useUpdateEventType();

  const [form, setForm] = useState<FormState>({
    name: eventType?.name ?? '',
    description: eventType?.description ?? '',
    durationMinutes: eventType ? String(eventType.durationMinutes) : '30',
    availableFrom: eventType?.availableFrom.slice(0, 5) ?? '09:00',
    availableTo: eventType?.availableTo.slice(0, 5) ?? '18:00',
  });

  const isPending = createEventType.isPending || updateEventType.isPending;
  const isEdit = Boolean(eventType);

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const submit = () => {
    const payload = {
      name: form.name.trim(),
      description: form.description.trim(),
      durationMinutes: Number(form.durationMinutes) as EventType['durationMinutes'],
      availableFrom: toTimeValue(form.availableFrom),
      availableTo: toTimeValue(form.availableTo),
    };

    const done = () => {
      createEventType.reset();
      updateEventType.reset();
      onClose();
    };

    if (eventType) {
      updateEventType.mutate({ id: eventType.id, patch: payload }, { onSuccess: done });
    } else {
      createEventType.mutate(payload, { onSuccess: done });
    }
  };

  const error = createEventType.error?.message ?? updateEventType.error?.message;

  const isValid =
    form.name.trim().length > 0 &&
    form.description.trim().length > 0 &&
    form.availableFrom.length === 5 &&
    form.availableTo.length === 5;

  return (
    <Modal opened={opened} onClose={onClose} title={isEdit ? 'Редактировать тип события' : 'Новый тип события'} centered>
      <Stack gap="md">
        {error && <Text c="red">{error}</Text>}

        <TextInput
          label="Название"
          required
          value={form.name}
          onChange={(e) => set('name', e.currentTarget.value)}
          disabled={isPending}
        />
        <TextInput
          label="Описание"
          required
          value={form.description}
          onChange={(e) => set('description', e.currentTarget.value)}
          disabled={isPending}
        />
        <Select
          label="Длительность слота"
          required
          data={DURATION_OPTIONS}
          value={form.durationMinutes}
          onChange={(value) => value && set('durationMinutes', value)}
          disabled={isPending}
        />
        <Grid>
          <Grid.Col span={6}>
            <TimePicker
              label="Начало окна"
              required
              format="24h"
              value={form.availableFrom}
              onChange={(value) => set('availableFrom', value)}
              disabled={isPending}
            />
          </Grid.Col>
          <Grid.Col span={6}>
            <TimePicker
              label="Конец окна"
              required
              format="24h"
              value={form.availableTo}
              onChange={(value) => set('availableTo', value)}
              disabled={isPending}
            />
          </Grid.Col>
        </Grid>

        <Button fullWidth loading={isPending} disabled={!isValid} onClick={submit}>
          {isEdit ? 'Сохранить' : 'Создать'}
        </Button>
      </Stack>
    </Modal>
  );
}
