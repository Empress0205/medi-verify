// Thin API client for the MediGuard backend.
const BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

const TOKEN_KEY = 'mediguard_token';

export const auth = {
  get token() {
    return localStorage.getItem(TOKEN_KEY);
  },
  set(token) {
    localStorage.setItem(TOKEN_KEY, token);
  },
  clear() {
    localStorage.removeItem(TOKEN_KEY);
  },
  get isAuthed() {
    return !!localStorage.getItem(TOKEN_KEY);
  },
};

async function request(path, { method = 'GET', body, authed = true } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (authed && auth.token) headers.Authorization = `Bearer ${auth.token}`;

  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401) {
    auth.clear();
    throw new ApiError('Session expired. Please sign in again.', 401);
  }
  if (!res.ok) {
    let detail = `Request failed (${res.status})`;
    try {
      const j = await res.json();
      detail = j.detail || detail;
    } catch (_) {}
    throw new ApiError(detail, res.status);
  }
  if (res.status === 204) return null;
  return res.json();
}

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

export const api = {
  base: BASE,
  login: (username, password) =>
    request('/auth/login', { method: 'POST', body: { username, password }, authed: false }),
  analytics: () => request('/analytics'),
  reports: (params = {}) => {
    const q = new URLSearchParams(
      Object.entries(params).filter(([, v]) => v !== '' && v != null)
    ).toString();
    return request(`/reports${q ? `?${q}` : ''}`);
  },
  updateStatus: (id, status, admin_notes) =>
    request(`/reports/${id}/status`, { method: 'PATCH', body: { status, admin_notes } }),
  deleteReport: (id) => request(`/reports/${id}`, { method: 'DELETE' }),
  scans: (params = {}) => {
    const q = new URLSearchParams(
      Object.entries(params).filter(([, v]) => v !== '' && v != null)
    ).toString();
    return request(`/scans${q ? `?${q}` : ''}`);
  },
  scanStats: () => request('/scans/stats'),
};
