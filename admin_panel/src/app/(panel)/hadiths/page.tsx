"use client";

import { useCallback, useEffect, useState } from "react";

import { api, type HadithDoc, type Localized } from "@/lib/api";
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

const GRADES = ["Sahih", "Hasan", "Da'if"];

interface HadithForm {
  id: string | null;
  book: string;
  bookNumber: number;
  chapter: string;
  hadithNumber: number;
  narrator: string;
  arabic: string;
  translation: Localized;
  grade: string;
  tags: string; // comma-separated in the form
  order: number;
  active: boolean;
}

const emptyForm = (nextOrder: number): HadithForm => ({
  id: null,
  book: "",
  bookNumber: 1,
  chapter: "",
  hadithNumber: 1,
  narrator: "",
  arabic: "",
  translation: { en: "", uz: "" },
  grade: "Sahih",
  tags: "",
  order: nextOrder,
  active: true,
});

const textareaCls = `${inputCls} min-h-20 resize-y`;

export default function HadithsPage() {
  const toast = useToast();
  const [items, setItems] = useState<HadithDoc[] | null>(null);
  const [form, setForm] = useState<HadithForm | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(() => {
    api<{ items: HadithDoc[] }>("/admin/hadiths")
      .then((d) => setItems(d.items))
      .catch((e) => toast(e.message, true));
  }, [toast]);

  useEffect(load, [load]);

  function openNew() {
    const next = items?.length
      ? Math.max(...items.map((h) => h.order)) + 1
      : 1;
    setForm(emptyForm(next));
  }

  function openEdit(h: HadithDoc) {
    setForm({
      id: h._id,
      book: h.book,
      bookNumber: h.bookNumber,
      chapter: h.chapter,
      hadithNumber: h.hadithNumber,
      narrator: h.narrator,
      arabic: h.arabic,
      translation: { ...h.translation },
      grade: h.grade,
      tags: (h.tags ?? []).join(", "),
      order: h.order,
      active: h.active,
    });
  }

  async function save() {
    if (!form) return;
    setSaving(true);
    try {
      const body = {
        book: form.book.trim(),
        bookNumber: Number(form.bookNumber) || 1,
        chapter: form.chapter.trim(),
        hadithNumber: Number(form.hadithNumber),
        narrator: form.narrator.trim(),
        arabic: form.arabic.trim(),
        translation: form.translation,
        grade: form.grade,
        tags: form.tags
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean),
        order: Number(form.order),
        active: form.active,
      };
      await api(form.id ? `/admin/hadiths/${form.id}` : "/admin/hadiths", {
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

  async function remove(h: HadithDoc) {
    if (!confirm(`«${h.book} №${h.hadithNumber}» hadisi o‘chirilsinmi?`))
      return;
    try {
      await api(`/admin/hadiths/${h._id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  return (
    <>
      <div className="anim-fade-up">
        <h1 className="text-2xl font-extrabold">Hadislar</h1>
        <p className="mb-6 mt-1 text-[13.5px] text-muted">
          Ilovadagi «Hadislar» bo‘limi va «Kun hadisi»: kitob, bob, raqamlar,
          roviy, daraja, arabcha matn, tarjima (UZ + EN) va teglar.
        </p>
      </div>

      <div className="anim-fade-up stagger-1 mb-4">
        <Button onClick={openNew}>＋ Yangi hadis</Button>
      </div>

      <Card className="anim-fade-up stagger-2">
        {!items ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : items.length === 0 ? (
          <Empty>Hadislar yo‘q — birinchisini qo‘shing</Empty>
        ) : (
          <div className="space-y-3">
            {items.map((h) => (
              <div
                key={h._id}
                className="lift rounded-xl border border-line bg-bg2 p-4"
              >
                <div className="mb-2 flex flex-wrap items-center gap-2">
                  <Badge tone={h.grade === "Sahih" ? "on" : "gold"}>
                    {h.grade}
                  </Badge>
                  <b>
                    {h.book} • №{h.hadithNumber}
                  </b>
                  {h.chapter && (
                    <span className="text-xs text-muted">— {h.chapter}</span>
                  )}
                  <Badge tone={h.active ? "on" : "off"}>
                    {h.active ? "Faol" : "O‘chiq"}
                  </Badge>
                  <span className="ml-auto flex gap-2">
                    <Button
                      variant="ghost"
                      className="!px-3 !py-1.5 text-xs"
                      onClick={() => openEdit(h)}
                    >
                      ✏️
                    </Button>
                    <Button
                      variant="danger"
                      className="!px-3 !py-1.5 text-xs"
                      onClick={() => remove(h)}
                    >
                      🗑
                    </Button>
                  </span>
                </div>
                {h.narrator && (
                  <p className="mb-1 text-[12px] text-muted">{h.narrator}</p>
                )}
                <p dir="rtl" className="mb-1.5 text-right text-lg leading-8">
                  {h.arabic}
                </p>
                <p className="mt-1 text-[13.5px]">{h.translation.uz}</p>
                <p className="mt-0.5 text-[12.5px] text-muted">
                  {h.translation.en}
                </p>
                {h.tags?.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    {h.tags.map((t) => (
                      <span
                        key={t}
                        className="rounded-full border border-primary/25 bg-primary/10 px-2 py-0.5 text-[10.5px] font-bold text-primary"
                      >
                        #{t}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </Card>

      <Modal
        title={form?.id ? "Hadisni tahrirlash" : "Yangi hadis"}
        open={form !== null}
        onClose={() => setForm(null)}
      >
        {form && (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Kitob (to‘plam)">
                <Input
                  placeholder="Sahih al-Buxoriy"
                  value={form.book}
                  onChange={(e) => setForm({ ...form, book: e.target.value })}
                />
              </Field>
              <Field label="Kitob raqami">
                <Input
                  type="number"
                  value={form.bookNumber}
                  onChange={(e) =>
                    setForm({ ...form, bookNumber: Number(e.target.value) })
                  }
                />
              </Field>
              <Field label="Bob (chapter)">
                <Input
                  placeholder="Vahiyning boshlanishi"
                  value={form.chapter}
                  onChange={(e) =>
                    setForm({ ...form, chapter: e.target.value })
                  }
                />
              </Field>
              <Field label="Hadis raqami">
                <Input
                  type="number"
                  value={form.hadithNumber}
                  onChange={(e) =>
                    setForm({ ...form, hadithNumber: Number(e.target.value) })
                  }
                />
              </Field>
              <Field label="Roviy">
                <Input
                  placeholder="Umar ibn Xattob"
                  value={form.narrator}
                  onChange={(e) =>
                    setForm({ ...form, narrator: e.target.value })
                  }
                />
              </Field>
              <Field label="Daraja">
                <Select
                  value={form.grade}
                  onChange={(e) => setForm({ ...form, grade: e.target.value })}
                >
                  {GRADES.map((g) => (
                    <option key={g} value={g}>
                      {g}
                    </option>
                  ))}
                </Select>
              </Field>
            </div>

            <Field label="Arabcha matn">
              <textarea
                dir="rtl"
                className={`${textareaCls} text-right text-lg leading-8`}
                placeholder="إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ"
                value={form.arabic}
                onChange={(e) => setForm({ ...form, arabic: e.target.value })}
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

            <Field label="Teglar (vergul bilan)">
              <Input
                placeholder="niyat, ibodat"
                value={form.tags}
                onChange={(e) => setForm({ ...form, tags: e.target.value })}
              />
            </Field>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Tartib">
                <Input
                  type="number"
                  value={form.order}
                  onChange={(e) =>
                    setForm({ ...form, order: Number(e.target.value) })
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
            </div>

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
