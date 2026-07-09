import { useEffect, useState, useCallback, useMemo } from 'react';
import { api, ApiError } from '../api.js';
import { StatusBadge } from '../charts.jsx';

const NEXT = {
  pending: [
    { status: 'under_review', label: 'Start review', cls: 'btn-primary' },
    { status: 'dismissed', label: 'Dismiss', cls: 'btn-ghost' },
  ],
  under_review: [
    { status: 'confirmed', label: 'Confirm counterfeit', cls: 'btn-danger' },
    { status: 'dismissed', label: 'Dismiss', cls: 'btn-ghost' },
  ],
  confirmed: [], dismissed: [],
};
const pct = (v) => `${Math.round((v || 0) * 100)}%`;
const fmt = (s) => (s ? new Date(s).toLocaleString(undefined, { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—');
const PAGE = 8;

export default function Reports({ onAuthError }) {
  const [rows, setRows] = useState([]);
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState({ key: 'submitted_at', dir: 'desc' });
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState('');
  const [sel, setSel] = useState(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api.reports({ status, search, limit: 500 });
      setRows(r);
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) return onAuthError();
      setErr(e.message);
    } finally { setLoading(false); }
  }, [status, search, onAuthError]);

  useEffect(() => { const t = setTimeout(load, 200); return () => clearTimeout(t); }, [load]);
  useEffect(() => { setPage(0); }, [status, search, sort]);

  const sorted = useMemo(() => {
    const s = [...rows].sort((a, b) => {
      const av = a[sort.key], bv = b[sort.key];
      const c = av < bv ? -1 : av > bv ? 1 : 0;
      return sort.dir === 'asc' ? c : -c;
    });
    return s;
  }, [rows, sort]);
  const pages = Math.max(1, Math.ceil(sorted.length / PAGE));
  const view = sorted.slice(page * PAGE, page * PAGE + PAGE);

  function toggleSort(key) {
    setSort((s) => (s.key === key ? { key, dir: s.dir === 'asc' ? 'desc' : 'asc' } : { key, dir: 'asc' }));
  }
  const arrow = (key) => (sort.key === key ? (sort.dir === 'asc' ? ' ↑' : ' ↓') : '');

  async function act(id, next) {
    setBusy(true);
    try {
      const updated = await api.updateStatus(id, next);
      await load();
      setSel((s) => (s && s.id === id ? updated : s));
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) return onAuthError();
      setErr(e.message);
    } finally { setBusy(false); }
  }
  async function remove(id, code) {
    if (!confirm(`Delete report ${code}? This cannot be undone.`)) return;
    setBusy(true);
    try { await api.deleteReport(id); setSel(null); await load(); }
    catch (e) { if (e instanceof ApiError && e.status === 401) return onAuthError(); setErr(e.message); }
    finally { setBusy(false); }
  }

  function exportCsv() {
    const cols = ['report_code', 'medicine_name', 'manufacturer', 'batch_number', 'expiry_date',
      'confidence', 'region', 'street', 'pharmacy', 'category', 'status', 'submitted_at'];
    const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
    const csv = [cols.join(','), ...sorted.map((r) => cols.map((c) => esc(r[c])).join(','))].join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    const link = document.createElement('a');
    link.href = url; link.download = `mediguard-reports-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click(); URL.revokeObjectURL(url);
  }

  return (
    <div className="card">
      {err && <div className="error">{err}</div>}
      <div className="toolbar">
        <input className="input" placeholder="Search medicine, pharmacy, or code…"
               value={search} onChange={(e) => setSearch(e.target.value)} />
        <select className="select" value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">All statuses</option>
          <option value="pending">Pending</option>
          <option value="under_review">Under review</option>
          <option value="confirmed">Confirmed</option>
          <option value="dismissed">Dismissed</option>
        </select>
        <div className="spacer" />
        <button className="btn btn-sm" onClick={load}>↻ Refresh</button>
        <button className="btn btn-sm" onClick={exportCsv} disabled={!sorted.length}>⭳ Export CSV</button>
      </div>

      {loading ? <div className="empty">Loading…</div>
        : sorted.length === 0 ? <div className="empty">No reports match your filters.</div>
        : (
        <>
          <div style={{ overflowX: 'auto' }}>
            <table>
              <thead>
                <tr>
                  <th className="sortable" onClick={() => toggleSort('report_code')}>Code{arrow('report_code')}</th>
                  <th className="sortable" onClick={() => toggleSort('medicine_name')}>Medicine{arrow('medicine_name')}</th>
                  <th>Pharmacy</th>
                  <th className="sortable" onClick={() => toggleSort('region')}>Region{arrow('region')}</th>
                  <th>Category</th>
                  <th className="sortable" onClick={() => toggleSort('confidence')}>Conf.{arrow('confidence')}</th>
                  <th className="sortable" onClick={() => toggleSort('status')}>Status{arrow('status')}</th>
                  <th className="sortable" onClick={() => toggleSort('submitted_at')}>Submitted{arrow('submitted_at')}</th>
                </tr>
              </thead>
              <tbody>
                {view.map((r) => (
                  <tr key={r.id} onClick={() => setSel(r)}>
                    <td className="mono">{r.report_code}</td>
                    <td>{r.medicine_name}</td>
                    <td>{r.pharmacy}</td>
                    <td>{r.region}</td>
                    <td>{r.category}</td>
                    <td className="mono">{pct(r.confidence)}</td>
                    <td><StatusBadge status={r.status} /></td>
                    <td className="mono">{fmt(r.submitted_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="pagination">
            <span>{sorted.length} report{sorted.length !== 1 ? 's' : ''}</span>
            <button className="btn btn-sm" disabled={page === 0} onClick={() => setPage((p) => p - 1)}>Prev</button>
            <span>Page {page + 1} / {pages}</span>
            <button className="btn btn-sm" disabled={page >= pages - 1} onClick={() => setPage((p) => p + 1)}>Next</button>
          </div>
        </>
      )}

      {sel && (
        <>
          <div className="scrim" onClick={() => setSel(null)} />
          <aside className="drawer">
            <div className="dh">
              <StatusBadge status={sel.status} />
              <b className="mono">{sel.report_code}</b>
              <div className="spacer" />
              <button className="icon-btn" onClick={() => setSel(null)}>✕</button>
            </div>
            <div className="db">
              <h3>{sel.medicine_name}</h3>
              <div className="sub">{sel.manufacturer}</div>
              <dl className="kv">
                <dt>Batch</dt><dd>{sel.batch_number || '—'}</dd>
                <dt>Expiry</dt><dd>{sel.expiry_date || '—'}</dd>
                <dt>AI confidence</dt><dd>{pct(sel.confidence)}</dd>
                <dt>Category</dt><dd>{sel.category}</dd>
                <dt>Region</dt><dd>{sel.region}</dd>
                <dt>Street</dt><dd>{sel.street || '—'}</dd>
                <dt>Pharmacy</dt><dd>{sel.pharmacy}</dd>
                <dt>Linked scan</dt><dd className="mono">{sel.scan_id ? sel.scan_id.slice(0, 8) + '…' : 'none'}</dd>
              </dl>
              {sel.description && (
                <div className="block"><h4>Reporter's description</h4>{sel.description}</div>
              )}
              <div className="block">
                <h4>Timeline</h4>
                Submitted {fmt(sel.submitted_at)}<br />
                {sel.reviewed_at ? `Reviewed ${fmt(sel.reviewed_at)}` : 'Not yet reviewed'}
                {sel.admin_notes ? <><br />Note: {sel.admin_notes}</> : null}
              </div>
            </div>
            <div className="df">
              {NEXT[sel.status]?.map((aBtn) => (
                <button key={aBtn.status} className={`btn ${aBtn.cls}`} disabled={busy}
                        onClick={() => act(sel.id, aBtn.status)}>{aBtn.label}</button>
              ))}
              <div className="spacer" />
              <button className="btn btn-danger" disabled={busy} onClick={() => remove(sel.id, sel.report_code)}>Delete</button>
            </div>
          </aside>
        </>
      )}
    </div>
  );
}
