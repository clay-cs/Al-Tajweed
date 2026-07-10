"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";

import { api, type Localized, type Surah } from "@/lib/api";
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

interface SurahForm {
  id: string | null;
  number: number;
  arabicName: string;
  name: Localized;
  meaning: Localized;
  revelation: "Meccan" | "Medinan";
}

const emptyForm = (nextNumber: number): SurahForm => ({
  id: null,
  number: nextNumber,
  arabicName: "",
  name: { en: "", uz: "" },
  meaning: { en: "", uz: "" },
  revelation: "Meccan",
});

export default function QuranPage() {
  const toast = useToast();
  const [items, setItems] = useState<Surah[] | null>(null);
  const [form, setForm] = useState<SurahForm | null>(null);

  const load = useCallback(() => {
    api<{ items: Surah[] }>("/admin/quran/surahs")
      .then((d) => setItems(d.items))
      .catch((e) => toast(e.message, true));
  }, [toast]);

  useEffect(load, [load]);

  function openNew() {
    const next = items?.length ? Math.max(...items.map((s) => s.number)) + 1 : 1;
    setForm(emptyForm(Math.min(next, 114)));
  }

  function openEdit(s: Surah) {
    setForm({
      id: s._id,
      number: s.number,
      arabicName: s.arabicName,
      name: { ...s.name },
      meaning: { ...s.meaning },
      revelation: s.revelation,
    });
  }

  async function save() {
    if (!form) return;
    try {
      const body = {
        number: Number(form.number),
        arabicName: form.arabicName.trim(),
        name: form.name,
        meaning: form.meaning,
        revelation: form.revelation,
      };
      await api(
        form.id ? `/admin/quran/surahs/${form.id}` : "/admin/quran/surahs",
        { method: form.id ? "PUT" : "POST", body },
      );
      setForm(null);
      toast("Saqlandi ✓");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  async function remove(s: Surah) {
    if (
      !confirm(
        `«${s.name.uz}» surasi va uning ${s.ayahCount} ta oyati o‘chirilsinmi?`,
      )
    )
      return;
    try {
      await api(`/admin/quran/surahs/${s._id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  return (
    <>
      <h1 className="text-2xl font-extrabold">Qur’on — suralar</h1>
      <p className="mb-6 mt-1 text-[13.5px] text-muted">
        Ilovadagi Qur’on bo‘limi shu yerdan boshqariladi. Surani oching va
        oyatlarini kiriting.
      </p>

      <div className="mb-4">
        <Button onClick={openNew}>＋ Yangi sura</Button>
      </div>

      <Card>
        {!items ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : items.length === 0 ? (
          <Empty>Suralar yo‘q — birinchisini qo‘shing</Empty>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr>
                  <Th>#</Th>
                  <Th>Arabcha</Th>
                  <Th>Nomi (UZ)</Th>
                  <Th>Ma’nosi (UZ)</Th>
                  <Th>Nozil</Th>
                  <Th>Oyatlar</Th>
                  <Th>
                    <span className="block text-right">Amallar</span>
                  </Th>
                </tr>
              </thead>
              <tbody>
                {items.map((s) => (
                  <tr key={s._id} className="hover:bg-white/[0.015]">
                    <Td className="font-bold text-primary">{s.number}</Td>
                    <Td className="text-lg" dir="rtl">
                      {s.arabicName}
                    </Td>
                    <Td>
                      <b>{s.name.uz}</b>
                      <div className="text-xs text-muted">{s.name.en}</div>
                    </Td>
                    <Td className="text-muted">{s.meaning.uz}</Td>
                    <Td>
                      <Badge tone={s.revelation === "Meccan" ? "gold" : "info"}>
                        {s.revelation === "Meccan" ? "Makkiy" : "Madaniy"}
                      </Badge>
                    </Td>
                    <Td>
                      <Link
                        href={`/quran/${s.number}`}
                        className="font-bold text-primary hover:underline"
                      >
                        {s.ayahCount} ta oyat →
                      </Link>
                    </Td>
                    <Td className="whitespace-nowrap text-right">
                      <Link href={`/quran/${s.number}`}>
                        <Button variant="ghost" className="!px-3 !py-1.5 text-xs">
                          📃 Oyatlar
                        </Button>
                      </Link>{" "}
                      <Button
                        variant="ghost"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => openEdit(s)}
                      >
                        ✏️
                      </Button>{" "}
                      <Button
                        variant="danger"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => remove(s)}
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
        title={form?.id ? "Surani tahrirlash" : "Yangi sura"}
        open={form !== null}
        onClose={() => setForm(null)}
      >
        {form && (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Sura raqami (1–114)">
                <Input
                  type="number"
                  min={1}
                  max={114}
                  value={form.number}
                  onChange={(e) =>
                    setForm({ ...form, number: Number(e.target.value) })
                  }
                />
              </Field>
              <Field label="Arabcha nomi">
                <Input
                  dir="rtl"
                  placeholder="الفاتحة"
                  value={form.arabicName}
                  onChange={(e) =>
                    setForm({ ...form, arabicName: e.target.value })
                  }
                />
              </Field>
              <Field label="Nomi (EN)">
                <Input
                  placeholder="Al-Fatihah"
                  value={form.name.en}
                  onChange={(e) =>
                    setForm({ ...form, name: { ...form.name, en: e.target.value } })
                  }
                />
              </Field>
              <Field label="Nomi (UZ)">
                <Input
                  placeholder="Fotiha"
                  value={form.name.uz}
                  onChange={(e) =>
                    setForm({ ...form, name: { ...form.name, uz: e.target.value } })
                  }
                />
              </Field>
              <Field label="Ma’nosi (EN)">
                <Input
                  placeholder="The Opening"
                  value={form.meaning.en}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      meaning: { ...form.meaning, en: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Ma’nosi (UZ)">
                <Input
                  placeholder="Ochuvchi"
                  value={form.meaning.uz}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      meaning: { ...form.meaning, uz: e.target.value },
                    })
                  }
                />
              </Field>
            </div>
            <Field label="Nozil bo‘lgan joyi">
              <Select
                value={form.revelation}
                onChange={(e) =>
                  setForm({
                    ...form,
                    revelation: e.target.value as "Meccan" | "Medinan",
                  })
                }
              >
                <option value="Meccan">Makkiy</option>
                <option value="Medinan">Madaniy</option>
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
