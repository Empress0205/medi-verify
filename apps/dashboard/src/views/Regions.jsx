import { useEffect, useState } from 'react';
import { api, ApiError } from '../api.js';
import { RankedBars } from '../charts.jsx';

// Approximate normalized positions of Tanzania regions (x: west→east, y: north→south).
const COORDS = {
  'dar es salaam': [0.86, 0.53], arusha: [0.64, 0.21], mwanza: [0.33, 0.14],
  dodoma: [0.56, 0.47], mbeya: [0.37, 0.72], kilimanjaro: [0.70, 0.21], moshi: [0.70, 0.21],
  tanga: [0.84, 0.37], morogoro: [0.72, 0.53], zanzibar: [0.86, 0.47], kigoma: [0.05, 0.35],
  iringa: [0.56, 0.62], tabora: [0.32, 0.37], mtwara: [0.93, 0.84], singida: [0.48, 0.38],
  shinyanga: [0.30, 0.28], kagera: [0.12, 0.10], mara: [0.42, 0.06], pwani: [0.82, 0.55],
  ruvuma: [0.62, 0.82], rukwa: [0.28, 0.64], lindi: [0.86, 0.72],
};

function findCoord(region) {
  const r = (region || '').toLowerCase();
  for (const key in COORDS) if (r.includes(key)) return COORDS[key];
  return null;
}

export default function Regions({ onAuthError }) {
  const [a, setA] = useState(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    (async () => {
      try { setA(await api.analytics()); }
      catch (e) { if (e instanceof ApiError && e.status === 401) return onAuthError(); setErr(e.message); }
    })();
  }, [onAuthError]);

  if (err) return <div className="error">{err}</div>;
  if (!a) return <div className="empty">Loading…</div>;

  const max = Math.max(1, ...a.regions.map((r) => r.reports));
  const bubbles = a.regions
    .map((r) => ({ ...r, xy: findCoord(r.region) }))
    .filter((r) => r.xy);

  return (
    <>
      <div className="grid c2">
        <div className="card">
          <h3>Report hotspots</h3>
          <div className="sub">Bubble size = reports in that region (approx. positions)</div>
          <div className="bubble-map">
            {bubbles.map((r) => {
              const size = 22 + (r.reports / max) * 46;
              return (
                <div className="bubble" key={r.region}
                     style={{ left: `${r.xy[0] * 100}%`, top: `${r.xy[1] * 100}%`, width: size, height: size }}>
                  <b>{r.reports}</b>
                  <span className="lab">{r.region}</span>
                </div>
              );
            })}
            {bubbles.length === 0 && <div className="empty" style={{ paddingTop: 90 }}>No located regions yet</div>}
          </div>
        </div>
        <div className="card">
          <h3>Reports by region</h3>
          <div className="sub">All reporting regions, ranked</div>
          <RankedBars items={a.regions} nameKey="region" valueKey="reports" emptyText="No reports yet" />
        </div>
      </div>

      <div className="grid c2e">
        <div className="card">
          <h3>Pharmacy hotspots</h3>
          <div className="sub">Where flagged medicines were bought</div>
          <RankedBars items={a.top_pharmacies} nameKey="name" valueKey="count" color="var(--st-confirmed)" />
        </div>
        <div className="card">
          <h3>By issue category</h3>
          <div className="sub">What people report</div>
          <RankedBars items={a.categories} nameKey="name" valueKey="value" />
        </div>
      </div>
    </>
  );
}
