"use client";

import { useCallback, useEffect, useState } from "react";

import { api, type AdminUser } from "@/lib/api";
import {
  Avatar,
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

interface UsersResponse {
  items: AdminUser[];
  total: number;
  page: number;
  pages: number;
}

export default function UsersPage() {
  const toast = useToast();
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<UsersResponse | null>(null);
  const [editing, setEditing] = useState<AdminUser | null>(null);
  const [form, setForm] = useState({ name: "", role: "user", password: "" });

  const load = useCallback(async () => {
    try {
      const res = await api<UsersResponse>(
        `/admin/users?q=${encodeURIComponent(query)}&page=${page}`,
      );
      setData(res);
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }, [query, page, toast]);

  // Debounced search + pagination.
  useEffect(() => {
    const t = setTimeout(load, query ? 350 : 0);
    return () => clearTimeout(t);
  }, [load, query]);

  function openEdit(u: AdminUser) {
    setForm({ name: u.name, role: u.role, password: "" });
    setEditing(u);
  }

  async function save() {
    if (!editing) return;
    try {
      const body: Record<string, string> = {
        name: form.name.trim(),
        role: form.role,
      };
      if (form.password) body.password = form.password;
      await api(`/admin/users/${editing.id}`, { method: "PATCH", body });
      setEditing(null);
      toast("Saqlandi ✓");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  async function remove(u: AdminUser) {
    if (!confirm(`«${u.name}» va uning BARCHA ma’lumotlari o‘chirilsinmi?`)) return;
    try {
      await api(`/admin/users/${u.id}`, { method: "DELETE" });
      toast("O‘chirildi");
      load();
    } catch (e) {
      toast(e instanceof Error ? e.message : "Xatolik", true);
    }
  }

  return (
    <>
      <h1 className="text-2xl font-extrabold">Foydalanuvchilar</h1>
      <p className="mb-6 mt-1 text-[13.5px] text-muted">
        Hisoblarni ko‘rish, tahrirlash, parol tiklash va o‘chirish.
      </p>

      <div className="mb-4 max-w-xs">
        <Input
          placeholder="🔍 Ism yoki email bo‘yicha qidirish…"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setPage(1);
          }}
        />
      </div>

      <Card>
        {!data ? (
          <Empty>Yuklanmoqda…</Empty>
        ) : data.items.length === 0 ? (
          <Empty>Topilmadi</Empty>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr>
                  <Th />
                  <Th>Ism</Th>
                  <Th>Email</Th>
                  <Th>Rol</Th>
                  <Th>XP / Daraja</Th>
                  <Th>Streak</Th>
                  <Th>Sahifa</Th>
                  <Th>Tilovat</Th>
                  <Th>
                    <span className="block text-right">Amallar</span>
                  </Th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((u) => (
                  <tr key={u.id} className="hover:bg-white/[0.015]">
                    <Td>
                      <Avatar name={u.name} />
                    </Td>
                    <Td className="font-bold">{u.name}</Td>
                    <Td className="text-muted">{u.email}</Td>
                    <Td>
                      <Badge tone={u.role === "admin" ? "gold" : "info"}>
                        {u.role === "admin" ? "Admin" : "User"}
                      </Badge>
                    </Td>
                    <Td>
                      {u.xp} XP · Lv {u.level}
                    </Td>
                    <Td>🔥 {u.streak}</Td>
                    <Td>{u.pagesRead}</Td>
                    <Td>{u.recitationCount}</Td>
                    <Td className="whitespace-nowrap text-right">
                      <Button
                        variant="ghost"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => openEdit(u)}
                      >
                        ✏️
                      </Button>{" "}
                      <Button
                        variant="danger"
                        className="!px-3 !py-1.5 text-xs"
                        onClick={() => remove(u)}
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

        {data && (
          <div className="mt-4 flex items-center justify-end gap-3 text-[13px] text-muted">
            {data.pages > 1 ? (
              <>
                <Button
                  variant="ghost"
                  className="!px-3 !py-1.5 text-xs"
                  disabled={data.page <= 1}
                  onClick={() => setPage((p) => p - 1)}
                >
                  ←
                </Button>
                <span>
                  {data.page} / {data.pages}
                </span>
                <Button
                  variant="ghost"
                  className="!px-3 !py-1.5 text-xs"
                  disabled={data.page >= data.pages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  →
                </Button>
              </>
            ) : (
              <span>Jami: {data.total}</span>
            )}
          </div>
        )}
      </Card>

      <Modal
        title="Foydalanuvchini tahrirlash"
        open={editing !== null}
        onClose={() => setEditing(null)}
      >
        <div className="space-y-4">
          <Field label="Ism">
            <Input
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
          </Field>
          <Field label="Rol">
            <Select
              value={form.role}
              onChange={(e) => setForm({ ...form, role: e.target.value })}
            >
              <option value="user">Foydalanuvchi</option>
              <option value="admin">Admin</option>
            </Select>
          </Field>
          <Field label="Yangi parol (ixtiyoriy)">
            <Input
              placeholder="Bo‘sh qoldirsangiz o‘zgarmaydi"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
            />
          </Field>
          <div className="flex justify-end gap-2.5 pt-2">
            <Button variant="ghost" onClick={() => setEditing(null)}>
              Bekor qilish
            </Button>
            <Button onClick={save}>Saqlash</Button>
          </div>
        </div>
      </Modal>
    </>
  );
}
