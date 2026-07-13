import { useEffect, useState } from 'react';
import { api, ApiError } from '../api.js';
import { StatTile, Donut, TrendLine, RankedBars } from '../charts.jsx';

const pct = (v) => `${Math.round((v || 0) * 100)}%`;

// Age of the register mirror, in hours, or null if never synced.
function hoursSince(iso) {
  if (!iso) return null;
  return (Date.now() - new Date(iso + 'Z').getTime()) / 36e5;
}

/**
 * Health of the local TMDA register mirror.
 *
 * This is the single most important thing on the page: if the mirror is empty,
 * every scan quietly comes back "not on register" and the app looks like it is
 * working. It is worth showing loudly rather than discovering it from support
 * tickets.
 */
function RegisterHealth({ reg }) {
  if (!reg) return null;

  const count = reg.medicines || 0;
  const age = hoursSince(reg.last_sync);
  const empty = count === 0;
  const stale = age !== null && age > 48;
  const failed = reg.last_sync_ok === false;

  if (empty) {
    return (
      <div className="error" style={{ marginBottom: 16 }}>
        <b>TMDA register is empty.</b> No products are loaded, so every scan will
        return “not on register”. {reg.note ? `Last sync error: ${reg.note}` : 'Check the API logs.'}
      </div>
    );
  }

  const warn = stale || failed;
  return (
    <div
      className="card"
      style={{
        marginBottom: 16,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        borderLeft: `4px solid ${warn ? 'var(--st-pending)' : 'var(--brand)'}`,
      }}
    >
      <span style={{ fontSize: 20 }}>{warn ? '⚠️' : '✅'}</span>
      <div>
        <b>{count.toLocaleString()} products</b> on the TMDA register
        <div className="sub">
          {reg.last_sync
            ? `Last synced ${age < 1 ? 'less than an hour' : `${Math.round(age)} hours`} ago`
            : 'Never synced'}
          {failed && ' · last sync failed'}
          {stale && ' · sync may be stale'}
        </div>
      </div>
    </div>
  );
}

export default function Overview({ onAuthError }) {
  const [a, setA] = useState(null);
  const [scan, setScan] = useState(null);
  const [reg, setReg] = useState(null);
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
      // Non-fatal: the register banner is a diagnostic, not core to the page.
      try { setReg(await api.registerStatus()); } catch (_) { /* ignore */ }
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
      <RegisterHealth reg={reg} />

      <div className="tiles">
        <StatTile label="Total reports" value={s.total} icon="🚩" />
        <StatTile label="Pending queue" value={s.pending} icon="⏳" tone="var(--st-pending)" />
        <StatTile label="Confirmed" value={s.confirmed} icon="⚠️" tone="var(--st-confirmed)" />
        <StatTile label="Confirmation rate" value={`${a.confirmation_rate}%`} icon="✓" />
        <StatTile label="Total scans" value={scan.total} icon="🔍" />
        <StatTile label="Not-found rate" value={`${scan.not_found_rate}%`} icon="🧪" tone="var(--sc-not_found)" />
        <StatTile label="Avg match confidence" value={pct(scan.avg_confidence)} icon="📈" />
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
          <h3>Register checks</h3>
          <div className="sub">Scan volume vs products not found on the register</div>
          <TrendLine data={scan.trend} xKey="month"
            series={[
              { key: 'scans', label: 'Scans', color: 'var(--brand)' },
              { key: 'not_found', label: 'Not on register', color: 'var(--sc-not_found)' },
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
