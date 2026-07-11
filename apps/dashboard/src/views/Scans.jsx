import { useEffect, useState, useCallback } from 'react';
import { api, ApiError } from '../api.js';
import { StatTile, Donut, ScanBadge, TrendLine } from '../charts.jsx';

const pct = (v) => `${Math.round((v || 0) * 100)}%`;
const fmt = (s) => new Date(s).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });

export default function Scans({ onAuthError }) {
  const [stats, setStats] = useState(null);
  const [rows, setRows] = useState([]);
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setErr('');
    try {
      const [st, list] = await Promise.all([api.scanStats(), api.scans({ status, search, limit: 500 })]);
      setStats(st); setRows(list);
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) return onAuthError();
      setErr(e.message);
    } finally { setLoading(false); }
  }, [status, search, onAuthError]);

  useEffect(() => { const t = setTimeout(load, 200); return () => clearTimeout(t); }, [load]);

  if (err) return <div className="error">{err}</div>;
  if (!stats) return <div className="empty">Loading…</div>;

  const segments = [
    { label: 'Registered', value: stats.registered, color: 'var(--sc-registered)' },
    { label: 'Not on register', value: stats.not_found, color: 'var(--sc-not_found)' },
    { label: 'Not medicine', value: stats.not_medicine, color: 'var(--sc-not_medicine)' },
    { label: 'Unknown', value: stats.unknown, color: 'var(--sc-unknown)' },
  ];

  return (
    <>
      <div className="tiles">
        <StatTile label="Total scans" value={stats.total} icon="🔍" />
        <StatTile label="Registered" value={stats.registered} icon="✅" tone="var(--sc-registered)" />
        <StatTile label="Not on register" value={stats.not_found} icon="⚠️" tone="var(--sc-not_found)" />
        <StatTile label="Not-found rate" value={`${stats.not_found_rate}%`} icon="🧪" tone="var(--sc-not_found)" />
        <StatTile label="Not medicine" value={stats.not_medicine} icon="🚫" tone="var(--sc-not_medicine)" />
        <StatTile label="Avg confidence" value={pct(stats.avg_confidence)} icon="📈" />
      </div>

      <div className="grid c2">
        <div className="card">
          <h3>Scan volume</h3>
          <div className="sub">Last 6 months — scans vs products not on the register</div>
          <TrendLine data={stats.trend} xKey="month"
            series={[
              { key: 'scans', label: 'Scans', color: 'var(--brand)' },
              { key: 'not_found', label: 'Not on register', color: 'var(--sc-not_found)' },
            ]} />
        </div>
        <div className="card">
          <h3>Result breakdown</h3>
          <div className="sub">Outcome of every verification</div>
          <Donut segments={segments} centerLabel="scans" />
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <input className="input" placeholder="Search medicine or manufacturer…"
                 value={search} onChange={(e) => setSearch(e.target.value)} />
          <select className="select" value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="">All results</option>
            <option value="registered">Registered</option>
            <option value="not_found">Not on register</option>
            <option value="not_medicine">Not medicine</option>
            <option value="unknown">Unknown</option>
          </select>
          <div className="spacer" />
          <button className="btn btn-sm" onClick={load}>↻ Refresh</button>
        </div>
        {loading ? <div className="empty">Loading…</div>
          : rows.length === 0 ? <div className="empty">No scans match your filters.</div>
          : (
          <div style={{ overflowX: 'auto' }}>
            <table>
              <thead>
                <tr><th>Medicine</th><th>Manufacturer</th><th>Batch</th><th>Result</th><th>Conf.</th><th>Scanned</th></tr>
              </thead>
              <tbody>
                {rows.slice(0, 100).map((r) => (
                  <tr key={r.id} style={{ cursor: 'default' }}>
                    <td>{r.medicine_name || '—'}</td>
                    <td>{r.manufacturer || '—'}</td>
                    <td className="mono">{r.batch_number || '—'}</td>
                    <td><ScanBadge status={r.status} /></td>
                    <td className="mono">{pct(r.confidence_score)}</td>
                    <td className="mono">{fmt(r.scanned_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </>
  );
}
