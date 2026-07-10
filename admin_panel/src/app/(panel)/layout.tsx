"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

import { api, clearToken, getToken, type AdminUser } from "@/lib/api";
import { ToastProvider } from "@/components/ui";

const NAV = [
  { href: "/dashboard", icon: "📊", label: "Boshqaruv" },
  { href: "/quran", icon: "📖", label: "Qur’on" },
  { href: "/users", icon: "👥", label: "Foydalanuvchilar" },
  { href: "/quizzes", icon: "❓", label: "Viktorina savollari" },
  { href: "/lessons", icon: "🎓", label: "Kurslar (Learn)" },
  { href: "/duas", icon: "🤲", label: "Duolar" },
  { href: "/hadiths", icon: "📜", label: "Hadislar" },
];

export default function PanelLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [me, setMe] = useState<AdminUser | null>(null);

  // Auth guard: no token or not an admin → back to login.
  useEffect(() => {
    if (!getToken()) {
      router.replace("/");
      return;
    }
    api<{ user: AdminUser }>("/auth/me")
      .then(({ user }) => {
        if (user.role !== "admin") throw new Error("not admin");
        setMe(user);
      })
      .catch(() => {
        clearToken();
        router.replace("/");
      });
  }, [router]);

  function logout() {
    clearToken();
    router.replace("/");
  }

  if (!me) {
    return (
      <div className="flex min-h-screen items-center justify-center text-muted">
        Yuklanmoqda…
      </div>
    );
  }

  return (
    <ToastProvider>
      <div className="grid min-h-screen md:grid-cols-[250px_1fr]">
        <aside className="flex flex-col border-r border-line bg-bg2 p-4 md:sticky md:top-0 md:h-screen">
          <div className="mb-6 flex items-center gap-3 px-2 pt-2">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[#0b7a61] text-xl">
              📖
            </div>
            <div>
              <b className="block text-[15px]">Quran AI</b>
              <small className="text-[11px] font-medium text-muted">
                Admin panel
              </small>
            </div>
          </div>

          <nav className="space-y-1">
            {NAV.map((item, i) => {
              const active = pathname.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`anim-fade-up stagger-${Math.min(i + 1, 8)} flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-semibold transition-all duration-200 ${
                    active
                      ? "border border-primary/25 bg-gradient-to-br from-primary/20 to-primary/5 text-primary shadow-[0_0_18px_rgba(18,181,135,0.12)]"
                      : "text-muted hover:translate-x-1 hover:bg-card hover:text-ink"
                  }`}
                >
                  <span className="w-5 text-center">{item.icon}</span>
                  {item.label}
                </Link>
              );
            })}
          </nav>

          <div className="mt-auto flex items-center gap-2.5 rounded-2xl border border-line bg-card p-3.5">
            <span className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-gold to-[#b8860b] text-[15px] font-extrabold text-white">
              {me.name.charAt(0).toUpperCase()}
            </span>
            <div className="min-w-0">
              <b className="block truncate text-[13px]">{me.name}</b>
              <small className="block truncate text-[11px] text-muted">
                {me.email}
              </small>
            </div>
            <button
              onClick={logout}
              title="Chiqish"
              className="ml-auto cursor-pointer text-base text-muted transition hover:text-danger"
            >
              ⎋
            </button>
          </div>
        </aside>

        <main className="mx-auto w-full max-w-6xl p-6 md:p-9">{children}</main>
      </div>
    </ToastProvider>
  );
}
