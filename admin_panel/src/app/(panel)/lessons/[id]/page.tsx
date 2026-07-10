"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";

import {
  api,
  audioSrc,
  uploadImage,
  type CourseLessonDoc,
  type Lesson,
  type Localized,
} from "@/lib/api";
import {
  Badge,
  Button,
  Card,
  Empty,
  Field,
  Input,
  Modal,
  inputCls,
  useToast,
} from "@/components/ui";

interface ItemForm {
  id: string | null;
  order: number;
  title: Localized;
  body: Localized;
  arabic: string;
  imageUrl: string | null;
}

const emptyForm = (nextOrder: number): ItemForm => ({
  id: null,
  order: nextOrder,
  title: { en: "", uz: "" },
  body: { en: "", uz: "" },
  arabic: "",
  imageUrl: null,
});

const textareaCls = `${inputCls} min-h-24 resize-y`;

export default function CourseContentPage() {
  const params = useParams<{ id: string }>();
  const courseId = params.id;
  const toast = useToast();

  const [course, setCourse] = useState<Lesson | null>(null);
  const [items, setItems] = useState<CourseLessonDoc[] | null>(null);
  const [form, setForm] = useState<ItemForm | null>(null);
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const load = useCallback(() => {
    api<{ items: Lesson[] }>("/admin/lessons")
      .then((d) => setCourse(d.items.find((l) => l._id === courseId) ?? null))
      .catch((e) => toast(e.message, true));
    api<{ items: CourseLessonDoc[] }>(`/admin/lessons/${courseId}/items`)
      .then((d) => setItems(d.items))
      .catch((e) => toast(e.message, true));
  }, [courseId, toast]);

  useEffect(load, [load]);

  function openNew() {
    const next = items?.length
      ? Math.max(...items.map((i) => i.order)) + 1
      : 1;
    setForm(emptyForm(next));
  }

  function openEdit(i: CourseLessonDoc) {
    setForm({
      id: i._id,
      order: i.order,
      title: { ...i.title },
      body: { ...i.body },
      arabic: i.arabic,
      imageUrl: i.imageUrl,
    });
  }

  async function pickImage(file: File | undefined) {
    if (!file || !form) return;
    setUploading(true);
    try {
      const url = await uploadImage(file);
      setForm((f) => (f ? { ...f, imageUrl: url } : f));
      toast("Rasm yuklandi ✓");
    } catch (e) {
      toast(e instanceof Error ? e.message : "Yuklashda xatolik", true);
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = "";
    }
  }

  async function save() {
    if (!form) return;
    setSaving(true);
    try {
      const body = {
        order: Number(form.order),
        title: form.title,
        body: form.body,
        arabic: form.arabic.trim(),
        imageUrl: form.imageUrl,
      };
      await api(
        form.id
          ? `/admin/lesson-items/${form.id}`
          : `/admin/lessons/${courseId}/items`,
        { method: form.id ? "PUT" : "POST", body },
      );
      setForm(null);
      toast("Saqlandi ✓");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    } finally {
      setSaving(false);
    }
  }

  async function remove(i: CourseLessonDoc) {
    if (!confirm(`«${i.title.uz}» darsi o‘chirilsinmi?`)) return;
    try {
      await api(`/admin/lesson-items/${i._id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  return (
    <>
      <div className="mb-1">
        <Link href="/lessons" className="text-muted transition hover:text-ink">
          ← Kurslar
        </Link>
      </div>
      <h1 className="text-2xl font-extrabold">
        {course ? course.title.uz : "Kurs"} — darslar
      </h1>
      <p className="mb-6 mt-1 text-[13.5px] text-muted">
        Har bir dars: sarlavha, matn (EN+UZ), ixtiyoriy arabcha misol va rasm.
        Ilovada shu tartibda ko‘rinadi.
      </p>

      <div className="mb-4">
        <Button onClick={openNew}>＋ Yangi dars</Button>
      </div>

      <Card>
        {!items ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : items.length === 0 ? (
          <Empty>Darslar yo‘q — birinchisini qo‘shing</Empty>
        ) : (
          <div className="space-y-3">
            {items.map((i) => (
              <div
                key={i._id}
                className="flex gap-4 rounded-xl border border-line bg-bg2 p-4"
              >
                {i.imageUrl && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={audioSrc(i.imageUrl)}
                    alt=""
                    className="h-20 w-20 rounded-lg object-cover"
                  />
                )}
                {i.arabic && !i.imageUrl && (
                  <div className="flex h-20 w-20 items-center justify-center rounded-lg bg-primary/10 text-4xl text-primary">
                    {i.arabic.length > 2 ? i.arabic.slice(0, 2) : i.arabic}
                  </div>
                )}
                <div className="min-w-0 flex-1">
                  <div className="mb-1 flex items-center gap-2">
                    <Badge tone="on">{i.order}-dars</Badge>
                    <b className="truncate">{i.title.uz}</b>
                    <span className="ml-auto flex gap-2">
                      <Button
                        variant="ghost"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => openEdit(i)}
                      >
                        ✏️
                      </Button>
                      <Button
                        variant="danger"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => remove(i)}
                      >
                        🗑
                      </Button>
                    </span>
                  </div>
                  <p className="line-clamp-2 text-[13px] text-muted">
                    {i.body.uz}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>

      <Modal
        title={form?.id ? "Darsni tahrirlash" : "Yangi dars"}
        open={form !== null}
        onClose={() => setForm(null)}
      >
        {form && (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Tartib raqami">
                <Input
                  type="number"
                  min={1}
                  value={form.order}
                  onChange={(e) =>
                    setForm({ ...form, order: Number(e.target.value) })
                  }
                />
              </Field>
              <Field label="Arabcha misol (ixtiyoriy)">
                <Input
                  dir="rtl"
                  placeholder="ب"
                  value={form.arabic}
                  onChange={(e) =>
                    setForm({ ...form, arabic: e.target.value })
                  }
                />
              </Field>
              <Field label="Sarlavha (EN)">
                <Input
                  placeholder="Ba — letter 2"
                  value={form.title.en}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      title: { ...form.title, en: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Sarlavha (UZ)">
                <Input
                  placeholder="Bo — 2-harf"
                  value={form.title.uz}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      title: { ...form.title, uz: e.target.value },
                    })
                  }
                />
              </Field>
            </div>

            <Field label="Dars matni (EN)">
              <textarea
                className={textareaCls}
                value={form.body.en}
                onChange={(e) =>
                  setForm({
                    ...form,
                    body: { ...form.body, en: e.target.value },
                  })
                }
              />
            </Field>
            <Field label="Dars matni (UZ)">
              <textarea
                className={textareaCls}
                value={form.body.uz}
                onChange={(e) =>
                  setForm({
                    ...form,
                    body: { ...form.body, uz: e.target.value },
                  })
                }
              />
            </Field>

            <Field label="Rasm (ixtiyoriy, 8 MB gacha)">
              <div className="space-y-2">
                {form.imageUrl && (
                  <div className="flex items-center gap-3">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={audioSrc(form.imageUrl)}
                      alt=""
                      className="h-24 w-24 rounded-lg border border-line object-cover"
                    />
                    <Button
                      variant="danger"
                      className="!px-3 !py-1.5 text-xs"
                      onClick={() => setForm({ ...form, imageUrl: null })}
                    >
                      ✕ Olib tashlash
                    </Button>
                  </div>
                )}
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/*"
                  disabled={uploading}
                  onChange={(e) => pickImage(e.target.files?.[0])}
                  className="block w-full cursor-pointer text-sm text-muted file:mr-3 file:cursor-pointer file:rounded-lg file:border-0 file:bg-primary/15 file:px-4 file:py-2 file:text-sm file:font-semibold file:text-primary hover:file:bg-primary/25"
                />
                {uploading && (
                  <p className="text-xs text-muted">Yuklanmoqda…</p>
                )}
              </div>
            </Field>

            <div className="flex justify-end gap-2.5 pt-2">
              <Button variant="ghost" onClick={() => setForm(null)}>
                Bekor qilish
              </Button>
              <Button onClick={save} disabled={saving || uploading}>
                {saving ? "Saqlanmoqda…" : "Saqlash"}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </>
  );
}
