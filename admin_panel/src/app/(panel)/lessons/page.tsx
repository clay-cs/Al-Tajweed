"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";

import { api, type Lesson, type Localized } from "@/lib/api";
import {
  Badge,
  Button,
  Card,
  Empty,
  Field,
  Input,
  Modal,
  Select,
  Td,
  Th,
  useToast,
} from "@/components/ui";

const ICONS = [
  { value: "translate", label: "🔤 Alifbo" },
  { value: "voice", label: "🗣 Tilovat" },
  { value: "eq", label: "🎚 Qoidalar" },
  { value: "audio", label: "🎵 Madd" },
  { value: "mic", label: "🎙 Maxraj" },
  { value: "school", label: "🎓 Umumiy" },
];

interface LessonForm {
  id: string | null;
  title: Localized;
  subtitle: Localized;
  totalLessons: number;
  order: number;
  icon: string;
  color: string;
  active: boolean;
}

const emptyForm = (): LessonForm => ({
  id: null,
  title: { en: "", uz: "" },
  subtitle: { en: "", uz: "" },
  totalLessons: 10,
  order: 0,
  icon: "school",
  color: "#0E9D7B",
  active: true,
});

export default function LessonsPage() {
  const toast = useToast();
  const [items, setItems] = useState<Lesson[] | null>(null);
  const [form, setForm] = useState<LessonForm | null>(null);

  const load = useCallback(() => {
    api<{ items: Lesson[] }>("/admin/lessons")
      .then((d) => setItems(d.items))
      .catch((e) => toast(e.message, true));
  }, [toast]);

  useEffect(load, [load]);

  function openEdit(l: Lesson) {
    setForm({
      id: l._id,
      title: { ...l.title },
      subtitle: { ...l.subtitle },
      totalLessons: l.totalLessons,
      order: l.order,
      icon: l.icon,
      color: l.color,
      active: l.active,
    });
  }

  async function save() {
    if (!form) return;
    try {
      const body = {
        title: form.title,
        subtitle: form.subtitle,
        totalLessons: Number(form.totalLessons),
        order: Number(form.order),
        icon: form.icon,
        color: form.color,
        active: form.active,
      };
      await api(form.id ? `/admin/lessons/${form.id}` : "/admin/lessons", {
        method: form.id ? "PUT" : "POST",
        body,
      });
      setForm(null);
      toast("Saqlandi ✓");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  async function remove(id: string) {
    if (!confirm("Kurs o‘chirilsinmi?")) return;
    try {
      await api(`/admin/lessons/${id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  return (
    <>
      <h1 className="text-2xl font-extrabold">Kurslar — Learning Center</h1>
      <p className="mb-6 mt-1 text-[13.5px] text-muted">
        Ilovadagi “O‘rganish” bo‘limida ko‘rinadigan kurslar.
      </p>

      <div className="mb-4">
        <Button onClick={() => setForm(emptyForm())}>＋ Yangi kurs</Button>
      </div>

      <Card>
        {!items ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : items.length === 0 ? (
          <Empty>Kurslar yo‘q — birinchisini qo‘shing</Empty>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr>
                  <Th>#</Th>
                  <Th>Nomi (UZ)</Th>
                  <Th>Tavsif (UZ)</Th>
                  <Th>Darslar</Th>
                  <Th>Rang</Th>
                  <Th>Holat</Th>
                  <Th>
                    <span className="block text-right">Amallar</span>
                  </Th>
                </tr>
              </thead>
              <tbody>
                {items.map((l) => (
                  <tr key={l._id} className="hover:bg-white/[0.015]">
                    <Td>{l.order}</Td>
                    <Td>
                      <b>{l.title.uz}</b>
                      <div className="text-xs text-muted">{l.title.en}</div>
                    </Td>
                    <Td className="text-muted">{l.subtitle.uz}</Td>
                    <Td>{l.totalLessons}</Td>
                    <Td>
                      <span
                        className="inline-block h-4.5 w-4.5 rounded-md align-middle"
                        style={{ background: l.color }}
                      />
                    </Td>
                    <Td>
                      <Badge tone={l.active ? "on" : "off"}>
                        {l.active ? "Faol" : "O‘chiq"}
                      </Badge>
                    </Td>
                    <Td className="whitespace-nowrap text-right">
                      <Link href={`/lessons/${l._id}`}>
                        <Button
                          variant="ghost"
                          className="!px-3 !py-1.5 text-xs"
                        >
                          📚 Darslar
                        </Button>
                      </Link>{" "}
                      <Button
                        variant="ghost"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => openEdit(l)}
                      >
                        ✏️
                      </Button>{" "}
                      <Button
                        variant="danger"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => remove(l._id)}
                      >
                        🗑
                      </Button>
                    </Td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <Modal
        title={form?.id ? "Kursni tahrirlash" : "Yangi kurs"}
        open={form !== null}
        onClose={() => setForm(null)}
      >
        {form && (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Nomi (EN)">
                <Input
                  value={form.title.en}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      title: { ...form.title, en: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Nomi (UZ)">
                <Input
                  value={form.title.uz}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      title: { ...form.title, uz: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Tavsif (EN)">
                <Input
                  value={form.subtitle.en}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      subtitle: { ...form.subtitle, en: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Tavsif (UZ)">
                <Input
                  value={form.subtitle.uz}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      subtitle: { ...form.subtitle, uz: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Darslar soni">
                <Input
                  type="number"
                  min={1}
                  value={form.totalLessons}
                  onChange={(e) =>
                    setForm({ ...form, totalLessons: Number(e.target.value) })
                  }
                />
              </Field>
              <Field label="Tartib">
                <Input
                  type="number"
                  value={form.order}
                  onChange={(e) =>
                    setForm({ ...form, order: Number(e.target.value) })
                  }
                />
              </Field>
              <Field label="Rang">
                <input
                  type="color"
                  className="h-11 w-full cursor-pointer rounded-lg border border-line bg-bg2 p-1"
                  value={form.color}
                  onChange={(e) => setForm({ ...form, color: e.target.value })}
                />
              </Field>
              <Field label="Ikonka">
                <Select
                  value={form.icon}
                  onChange={(e) => setForm({ ...form, icon: e.target.value })}
                >
                  {ICONS.map((i) => (
                    <option key={i.value} value={i.value}>
                      {i.label}
                    </option>
                  ))}
                </Select>
              </Field>
            </div>

            <Field label="Holat">
              <Select
                value={String(form.active)}
                onChange={(e) =>
                  setForm({ ...form, active: e.target.value === "true" })
                }
              >
                <option value="true">Faol</option>
                <option value="false">O‘chirilgan</option>
              </Select>
            </Field>

            <div className="flex justify-end gap-2.5 pt-2">
              <Button variant="ghost" onClick={() => setForm(null)}>
                Bekor qilish
              </Button>
              <Button onClick={save}>Saqlash</Button>
            </div>
          </div>
        )}
      </Modal>
    </>
  );
}
