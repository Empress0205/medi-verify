import { useState } from 'react';
import { auth } from './api.js';
import Login from './Login.jsx';
import Overview from './views/Overview.jsx';
import Reports from './views/Reports.jsx';
import Scans from './views/Scans.jsx';
import Regions from './views/Regions.jsx';

const NAV = [
  { id: 'overview', label: 'Overview', ic: '▦' },
  { id: 'reports', label: 'Reports', ic: '🚩' },
  { id: 'scans', label: 'Scans', ic: '🔍' },
  { id: 'regions', label: 'Regions', ic: '📍' },
];
const TITLES = {
  overview: ['Overview', 'Registration checks and reports at a glance'],
  reports: ['Reports', 'Triage public suspicious-medicine reports'],
  scans: ['Scans', 'TMDA register checks from the mobile app'],
  regions: ['Regions', 'Where suspicious medicines are being reported'],
};

export default function App() {
  const [authed, setAuthed] = useState(auth.isAuthed);
  const [view, setView] = useState('overview');

  function logout() { auth.clear(); setAuthed(false); }
  if (!authed) return <Login onAuthed={() => setAuthed(true)} />;

  const [title, sub] = TITLES[view];
  const V = { overview: Overview, reports: Reports, scans: Scans, regions: Regions }[view];

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="logo">
          <span className="mark">🛡️</span>
          <span><b>MediGuard</b><small>Admin console</small></span>
        </div>
        <nav className="nav">
          {NAV.map((n) => (
            <button key={n.id} className={view === n.id ? 'active' : ''} onClick={() => setView(n.id)}>
              <span className="ic">{n.ic}</span>{n.label}
            </button>
          ))}
        </nav>
        <div className="foot">MediGuard · TMDA verification<br />v1.0 · mock engine</div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div>
            <h1>{title}</h1>
            <div className="sub">{sub}</div>
          </div>
          <div className="spacer" />
          <div className="user"><span className="av">A</span>admin</div>
          <button className="btn btn-ghost btn-sm" onClick={logout}>Sign out</button>
        </header>
        <main className="content">
          <V onAuthError={logout} />
        </main>
      </div>
    </div>
  );
}
