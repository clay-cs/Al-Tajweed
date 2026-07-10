"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { api, getToken, setToken, type AdminUser } from "@/lib/api";
import { Button, Field, Input } from "@/components/ui";

interface LoginResponse {
  token: string;
  user: AdminUser;
}

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  // Already signed in → straight to the dashboard.
  useEffect(() => {
    if (getToken()) router.replace("/dashboard");
  }, [router]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const data = await api<LoginResponse>("/auth/login", {
        method: "POST",
        body: { email: email.trim(), password },
      });
      if (data.user.role !== "admin") {
        throw new Error("Bu hisob admin emas");
      }
      setToken(data.token);
      router.replace("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center p-6">
      <form
        onSubmit={submit}
        className="w-full max-w-sm rounded-3xl border border-line bg-card p-10 shadow-2xl"
      >
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-[#0b7a61] text-3xl shadow-lg shadow-primary/35">
          📖
        </div>
        <h1 className="text-center text-xl font-extrabold">Quran AI Admin</h1>
        <p className="mb-6 mt-1.5 text-center text-[13px] text-muted">
          Boshqaruv paneliga kirish
        </p>

        {error && (
          <div className="mb-4 rounded-lg border border-danger/35 bg-danger/10 px-3.5 py-2.5 text-[13px] text-danger">
            {error}
          </div>
        )}

        <div className="space-y-4">
          <Field label="Email">
            <Input
              type="email"
              placeholder="admin@quranai.uz"
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </Field>
          <Field label="Parol">
            <Input
              type="password"
              placeholder="••••••••"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </Field>
          <Button type="submit" disabled={loading} className="w-full">
            {loading ? "Kirilmoqda…" : "Kirish →"}
          </Button>
        </div>
      </form>
    </main>
  );
}
