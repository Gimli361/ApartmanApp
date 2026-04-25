// CSRF — tüm fetch isteklerine RequestVerificationToken header'ı ekle
(function () {
    const tokenMeta = document.querySelector('meta[name="csrf-token"]');
    if (!tokenMeta) return;
    const token = tokenMeta.getAttribute('content');
    const original = window.fetch;
    window.fetch = function (input, init) {
        init = init || {};
        const method = (init.method || (typeof input === 'object' ? input.method : 'GET') || 'GET').toUpperCase();
        if (method !== 'GET' && method !== 'HEAD' && method !== 'OPTIONS' && method !== 'TRACE') {
            init.headers = new Headers(init.headers || {});
            if (!init.headers.has('RequestVerificationToken')) {
                init.headers.set('RequestVerificationToken', token);
            }
        }
        return original(input, init);
    };
})();

// Global Toast Notification
function toast(msg, type = 'success') {
    const colors = {
        success: { bg: 'bg-success', icon: 'bi-check-circle-fill' },
        danger:  { bg: 'bg-danger',  icon: 'bi-x-circle-fill'     },
        warning: { bg: 'bg-warning text-dark', icon: 'bi-exclamation-triangle-fill' },
        info:    { bg: 'bg-info text-dark',    icon: 'bi-info-circle-fill' }
    };
    const c = colors[type] || colors.success;
    const div = document.createElement('div');
    div.className = 'position-fixed top-0 end-0 p-3';
    div.style.cssText = 'z-index:9999;min-width:280px;';
    div.innerHTML = `
        <div class="toast show align-items-center text-white ${c.bg} border-0 shadow-sm" role="alert">
            <div class="d-flex align-items-center">
                <i class="bi ${c.icon} fs-5 ms-3 me-2 flex-shrink-0"></i>
                <div class="toast-body fw-medium">${msg}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto"
                    onclick="this.closest('.position-fixed').remove()"></button>
            </div>
        </div>`;
    document.body.appendChild(div);
    setTimeout(() => div.remove(), 3500);
}

// Global Confirm Dialog
let _confirmCallback = null;

function confirmDialog(msg, callback, label = 'Evet, Sil') {
    _confirmCallback = callback;
    document.getElementById('_confirmMsg').textContent = msg;
    document.getElementById('_confirmBtn').textContent = label;
    new bootstrap.Modal(document.getElementById('_confirmModal')).show();
}

document.addEventListener('DOMContentLoaded', function () {
    const btn = document.getElementById('_confirmBtn');
    if (btn) {
        btn.addEventListener('click', function () {
            bootstrap.Modal.getInstance(document.getElementById('_confirmModal'))?.hide();
            if (_confirmCallback) { _confirmCallback(); _confirmCallback = null; }
        });
    }

    document.querySelectorAll('.alert-dismissible').forEach(function (alert) {
        setTimeout(function () {
            bootstrap.Alert.getOrCreateInstance(alert)?.close();
        }, 5000);
    });
});
