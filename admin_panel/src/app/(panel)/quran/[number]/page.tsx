"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";

import {
  api,
  audioSrc,
  uploadAudio,
  type AyahDoc,
  type Localized,
  type Surah,
} from "@/lib/api";
import {
  Badge,
  Button,
  Card,
  Empty,
  Field,
  Input,
  Modal,
  Td,
  Th,
  inputCls,
  useToast,
} from "@/components/ui";

interface AyahForm {
  id: string | null;
  number: number;
  juz: number;
  arabic: string;
  transliteration: string;
  translation: Localized;
  audioUrl: string | null;
}

const emptyForm = (nextNumber: number, juz: number): AyahForm => ({
  id: null,
  number: nextNumber,
  juz,
  arabic: "",
  transliteration: "",
  translation: { en: "", uz: "" },
  audioUrl: null,
});

const textareaCls = `${inputCls} min-h-20 resize-y`;

export default function AyahsPage() {
  const params = useParams<{ number: string }>();
  const surahNumber = Number(params.number);
  const toast = useToast();

  const [surah, setSurah] = useState<Surah | null>(null);
  const [items, setItems] = useState<AyahDoc[] | null>(null);
  const [form, setForm] = useState<AyahForm | null>(null);
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const load = useCallback(() => {
    api<{ items: Surah[] }>("/admin/quran/surahs")
      .then((d) =>
        setSurah(d.items.find((s) => s.number === surahNumber) ?? null),
      )
      .catch((e) => toast(e.message, true));
    api<{ items: AyahDoc[] }>(`/admin/quran/surahs/${surahNumber}/ayahs`)
      .then((d) => setItems(d.items))
      .catch((e) => toast(e.message, true));
  }, [surahNumber, toast]);

  useEffect(load, [load]);

  function openNew() {
    const next = items?.length ? Math.max(...items.map((a) => a.number)) + 1 : 1;
    const lastJuz = items?.length ? items[items.length - 1].juz : 1;
    setForm(emptyForm(next, lastJuz));
  }

  function openEdit(a: AyahDoc) {
    setForm({
      id: a._id,
      number: a.number,
      juz: a.juz,
      arabic: a.arabic,
      transliteration: a.transliteration,
      translation: { ...a.translation },
      audioUrl: a.audioUrl,
    });
  }

  async function pickAudio(file: File | undefined) {
    if (!file || !form) return;
    setUploading(true);
    try {
      const url = await uploadAudio(file);
      setForm((f) => (f ? { ...f, audioUrl: url } : f));
      toast("Audio yuklandi ✓");
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
        surahNumber,
        number: Number(form.number),
        juz: Number(form.juz),
        arabic: form.arabic.trim(),
        transliteration: form.transliteration.trim(),
        translation: form.translation,
        audioUrl: form.audioUrl,
      };
      await api(
        form.id ? `/admin/quran/ayahs/${form.id}` : "/admin/quran/ayahs",
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

  async function remove(a: AyahDoc) {
    if (!confirm(`${surahNumber}:${a.number} oyati o‘chirilsinmi?`)) return;
    try {
      await api(`/admin/quran/ayahs/${a._id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  return (
    <>
      <div className="mb-1 flex items-center gap-3">
        <Link href="/quran" className="text-muted transition hover:text-ink">
          ← Suralar
        </Link>
      </div>
      <h1 className="text-2xl font-extrabold">
        {surah ? (
          <>
            {surah.number}. {surah.name.uz}{" "}
            <span className="text-primary" dir="rtl">
              {surah.arabicName}
            </span>
          </>
        ) : (
          `${surahNumber}-sura`
        )}
      </h1>
      <p className="mb-6 mt-1 text-[13.5px] text-muted">
        Oyatlar: arabcha matn, lotincha o‘qilishi, tarjima (EN+UZ), pora va
        audio tilovat.
      </p>

      <div className="mb-4">
        <Button onClick={openNew}>＋ Yangi oyat</Button>
      </div>

      <Card>
        {!items ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : items.length === 0 ? (
          <Empty>Oyatlar yo‘q — birinchisini qo‘shing</Empty>
        ) : (
          <div className="space-y-3">
            {items.map((a) => (
              <div
                key={a._id}
                className="rounded-xl border border-line bg-bg2 p-4"
              >
                <div className="mb-2 flex flex-wrap items-center gap-2">
                  <Badge tone="on">
                    {surahNumber}:{a.number}
                  </Badge>
                  <Badge tone="gold">{a.juz}-pora</Badge>
                  {a.audioUrl ? (
                    <audio
                      controls
                      preload="none"
                      src={audioSrc(a.audioUrl)}
                      className="ml-auto h-8 max-w-56"
                    />
                  ) : (
                    <span className="ml-auto text-[11px] text-muted">
                      audio yo‘q
                    </span>
                  )}
                  <Button
                    variant="ghost"
                    className="!px-3 !py-1.5 text-xs"
                    onClick={() => openEdit(a)}
                  >
                    ✏️
                  </Button>
                  <Button
                    variant="danger"
                    className="!px-3 !py-1.5 text-xs"
                    onClick={() => remove(a)}
                  >
                    🗑
                  </Button>
                </div>
                <p dir="rtl" className="mb-1.5 text-right text-xl leading-9">
                  {a.arabic}
                </p>
                {a.transliteration && (
                  <p className="text-[13px] italic text-primary">
                    {a.transliteration}
                  </p>
                )}
                <p className="mt-1 text-[13.5px]">{a.translation.uz}</p>
                <p className="mt-0.5 text-[12.5px] text-muted">
                  {a.translation.en}
                </p>
              </div>
            ))}
          </div>
        )}
      </Card>

      <Modal
        title={form?.id ? "Oyatni tahrirlash" : "Yangi oyat"}
        open={form !== null}
        onClose={() => setForm(null)}
      >
        {form && (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Oyat raqami">
                <Input
                  type="number"
                  min={1}
                  value={form.number}
                  onChange={(e) =>
                    setForm({ ...form, number: Number(e.target.value) })
                  }
                />
              </Field>
              <Field label="Pora (juz, 1–30)">
                <Input
                  type="number"
                  min={1}
                  max={30}
                  value={form.juz}
                  onChange={(e) =>
                    setForm({ ...form, juz: Number(e.target.value) })
                  }
                />
              </Field>
            </div>

            <Field label="Arabcha matn">
              <textarea
                dir="rtl"
                className={`${textareaCls} text-right text-lg leading-8`}
                placeholder="بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
                value={form.arabic}
                onChange={(e) => setForm({ ...form, arabic: e.target.value })}
              />
            </Field>

            <Field label="Lotincha o‘qilishi (transliteratsiya)">
              <textarea
                className={textareaCls}
                placeholder="Bismillahir-Rahmanir-Rahim"
                value={form.transliteration}
                onChange={(e) =>
                  setForm({ ...form, transliteration: e.target.value })
                }
              />
            </Field>

            <Field label="Tarjima (UZ)">
              <textarea
                className={textareaCls}
                placeholder="Mehribon va rahmli Alloh nomi bilan…"
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
                placeholder="In the name of Allah…"
                value={form.translation.en}
                onChange={(e) =>
                  setForm({
                    ...form,
                    translation: { ...form.translation, en: e.target.value },
                  })
                }
              />
            </Field>

            <Field label="Audio tilovat (mp3/m4a, 20 MB gacha)">
              <div className="space-y-2">
                {form.audioUrl && (
                  <div className="flex items-center gap-2">
                    <audio
                      controls
                      src={audioSrc(form.audioUrl)}
                      className="h-9 w-full"
                    />
                    <Button
                      variant="danger"
                      className="!px-3 !py-1.5 text-xs"
                      onClick={() => setForm({ ...form, audioUrl: null })}
                    >
                      ✕
                    </Button>
                  </div>
                )}
                <input
                  ref={fileRef}
                  type="file"
                  accept="audio/*"
                  disabled={uploading}
                  onChange={(e) => pickAudio(e.target.files?.[0])}
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
