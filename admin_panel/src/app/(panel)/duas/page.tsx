"use client";

import { useCallback, useEffect, useState } from "react";

import { api, type DuaDoc, type Localized } from "@/lib/api";
import {
  Badge,
  Button,
  Card,
  Empty,
  Field,
  Input,
  Modal,
  Select,
  inputCls,
  useToast,
} from "@/components/ui";

const CATEGORIES = [
  { value: "Morning", label: "Tong" },
  { value: "Evening", label: "Kech" },
  { value: "Travel", label: "Safar" },
  { value: "Food", label: "Taom" },
  { value: "Sleep", label: "Uyqu" },
  { value: "Protection", label: "Himoya" },
  { value: "Forgiveness", label: "Istig‘for" },
];

const catLabel = (v: string) =>
  CATEGORIES.find((c) => c.value === v)?.label ?? v;

interface DuaForm {
  id: string | null;
  title: Localized;
  category: string;
  arabic: string;
  transliteration: string;
  translation: Localized;
  order: number;
  active: boolean;
}

const emptyForm = (nextOrder: number): DuaForm => ({
  id: null,
  title: { en: "", uz: "" },
  category: "Morning",
  arabic: "",
  transliteration: "",
  translation: { en: "", uz: "" },
  order: nextOrder,
  active: true,
});

const textareaCls = `${inputCls} min-h-20 resize-y`;

export default function DuasPage() {
  const toast = useToast();
  const [items, setItems] = useState<DuaDoc[] | null>(null);
  const [form, setForm] = useState<DuaForm | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(() => {
    api<{ items: DuaDoc[] }>("/admin/duas")
      .then((d) => setItems(d.items))
      .catch((e) => toast(e.message, true));
  }, [toast]);

  useEffect(load, [load]);

  function openNew() {
    const next = items?.length
      ? Math.max(...items.map((d) => d.order)) + 1
      : 1;
    setForm(emptyForm(next));
  }

  function openEdit(d: DuaDoc) {
    setForm({
      id: d._id,
      title: { ...d.title },
      category: d.category,
      arabic: d.arabic,
      transliteration: d.transliteration,
      translation: { ...d.translation },
      order: d.order,
      active: d.active,
    });
  }

  async function save() {
    if (!form) return;
    setSaving(true);
    try {
      const body = {
        title: form.title,
        category: form.category,
        arabic: form.arabic.trim(),
        transliteration: form.transliteration.trim(),
        translation: form.translation,
        order: Number(form.order),
        active: form.active,
      };
      await api(form.id ? `/admin/duas/${form.id}` : "/admin/duas", {
        method: form.id ? "PUT" : "POST",
        body,
      });
      setForm(null);
      toast("Saqlandi ✓");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    } finally {
      setSaving(false);
    }
  }

  async function remove(d: DuaDoc) {
    if (!confirm(`«${d.title.uz}» duosi o‘chirilsinmi?`)) return;
    try {
      await api(`/admin/duas/${d._id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  return (
    <>
      <h1 className="text-2xl font-extrabold">Duolar</h1>
      <p className="mb-6 mt-1 text-[13.5px] text-muted">
        Ilovadagi «Duolar» bo‘limi: arabcha matn, lotincha o‘qilishi va
        tarjima (EN + UZ), kategoriya bo‘yicha.
      </p>

      <div className="mb-4">
        <Button onClick={openNew}>＋ Yangi duo</Button>
      </div>

      <Card>
        {!items ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : items.length === 0 ? (
          <Empty>Duolar yo‘q — birinchisini qo‘shing</Empty>
        ) : (
          <div className="space-y-3">
            {items.map((d) => (
              <div
                key={d._id}
                className="rounded-xl border border-line bg-bg2 p-4"
              >
                <div className="mb-2 flex flex-wrap items-center gap-2">
                  <Badge tone="gold">{catLabel(d.category)}</Badge>
                  <b>{d.title.uz}</b>
                  <span className="text-xs text-muted">({d.title.en})</span>
                  <Badge tone={d.active ? "on" : "off"}>
                    {d.active ? "Faol" : "O‘chiq"}
                  </Badge>
                  <span className="ml-auto flex gap-2">
                    <Button
                      variant="ghost"
                      className="!px-3 !py-1.5 text-xs"
                      onClick={() => openEdit(d)}
                    >
                      ✏️
                    </Button>
                    <Button
                      variant="danger"
                      className="!px-3 !py-1.5 text-xs"
                      onClick={() => remove(d)}
                    >
                      🗑
                    </Button>
                  </span>
                </div>
                <p dir="rtl" className="mb-1.5 text-right text-lg leading-8">
                  {d.arabic}
                </p>
                {d.transliteration && (
                  <p className="text-[13px] italic text-primary">
                    {d.transliteration}
                  </p>
                )}
                <p className="mt-1 text-[13.5px]">{d.translation.uz}</p>
                <p className="mt-0.5 text-[12.5px] text-muted">
                  {d.translation.en}
                </p>
              </div>
            ))}
          </div>
        )}
      </Card>

      <Modal
        title={form?.id ? "Duoni tahrirlash" : "Yangi duo"}
        open={form !== null}
        onClose={() => setForm(null)}
      >
        {form && (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Nomi (EN)">
                <Input
                  placeholder="Before Sleeping"
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
                  placeholder="Uxlashdan oldin"
                  value={form.title.uz}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      title: { ...form.title, uz: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Kategoriya">
                <Select
                  value={form.category}
                  onChange={(e) =>
                    setForm({ ...form, category: e.target.value })
                  }
                >
                  {CATEGORIES.map((c) => (
                    <option key={c.value} value={c.value}>
                      {c.label}
                    </option>
                  ))}
                </Select>
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
            </div>

            <Field label="Arabcha matn">
              <textarea
                dir="rtl"
                className={`${textareaCls} text-right text-lg leading-8`}
                placeholder="بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا"
                value={form.arabic}
                onChange={(e) => setForm({ ...form, arabic: e.target.value })}
              />
            </Field>

            <Field label="Lotincha o‘qilishi">
              <textarea
                className={textareaCls}
                placeholder="Bismika Allohumma amutu va ahyo"
                value={form.transliteration}
                onChange={(e) =>
                  setForm({ ...form, transliteration: e.target.value })
                }
              />
            </Field>

            <Field label="Tarjima (UZ)">
              <textarea
                className={textareaCls}
                value={form.translation.uz}
                onChange={(e) =>
                  setForm({
                    ...form,
                    translation: { ...form.translation, uz: e.target.value },
                  })
                }
              />
            </Field>
            <Field label="Tarjima (EN)">
              <textarea
                className={textareaCls}
                value={form.translation.en}
                onChange={(e) =>
                  setForm({
                    ...form,
                    translation: { ...form.translation, en: e.target.value },
                  })
                }
              />
            </Field>

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
              <Button onClick={save} disabled={saving}>
                {saving ? "Saqlanmoqda…" : "Saqlash"}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </>
  );
}
