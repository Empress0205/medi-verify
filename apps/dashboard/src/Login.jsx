import { useState } from 'react';
import { api, auth } from './api.js';

export default function Login({ onAuthed }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e) {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const { access_token } = await api.login(username.trim(), password);
      auth.set(access_token);
      onAuthed();
    } catch (err) {
      setError(err.message || 'Login failed');
    } finally { setLoading(false); }
  }

  return (
    <div className="login-wrap">
      <form className="login-card" onSubmit={submit}>
        <div className="mark">🛡️</div>
        <h1>MediGuard Admin</h1>
        <p>Review and triage suspicious-medicine reports across Tanzania.</p>

        <label className="field">
          <span>Username</span>
          <input className="input" value={username} onChange={(e) => setUsername(e.target.value)}
                 autoComplete="username" autoFocus />
        </label>
        <label className="field">
          <span>Password</span>
          <input className="input" type="password" value={password}
                 onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
        </label>

        {error && <div className="error">{error}</div>}
        <button className="btn btn-primary" style={{ width: '100%', padding: '11px' }} disabled={loading}>
          {loading ? 'Signing in…' : 'Sign in'}
        </button>
        {/* No credentials hint here — this console is publicly reachable. */}
        <div className="hint">Authorised TMDA reviewers only.</div>
      </form>
    </div>
  );
}
