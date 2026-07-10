"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";

// ── Buttons ───────────────────────────────────────────────────────────

type BtnVariant = "primary" | "ghost" | "danger";

export function Button({
  variant = "primary",
  className = "",
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: BtnVariant }) {
  const styles: Record<BtnVariant, string> = {
    primary:
      "bg-gradient-to-br from-primary to-primary2 text-white font-bold hover:brightness-110",
    ghost: "border border-line text-ink font-semibold hover:bg-card",
    danger:
      "bg-danger/10 text-danger border border-danger/30 font-semibold hover:bg-danger/20",
  };
  return (
    <button
      className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm transition cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed ${styles[variant]} ${className}`}
      {...props}
    />
  );
}

// ── Form fields ───────────────────────────────────────────────────────

export function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted">
        {label}
      </span>
      {children}
    </label>
  );
}

export const inputCls =
  "w-full rounded-lg border border-line bg-bg2 px-3.5 py-2.5 text-sm text-ink outline-none focus:border-primary";

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input className={inputCls} {...props} />;
}

export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return <select className={inputCls} {...props} />;
}

// ── Cards / badges ────────────────────────────────────────────────────

export function Card({
  className = "",
  lift = false,
  children,
}: {
  className?: string;
  lift?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div
      className={`rounded-2xl border border-line bg-card p-5 ${
        lift ? "lift" : ""
      } ${className}`}
    >
      {children}
    </div>
  );
}

export function Badge({
  tone,
  children,
}: {
  tone: "gold" | "info" | "on" | "off";
  children: React.ReactNode;
}) {
  const styles = {
    gold: "bg-gold/15 text-gold border-gold/30",
    info: "bg-info/10 text-info border-info/25",
    on: "bg-primary/10 text-primary border-primary/30",
    off: "bg-muted/10 text-muted border-line",
  }[tone];
  return (
    <span
      className={`inline-block rounded-full border px-2.5 py-0.5 text-[11px] font-bold ${styles}`}
    >
      {children}
    </span>
  );
}

export function Avatar({ name }: { name: string }) {
  return (
    <span className="inline-flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-primary to-primary2 text-sm font-bold text-white">
      {(name || "?").charAt(0).toUpperCase()}
    </span>
  );
}

/** Count-up number: animates from 0 to `value` on mount. */
export function CountUp({ value }: { value: number }) {
  const [shown, setShown] = useState(0);
  const raf = useRef(0);

  useEffect(() => {
    const start = performance.now();
    const dur = 750;
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / dur);
      const eased = 1 - Math.pow(1 - t, 3);
      setShown(Math.round(value * eased));
      if (t < 1) raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf.current);
  }, [value]);

  return <>{shown.toLocaleString("uz-UZ")}</>;
}

export function StatCard({
  icon,
  value,
  label,
  toneClass,
  className = "",
}: {
  icon: string;
  value: number | string;
  label: string;
  toneClass: string;
  className?: string;
}) {
  return (
    <Card lift className={`anim-fade-up ${className}`}>
      <div
        className={`mb-3 flex h-11 w-11 items-center justify-center rounded-xl text-xl ${toneClass}`}
      >
        {icon}
      </div>
      <div className="text-2xl font-extrabold">
        {typeof value === "number" ? <CountUp value={value} /> : value}
      </div>
      <div className="mt-0.5 text-xs font-semibold text-muted">{label}</div>
    </Card>
  );
}

// ── Modal ─────────────────────────────────────────────────────────────

export function Modal({
  title,
  open,
  onClose,
  children,
}: {
  title: string;
  open: boolean;
  onClose: () => void;
  children: React.ReactNode;
}) {
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/60 p-6 pt-16 backdrop-blur-sm"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div className="anim-pop w-full max-w-xl rounded-2xl border border-line bg-card2 p-7 shadow-2xl">
        <h3 className="mb-5 text-lg font-extrabold">{title}</h3>
        {children}
      </div>
    </div>
  );
}

// ── Toast ─────────────────────────────────────────────────────────────

interface ToastState {
  message: string;
  error: boolean;
}

const ToastContext = createContext<(msg: string, error?: boolean) => void>(
  () => {},
);

export const useToast = () => useContext(ToastContext);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toast, setToast] = useState<ToastState | null>(null);

  const show = useCallback((message: string, error = false) => {
    setToast({ message, error });
    setTimeout(() => setToast(null), 2600);
  }, []);

  return (
    <ToastContext.Provider value={show}>
      {children}
      {toast && (
        <div
          className={`anim-toast fixed bottom-7 left-1/2 z-[99] rounded-xl border bg-card2 px-6 py-3 text-sm font-semibold shadow-2xl ${
            toast.error ? "border-danger" : "border-primary"
          }`}
        >
          {toast.message}
        </div>
      )}
    </ToastContext.Provider>
  );
}

// ── Table helpers ─────────────────────────────────────────────────────

export function Th({ children }: { children?: React.ReactNode }) {
  return (
    <th className="border-b border-line px-3 py-2 text-left text-[10.5px] font-bold uppercase tracking-wider text-muted">
      {children}
    </th>
  );
}

export function Td({
  className = "",
  children,
  ...props
}: React.TdHTMLAttributes<HTMLTableCellElement>) {
  return (
    <td
      className={`border-b border-line px-3 py-3 align-middle text-[13.5px] ${className}`}
      {...props}
    >
      {children}
    </td>
  );
}

export function Empty({ children }: { children: React.ReactNode }) {
  return (
    <div className="py-10 text-center text-sm text-muted">{children}</div>
  );
}
