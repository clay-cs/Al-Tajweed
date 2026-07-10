"use client";

import { useEffect, useState } from "react";

import { api, type AdminStats } from "@/lib/api";
import {
  AreaChart,
  BarChart,
  DonutChart,
  HBarChart,
  fillDays,
} from "@/components/charts";
import {
  Avatar,
  Badge,
  Card,
  Empty,
  StatCard,
  Td,
  Th,
  useToast,
} from "@/components/ui";

export default function DashboardPage() {
  const toast = useToast();
  const [data, setData] = useState<AdminStats | null>(null);

  useEffect(() => {
    api<AdminStats>("/admin/stats")
      .then(setData)
      .catch((e) => toast(e.message, true));
  }, [toast]);

  if (!data) return <Empty>Yuklanmoqda…</Empty>;

  const t = data.totals;
  const stats = [
    { icon: "👥", value: t.users, label: "Foydalanuvchilar", tone: "bg-info/15" },
    { icon: "⚡", value: t.activeUsers7d, label: "Faol (7 kun)", tone: "bg-primary/15" },
    { icon: "📜", value: t.hadithReads, label: "O‘qilgan hadislar", tone: "bg-violet/15" },
    { icon: "🧠", value: t.memorizedAyahs, label: "Yodlangan oyatlar", tone: "bg-gold/15" },
    { icon: "🏁", value: t.completedSurahs, label: "Tugatilgan suralar", tone: "bg-primary/10" },
    { icon: "🎓", value: t.lessonsCompleted, label: "Tugatilgan darslar", tone: "bg-info/10" },
    { icon: "📝", value: t.quizAttempts, label: "Quiz urinishlar", tone: "bg-danger/10" },
    { icon: "🎙", value: t.recitations, label: "Tilovatlar", tone: "bg-gold/10" },
  ];

  const regs = fillDays(data.registrationsByDay, data.days);
  const active = fillDays(data.activeByDay, data.days);
  const hadithReads = fillDays(data.hadithReadsByDay, data.days);
  const lessons = fillDays(data.lessonsByDay, data.days);
  const memorized = fillDays(data.memorizedByDay, data.days);

  return (
    <>
      <div className="anim-fade-up">
        <h1 className="text-2xl font-extrabold">Boshqaruv paneli</h1>
        <p className="mb-6 mt-1 flex items-center gap-2 text-[13.5px] text-muted">
          <span className="anim-pulse inline-block h-2 w-2 rounded-full bg-primary" />
          Ilovaning umumiy holati — real vaqtda bazadan.
        </p>
      </div>

      {/* Headline numbers */}
      <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
        {stats.map((s, i) => (
          <StatCard
            key={s.label}
            icon={s.icon}
            value={s.value ?? 0}
            label={s.label}
            toneClass={s.tone}
            className={`stagger-${i + 1}`}
          />
        ))}
      </div>

      {/* Registrations + active users */}
      <div className="mb-5 grid gap-5 xl:grid-cols-2">
        <Card lift className="anim-fade-up stagger-2">
          <h3 className="mb-1 text-[15px] font-bold">
            Ro‘yxatdan o‘tishlar
          </h3>
          <p className="mb-3 text-xs text-muted">
            So‘nggi {data.days} kunda yangi foydalanuvchilar
          </p>
          <AreaChart id="regs" data={regs} color="#60a5fa" />
        </Card>
        <Card lift className="anim-fade-up stagger-3">
          <h3 className="mb-1 text-[15px] font-bold">Faollik</h3>
          <p className="mb-3 text-xs text-muted">
            Kunlik faol foydalanuvchilar (o‘qish, dars, quiz…)
          </p>
          <AreaChart id="active" data={active} color="#12b587" />
        </Card>
      </div>

      {/* Learning activity bars */}
      <div className="mb-5 grid gap-5 xl:grid-cols-3">
        <Card lift className="anim-fade-up stagger-3">
          <h3 className="mb-1 text-[15px] font-bold">O‘qilgan hadislar</h3>
          <p className="mb-2 text-xs text-muted">kunlik, so‘nggi {data.days} kun</p>
          <BarChart data={hadithReads} color="#a78bfa" />
        </Card>
        <Card lift className="anim-fade-up stagger-4">
          <h3 className="mb-1 text-[15px] font-bold">Yodlangan oyatlar</h3>
          <p className="mb-2 text-xs text-muted">kunlik, so‘nggi {data.days} kun</p>
          <BarChart data={memorized} color="#e3b23c" />
        </Card>
        <Card lift className="anim-fade-up stagger-5">
          <h3 className="mb-1 text-[15px] font-bold">Tugatilgan darslar</h3>
          <p className="mb-2 text-xs text-muted">kunlik, so‘nggi {data.days} kun</p>
          <BarChart data={lessons} color="#12b587" />
        </Card>
      </div>

      {/* Quran learning + users donut + content inventory */}
      <div className="mb-5 grid gap-5 xl:grid-cols-2">
        <Card lift className="anim-fade-up stagger-4">
          <h3 className="mb-1 text-[15px] font-bold">
            Qur’on o‘rganish statistikasi
          </h3>
          <p className="mb-4 text-xs text-muted">
            Eng ko‘p yodlangan suralar (oyatlar soni bo‘yicha)
          </p>
          {data.topMemorizedSurahs.length === 0 ? (
            <Empty>Hozircha yodlangan oyat yo‘q</Empty>
          ) : (
            <HBarChart
              items={data.topMemorizedSurahs.map((s) => ({
                label: `${s.surahNumber}. ${s.name}`,
                value: s.count,
              }))}
            />
          )}
        </Card>
        <Card lift className="anim-fade-up stagger-5">
          <h3 className="mb-4 text-[15px] font-bold">Foydalanuvchilar faolligi</h3>
          <DonutChart
            centerValue={String(t.users)}
            centerLabel="jami foydalanuvchi"
            segments={[
              {
                label: "Faol (7 kun)",
                value: t.activeUsers7d,
                color: "#12b587",
              },
              {
                label: "Nofaol",
                value: Math.max(0, t.users - t.activeUsers7d),
                color: "#1f3a31",
              },
            ]}
          />
          <div className="mt-5 grid grid-cols-3 gap-3 border-t border-line pt-4 text-center">
            <div>
              <div className="text-lg font-extrabold">{t.surahs}</div>
              <div className="text-[10.5px] font-semibold text-muted">Suralar</div>
            </div>
            <div>
              <div className="text-lg font-extrabold">
                {t.ayahs.toLocaleString("uz-UZ")}
              </div>
              <div className="text-[10.5px] font-semibold text-muted">Oyatlar</div>
            </div>
            <div>
              <div className="text-lg font-extrabold">{t.hadiths}</div>
              <div className="text-[10.5px] font-semibold text-muted">Hadislar</div>
            </div>
            <div>
              <div className="text-lg font-extrabold">{t.duas}</div>
              <div className="text-[10.5px] font-semibold text-muted">Duolar</div>
            </div>
            <div>
              <div className="text-lg font-extrabold">{t.courses}</div>
              <div className="text-[10.5px] font-semibold text-muted">Kurslar</div>
            </div>
            <div>
              <div className="text-lg font-extrabold">{t.quizzes}</div>
              <div className="text-[10.5px] font-semibold text-muted">Quiz savollar</div>
            </div>
          </div>
        </Card>
      </div>

      {/* Recent users */}
      <Card lift className="anim-fade-up stagger-6">
        <h3 className="mb-4 text-[15px] font-bold">Yangi foydalanuvchilar</h3>
        {data.recentUsers.length === 0 ? (
          <Empty>Hozircha foydalanuvchi yo‘q</Empty>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr>
                  <Th />
                  <Th>Ism</Th>
                  <Th>Email</Th>
                  <Th>Rol</Th>
                  <Th>XP</Th>
                  <Th>Streak</Th>
                </tr>
              </thead>
              <tbody>
                {data.recentUsers.map((u) => (
                  <tr key={u.id} className="transition hover:bg-white/[0.02]">
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
                    <Td>{u.xp}</Td>
                    <Td>🔥 {u.streak}</Td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </>
  );
}
