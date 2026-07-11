// Viz primitives — hand-built per the dataviz mark specs.

export function StatTile({ label, value, icon, delta, tone }) {
  return (
    <div className="tile">
      <div className="top">
        <span className="label">{label}</span>
        {icon && <span className="ic" style={tone ? { background: `color-mix(in srgb, ${tone} 16%, transparent)` } : undefined}>{icon}</span>}
      </div>
      <div className="value" style={tone ? { color: tone } : undefined}>{value}</div>
      {delta && <div className="delta">{delta}</div>}
    </div>
  );
}

const REPORT_STATUS = {
  pending: ['Pending', 'var(--st-pending)'],
  under_review: ['Under review', 'var(--st-review)'],
  confirmed: ['Confirmed', 'var(--st-confirmed)'],
  dismissed: ['Dismissed', 'var(--st-dismissed)'],
};
const SCAN_STATUS = {
  registered: ['Registered', 'var(--sc-registered)'],
  not_found: ['Not on register', 'var(--sc-not_found)'],
  unknown: ['Unknown', 'var(--sc-unknown)'],
  not_medicine: ['Not medicine', 'var(--sc-not_medicine)'],
};

function Badge({ map, status }) {
  const [label, color] = map[status] || [status, 'var(--muted)'];
  return (
    <span className="badge" style={{ '--bg': color }}>
      <span className="dot" />
      {label}
    </span>
  );
}
export const StatusBadge = ({ status }) => <Badge map={REPORT_STATUS} status={status} />;
export const ScanBadge = ({ status }) => <Badge map={SCAN_STATUS} status={status} />;

// Donut — segments carry their own color; center shows the total.
export function Donut({ segments, centerLabel = 'total' }) {
  const total = segments.reduce((s, x) => s + x.value, 0);
  const r = 52, C = 2 * Math.PI * r, sw = 20;
  let offset = 0;
  return (
    <div className="donut-wrap">
      <div className="donut">
        <svg viewBox="0 0 140 140" width="150" height="150">
          <circle cx="70" cy="70" r={r} fill="none" stroke="var(--grid)" strokeWidth={sw} />
          {total > 0 && segments.map((s, i) => {
            const len = (s.value / total) * C;
            const el = (
              <circle key={i} cx="70" cy="70" r={r} fill="none" stroke={s.color} strokeWidth={sw}
                strokeDasharray={`${len} ${C - len}`} strokeDashoffset={-offset}
                transform="rotate(-90 70 70)" strokeLinecap="butt">
                <title>{`${s.label}: ${s.value}`}</title>
              </circle>
            );
            offset += len;
            return el;
          })}
        </svg>
        <div className="center"><b>{total}</b><small>{centerLabel}</small></div>
      </div>
      <div className="donut-legend">
        {segments.map((s) => (
          <div className="r" key={s.label}>
            <i style={{ background: s.color }} />
            <span className="lab">{s.label}</span>
            <span className="n">{s.value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// Multi-series line chart over evenly-spaced categories (months).
export function TrendLine({ data, xKey, series, height = 190 }) {
  const W = 560, H = height, padL = 28, padR = 12, padT = 12, padB = 26;
  const iw = W - padL - padR, ih = H - padT - padB;
  const max = Math.max(1, ...data.flatMap((d) => series.map((s) => d[s.key])));
  const x = (i) => padL + (data.length === 1 ? iw / 2 : (i / (data.length - 1)) * iw);
  const y = (v) => padT + ih - (v / max) * ih;
  const ticks = [0, Math.ceil(max / 2), max];

  return (
    <>
      <div className="legend" style={{ marginBottom: 8 }}>
        {series.map((s) => <span key={s.key}><i style={{ background: s.color }} />{s.label}</span>)}
      </div>
      <svg className="chart-svg" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="xMidYMid meet">
        {ticks.map((t, i) => (
          <g key={i}>
            <line x1={padL} x2={W - padR} y1={y(t)} y2={y(t)} stroke="var(--grid)" strokeWidth="1" />
            <text x={padL - 6} y={y(t) + 3} textAnchor="end" className="axis-lab">{t}</text>
          </g>
        ))}
        {series.map((s) => {
          const pts = data.map((d, i) => `${x(i)},${y(d[s.key])}`).join(' ');
          return (
            <g key={s.key}>
              <polyline points={pts} fill="none" stroke={s.color} strokeWidth="2"
                strokeLinejoin="round" strokeLinecap="round" />
              {data.map((d, i) => (
                <circle key={i} cx={x(i)} cy={y(d[s.key])} r="3" fill={s.color}>
                  <title>{`${d[xKey]} · ${s.label}: ${d[s.key]}`}</title>
                </circle>
              ))}
            </g>
          );
        })}
        {data.map((d, i) => (
          <text key={i} x={x(i)} y={H - 8} textAnchor="middle" className="axis-lab">{d[xKey]}</text>
        ))}
      </svg>
    </>
  );
}

export function RankedBars({ items, nameKey, valueKey, emptyText = 'No data yet', color = 'var(--seq)' }) {
  if (!items || items.length === 0) return <div className="empty">{emptyText}</div>;
  const max = Math.max(1, ...items.map((i) => i[valueKey]));
  return (
    <div className="rank">
      {items.map((i) => (
        <div className="row" key={i[nameKey]}>
          <div className="name" title={i[nameKey]}>{i[nameKey] || '—'}</div>
          <div className="track"><div className="fill" style={{ width: `${(i[valueKey] / max) * 100}%`, background: color }} /></div>
          <div className="n">{i[valueKey]}</div>
        </div>
      ))}
    </div>
  );
}
