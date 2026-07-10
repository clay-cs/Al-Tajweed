"use client";

import { useCallback, useEffect, useState } from "react";

import { api, type Localized, type QuizQuestion } from "@/lib/api";
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
  inputCls,
  useToast,
} from "@/components/ui";

interface QuizForm {
  id: string | null;
  question: Localized;
  options: Localized[];
  answer: number;
  category: string;
  active: boolean;
}

const emptyForm = (): QuizForm => ({
  id: null,
  question: { en: "", uz: "" },
  options: Array.from({ length: 4 }, () => ({ en: "", uz: "" })),
  answer: 0,
  category: "tajweed",
  active: true,
});

export default function QuizzesPage() {
  const toast = useToast();
  const [items, setItems] = useState<QuizQuestion[] | null>(null);
  const [form, setForm] = useState<QuizForm | null>(null);

  const load = useCallback(() => {
    api<{ items: QuizQuestion[] }>("/admin/quizzes")
      .then((d) => setItems(d.items))
      .catch((e) => toast(e.message, true));
  }, [toast]);

  useEffect(load, [load]);

  function openNew() {
    setForm(emptyForm());
  }

  function openEdit(q: QuizQuestion) {
    setForm({
      id: q._id,
      question: { ...q.question },
      options: q.options.map((o) => ({ ...o })),
      answer: q.answer,
      category: q.category,
      active: q.active,
    });
  }

  async function save() {
    if (!form) return;
    try {
      const body = {
        question: form.question,
        options: form.options,
        answer: form.answer,
        category: form.category,
        active: form.active,
      };
      await api(form.id ? `/admin/quizzes/${form.id}` : "/admin/quizzes", {
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
    if (!confirm("Savol o‘chirilsinmi?")) return;
    try {
      await api(`/admin/quizzes/${id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  function setOption(i: number, lang: "en" | "uz", value: string) {
    if (!form) return;
    const options = form.options.map((o, j) =>
      j === i ? { ...o, [lang]: value } : o,
    );
    setForm({ ...form, options });
  }

  function removeOption(i: number) {
    if (!form || form.options.length <= 2) return;
    const options = form.options.filter((_, j) => j !== i);
    setForm({
      ...form,
      options,
      answer: Math.min(form.answer, options.length - 1),
    });
  }

  return (
    <>
      <h1 className="text-2xl font-extrabold">Viktorina savollari</h1>
      <p className="mb-6 mt-1 text-[13.5px] text-muted">
        Kunlik viktorina shu savollardan avtomatik tuziladi (EN + UZ).
      </p>

      <div className="mb-4">
        <Button onClick={openNew}>＋ Yangi savol</Button>
      </div>

      <Card>
        {!items ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : items.length === 0 ? (
          <Empty>Savollar yo‘q — birinchisini qo‘shing</Empty>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr>
                  <Th>Savol (UZ)</Th>
                  <Th>Kategoriya</Th>
                  <Th>Variantlar</Th>
                  <Th>Holat</Th>
                  <Th>
                    <span className="block text-right">Amallar</span>
                  </Th>
                </tr>
              </thead>
              <tbody>
                {items.map((q) => (
                  <tr key={q._id} className="hover:bg-white/[0.015]">
                    <Td className="max-w-sm">
                      <b>{q.question.uz}</b>
                      <div className="text-xs text-muted">{q.question.en}</div>
                    </Td>
                    <Td>{q.category}</Td>
                    <Td>{q.options.length} ta</Td>
                    <Td>
                      <Badge tone={q.active ? "on" : "off"}>
                        {q.active ? "Faol" : "O‘chiq"}
                      </Badge>
                    </Td>
                    <Td className="whitespace-nowrap text-right">
                      <Button
                        variant="ghost"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => openEdit(q)}
                      >
                        ✏️
                      </Button>{" "}
                      <Button
                        variant="danger"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => remove(q._id)}
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
        title={form?.id ? "Savolni tahrirlash" : "Yangi savol"}
        open={form !== null}
        onClose={() => setForm(null)}
      >
        {form && (
          <div className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Savol (EN)">
                <Input
                  value={form.question.en}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      question: { ...form.question, en: e.target.value },
                    })
                  }
                />
              </Field>
              <Field label="Savol (UZ)">
                <Input
                  value={form.question.uz}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      question: { ...form.question, uz: e.target.value },
                    })
                  }
                />
              </Field>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Kategoriya">
                <Select
                  value={form.category}
                  onChange={(e) =>
                    setForm({ ...form, category: e.target.value })
                  }
                >
                  <option value="tajweed">Tajvid</option>
                  <option value="quran">Qur’on</option>
                  <option value="general">Umumiy</option>
                </Select>
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

            <Field label="Variantlar — to‘g‘risini belgilang">
              <div className="space-y-2">
                {form.options.map((o, i) => (
                  <div
                    key={i}
                    className="grid grid-cols-[24px_1fr_1fr_30px] items-center gap-2"
                  >
                    <input
                      type="radio"
                      name="answer"
                      className="h-4.5 w-4.5 accent-primary"
                      checked={form.answer === i}
                      onChange={() => setForm({ ...form, answer: i })}
                    />
                    <input
                      className={inputCls}
                      placeholder={`Variant ${i + 1} (EN)`}
                      value={o.en}
                      onChange={(e) => setOption(i, "en", e.target.value)}
                    />
                    <input
                      className={inputCls}
                      placeholder={`Variant ${i + 1} (UZ)`}
                      value={o.uz}
                      onChange={(e) => setOption(i, "uz", e.target.value)}
                    />
                    <button
                      onClick={() => removeOption(i)}
                      className="cursor-pointer text-muted transition hover:text-danger"
                    >
                      ✕
                    </button>
                  </div>
                ))}
              </div>
              <div className="mt-2">
                <Button
                  variant="ghost"
                  className="!px-3 !py-1.5 text-xs"
                  onClick={() =>
                    form.options.length < 6 &&
                    setForm({
                      ...form,
                      options: [...form.options, { en: "", uz: "" }],
                    })
                  }
                >
                  ＋ Variant qo‘shish
                </Button>
              </div>
              <p className="mt-1.5 text-[11.5px] text-muted">
                Chapdagi radio — to‘g‘ri javob. EN / UZ ikkalasi ham majburiy.
              </p>
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
