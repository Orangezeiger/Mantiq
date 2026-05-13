// Zentrale API-Helfer-Funktionen für alle Seiten

const API = {

    async post(url, data) {
        const res = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return { ok: res.ok, status: res.status, data: await res.json() };
    },

    async get(url) {
        const res = await fetch(url);
        return { ok: res.ok, status: res.status, data: await res.json() };
    },

    async delete(url) {
        const res = await fetch(url, { method: 'DELETE' });
        return { ok: res.ok, status: res.status };
    },

    async uploadPdf(file, userId, titel) {
        const form = new FormData();
        form.append('datei', file);
        form.append('userId', userId);
        form.append('titel', titel);
        const res = await fetch('/api/pdf/upload', { method: 'POST', body: form });
        return { ok: res.ok, data: await res.json() };
    }
};

// Auth-Helfer: Nutzer aus localStorage lesen / prüfen
const Auth = {
    get() {
        const raw = localStorage.getItem('mantiq_user');
        return raw ? JSON.parse(raw) : null;
    },
    set(user) {
        localStorage.setItem('mantiq_user', JSON.stringify(user));
    },
    logout() {
        localStorage.removeItem('mantiq_user');
        window.location.href = '/index.html';
    },
    require() {
        const user = this.get();
        if (!user) window.location.href = '/index.html';
        return user;
    }
};

// Kleiner Toast für Feedback
function showToast(msg, dauer = 2500) {
    let t = document.getElementById('toast');
    if (!t) {
        t = document.createElement('div');
        t.id = 'toast';
        t.className = 'toast';
        document.body.appendChild(t);
    }
    t.textContent = msg;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), dauer);
}
