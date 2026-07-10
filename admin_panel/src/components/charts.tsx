"use client";

// Dependency-free SVG charts for the dashboard. Each chart animates in
// via the keyframes defined in globals.css.

export interface DayPoint {
  day: string; // YYYY-MM-DD
  count: number;
}

/** Fills missing calendar days with 0 so gaps are visible. */
export function fillDays(points: DayPoint[], days: number): DayPoint[] {
  const by = Object.fromEntries(points.map((p) => [p.day, p.count]));
  return Array.from({ length: days }, (_, i) => {
    const d = new Date(Date.now() - (days - 1 - i) * 864e5)
      .toISOString()
      .slice(0, 10);
    return { day: d, count: by[d] ?? 0 };
  });
}

const fmtDay = (day: string) => day.slice(5).replace("-", "/");

/** Smooth area chart with a drawn line, gradient fill and hover dots. */
export function AreaChart({
  data,
  color = "#12b587",
  height = 180,
  id,
}: {
  data: DayPoint[];
  color?: string;
  height?: number;
  id: string; // unique gradient id per instance
}) {
  const w = 720;
  const h = height;
  const pad = { top: 14, right: 10, bottom: 24, left: 30 };
  const max = Math.max(1, ...data.map((d) => d.count));
  const iw = w - pad.left - pad.right;
  const ih = h - pad.top - pad.bottom;

  const x = (i: number) =>
    pad.left + (data.length < 2 ? iw / 2 : (i / (data.length - 1)) * iw);
  const y = (v: number) => pad.top + ih - (v / max) * ih;

  const line = data
    .map((d, i) => `${i === 0 ? "M" : "L"}${x(i).toFixed(1)},${y(d.count).toFixed(1)}`)
    .join(" ");
  const area = `${line} L${x(data.length - 1).toFixed(1)},${pad.top + ih} L${x(0).toFixed(1)},${pad.top + ih} Z`;

  // Y-axis guides: 0, half, max.
  const guides = [0, Math.ceil(max / 2), max];
  // X labels: ~6 evenly spaced.
  const step = Math.max(1, Math.round(data.length / 6));

  return (
    <svg
      viewBox={`0 0 ${w} ${h}`}
      className="w-full"
      role="img"
      aria-label="area chart"
    >
      <defs>
        <linearGradient id={`ag-${id}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.35" />
          <stop offset="100%" stopColor={color} stopOpacity="0.02" />
        </linearGradient>
      </defs>
      {guides.map((g) => (
        <g key={g}>
          <line
            x1={pad.left}
            x2={w - pad.right}
            y1={y(g)}
            y2={y(g)}
            stroke="#1f3a31"
            strokeWidth="1"
            strokeDasharray="3 5"
          />
          <text
            x={pad.left - 6}
            y={y(g) + 3.5}
            textAnchor="end"
            fontSize="10"
            fill="#8faaa1"
          >
            {g}
          </text>
        </g>
      ))}
      <path d={area} fill={`url(#ag-${id})`} className="anim-area" />
      <path
        d={line}
        fill="none"
        stroke={color}
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="anim-line"
        style={{ strokeDasharray: 2000, ["--line-len" as string]: 2000 }}
      />
      {data.map((d, i) => (
        <g key={d.day}>
          <circle
            cx={x(i)}
            cy={y(d.count)}
            r={d.count > 0 ? 3 : 0}
            fill="#0b1512"
            stroke={color}
            strokeWidth="2"
          >
            <title>{`${fmtDay(d.day)}: ${d.count}`}</title>
          </circle>
          {i % step === 0 && (
            <text
              x={x(i)}
              y={h - 6}
              textAnchor="middle"
              fontSize="10"
              fill="#8faaa1"
            >
              {fmtDay(d.day)}
            </text>
          )}
        </g>
      ))}
    </svg>
  );
}

/** Vertical bar chart for daily counts. */
export function BarChart({
  data,
  color = "#12b587",
  height = 150,
}: {
  data: DayPoint[];
  color?: string;
  height?: number;
}) {
  const max = Math.max(1, ...data.map((d) => d.count));
  const step = Math.max(1, Math.round(data.length / 6));
  return (
    <div style={{ height }} className="flex items-end gap-[3px] pt-2">
      {data.map((d, i) => (
        <div
          key={d.day}
          className="group relative flex h-full flex-1 flex-col items-center justify-end gap-1.5"
          title={`${fmtDay(d.day)}: ${d.count}`}
        >
          <div
            className="anim-bar w-full rounded-t"
            style={{
              height: `${Math.max(2, (d.count / max) * 100)}%`,
              background:
                d.count > 0
                  ? `linear-gradient(to top, ${color}55, ${color})`
                  : "#1f3a31",
              animationDelay: `${i * 18}ms`,
            }}
          />
          <span className="h-3 text-[9.5px] font-semibold text-muted">
            {i % step === 0 ? fmtDay(d.day) : ""}
          </span>
        </div>
      ))}
    </div>
  );
}

/** Horizontal labelled bars — e.g. top memorized surahs. */
export function HBarChart({
  items,
  color = "#e3b23c",
}: {
  items: { label: string; value: number }[];
  color?: string;
}) {
  const max = Math.max(1, ...items.map((i) => i.value));
  return (
    <div className="space-y-3">
      {items.map((it, i) => (
        <div key={it.label}>
          <div className="mb-1 flex items-center justify-between text-[12.5px]">
            <span className="font-semibold">{it.label}</span>
            <span className="font-bold text-muted">{it.value}</span>
          </div>
          <div className="h-2.5 overflow-hidden rounded-full bg-bg2">
            <div
              className="anim-bar-x h-full rounded-full"
              style={{
                width: `${(it.value / max) * 100}%`,
                background: `linear-gradient(to right, ${color}88, ${color})`,
                animationDelay: `${i * 70}ms`,
              }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}

/** Donut with a centred headline value and a small legend. */
export function DonutChart({
  segments,
  centerValue,
  centerLabel,
}: {
  segments: { label: string; value: number; color: string }[];
  centerValue: string;
  centerLabel: string;
}) {
  const total = Math.max(
    1,
    segments.reduce((s, x) => s + x.value, 0),
  );
  const R = 52;
  const C = 2 * Math.PI * R;
  let acc = 0;

  return (
    <div className="flex items-center gap-6">
      <svg viewBox="0 0 140 140" className="h-36 w-36 shrink-0 -rotate-90">
        <circle
          cx="70"
          cy="70"
          r={R}
          fill="none"
          stroke="#1f3a31"
          strokeWidth="16"
        />
        {segments.map((s) => {
          const len = (s.value / total) * C;
          const el = (
            <circle
              key={s.label}
              cx="70"
              cy="70"
              r={R}
              fill="none"
              stroke={s.color}
              strokeWidth="16"
              strokeLinecap="butt"
              strokeDasharray={`${len} ${C - len}`}
              strokeDashoffset={-acc}
              className="anim-donut"
            >
              <title>{`${s.label}: ${s.value}`}</title>
            </circle>
          );
          acc += len;
          return el;
        })}
      </svg>
      <div className="min-w-0">
        <div className="text-3xl font-extrabold leading-none">
          {centerValue}
        </div>
        <div className="mb-3 mt-1 text-xs font-semibold text-muted">
          {centerLabel}
        </div>
        <div className="space-y-1.5">
          {segments.map((s) => (
            <div key={s.label} className="flex items-center gap-2 text-[12px]">
              <span
                className="h-2.5 w-2.5 rounded-full"
                style={{ background: s.color }}
              />
              <span className="text-muted">{s.label}</span>
              <b className="ml-auto">{s.value}</b>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
