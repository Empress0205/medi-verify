import { useEffect, useState } from 'react';
import { api, ApiError } from '../api.js';
import { StatTile, Donut, TrendLine, RankedBars } from '../charts.jsx';

const pct = (v) => `${Math.round((v || 0) * 100)}%`;

export default function Overview({ onAuthError }) {
  const [a, setA] = useState(null);
  const [scan, setScan] = useState(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const [an, sc] = await Promise.all([api.analytics(), api.scanStats()]);
        setA(an); setScan(sc);
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) return onAuthError();
        setErr(e.message);
      }
    })();
  }, [onAuthError]);

  if (err) return <div className="error">{err}</div>;
  if (!a || !scan) return <div className="empty">Loading…</div>;

  const s = a.stats;
  const statusSegments = [
    { label: 'Pending', value: s.pending, color: 'var(--st-pending)' },
    { label: 'Under review', value: s.under_review, color: 'var(--st-review)' },
    { label: 'Confirmed', value: s.confirmed, color: 'var(--st-confirmed)' },
    { label: 'Dismissed', value: s.dismissed, color: 'var(--st-dismissed)' },
  ];

  return (
    <>
      <div className="tiles">
        <StatTile label="Total reports" value={s.total} icon="🚩" />
        <StatTile label="Pending queue" value={s.pending} icon="⏳" tone="var(--st-pending)" />
        <StatTile label="Confirmed" value={s.confirmed} icon="⚠️" tone="var(--st-confirmed)" />
        <StatTile label="Confirmation rate" value={`${a.confirmation_rate}%`} icon="✓" />
        <StatTile label="Total scans" value={scan.total} icon="🔍" />
        <StatTile label="Counterfeit rate" value={`${scan.counterfeit_rate}%`} icon="🧪" tone="var(--st-confirmed)" />
        <StatTile label="Avg AI confidence" value={pct(scan.avg_confidence)} icon="📈" />
      </div>

      <div className="grid c2">
        <div className="card">
          <h3>Reports trend</h3>
          <div className="sub">Last 6 months — submitted vs confirmed</div>
          <TrendLine data={a.trend} xKey="month"
            series={[
              { key: 'reports', label: 'Reports', color: 'var(--dv-info)' },
              { key: 'confirmed', label: 'Confirmed', color: 'var(--st-confirmed)' },
            ]} />
        </div>
        <div className="card">
          <h3>Report status</h3>
          <div className="sub">Where reports sit in the workflow</div>
          <Donut segments={statusSegments} centerLabel="reports" />
        </div>
      </div>

      <div className="grid c2">
        <div className="card">
          <h3>Scan detections</h3>
          <div className="sub">Verification volume vs counterfeits caught</div>
          <TrendLine data={scan.trend} xKey="month"
            series={[
              { key: 'scans', label: 'Scans', color: 'var(--brand)' },
              { key: 'counterfeit', label: 'Counterfeit', color: 'var(--st-confirmed)' },
            ]} />
        </div>
        <div className="card">
          <h3>Top flagged medicines</h3>
          <div className="sub">Most-reported products</div>
          <RankedBars items={a.top_medicines} nameKey="name" valueKey="count" />
        </div>
      </div>
    </>
  );
}
