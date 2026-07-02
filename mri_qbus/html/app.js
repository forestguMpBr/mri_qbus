'use strict';

// ─── State ────────────────────────────────────────────────────────────────────
let playerData  = null;
let routes      = [];
let rentOptions = [];
let buyOptions  = [];
let levels      = {};
let activeRoute = null;

// ─── NUI Message Handler ─────────────────────────────────────────────────────
window.addEventListener('message', ({ data }) => {
    switch (data.action) {

        case 'openUI':
            playerData  = data.playerData;
            routes      = data.routes      || [];
            rentOptions = data.rentOptions || [];
            buyOptions  = data.buyOptions  || [];
            levels      = data.levels      || {};
            document.getElementById('app').classList.remove('hidden');
            renderPlayerCard();
            renderRoutes();
            renderGarage();
            renderHistory();
            // Mostra botão cancelar rota se houver rota ativa
            document.getElementById('cancelRouteBtn').style.display = data.hasRoute ? 'block' : 'none';
            break;

        case 'updateCondition':
            updateHUD({ condition: data.condition });
            break;

        case 'stopResult':
            // opcional: animar algo na NUI
            break;

        case 'routeResult':
            activeRoute = null;
            document.getElementById('hud').classList.add('hidden');
            // Atualiza dados do jogador silenciosamente
            if (data.leveledUp) {
                showLevelUp(data.newLevelLabel);
            }
            break;
    }
});

// ─── Player Card ──────────────────────────────────────────────────────────────
function renderPlayerCard() {
    if (!playerData) return;
    const d = playerData;

    document.getElementById('pName').textContent       = 'Motorista';
    document.getElementById('pLevelLabel').textContent = `Nível ${d.level} – ${d.levelData?.label || ''}`;
    document.getElementById('pXP').textContent         = `${d.xp} XP`;
    document.getElementById('pXPNext').textContent     = d.xpToNextLevel > 0
        ? `${d.xpToNextLevel} para o próximo` : 'MAX';
    document.getElementById('pXPBar').style.width      = `${d.xpProgress || 0}%`;
    document.getElementById('pRoutes').textContent     = d.total_routes  || 0;
    document.getElementById('pStops').textContent      = d.total_stops   || 0;
    document.getElementById('pRank').textContent       = `#${d.rank || '–'}`;

    // Cor do nível na barra
    const color = d.levelData?.color || '#f59e0b';
    document.getElementById('pXPBar').style.background       = color;
    document.getElementById('pLevelLabel').style.color       = color;
}

// ─── Rotas ────────────────────────────────────────────────────────────────────
function renderRoutes() {
    const container = document.getElementById('routeList');
    container.innerHTML = '';

    const playerLevel = playerData?.level || 1;

    if (!routes.length) {
        container.innerHTML = '<p class="empty-msg">Nenhuma rota disponível no momento.</p>';
        return;
    }

    routes.forEach(r => {
        const locked   = playerLevel < r.minLevel;
        const template = getTemplate(r.templateId);
        const zone     = template?.zone || r.zone || '';

        const card = document.createElement('div');
        card.className = 'route-card';
        card.innerHTML = `
            <div class="route-card-header">
                <span class="route-label">${r.label}</span>
                <span class="route-dist">${r.distance || '—'}</span>
            </div>
            <div class="route-pay">R$ ${r.basePay.toLocaleString('pt-BR')}</div>
            <div class="route-xp">+ ${r.baseXP} XP base</div>
            <div class="route-meta">
                <span class="badge">${zoneLabel(zone)}</span>
                <span class="badge level">Nível ${r.minLevel}+</span>
                <span class="badge">${(r.stops || []).length} paradas</span>
            </div>
            <button class="btn ${locked ? 'btn-disabled' : 'btn-primary'}"
                    ${locked ? 'disabled' : ''}
                    data-id="${r.id}">
                ${locked ? `🔒 Nível ${r.minLevel} necessário` : '▶ Iniciar Rota'}
            </button>
        `;

        if (!locked) {
            card.querySelector('button').addEventListener('click', () => acceptRoute(r.id));
        }

        container.appendChild(card);
    });
}

function getTemplate(id) {
    // Routes já vêm do servidor com dados do template embutidos
    return routes.find(r => r.templateId === id) || routes.find(r => r.id === id);
}

function zoneLabel(zone) {
    const map = {
        centro: '🏙️ Centro',
        sul: '🌊 Sul',
        aeroporto: '✈️ Aeroporto',
        norte: '🏜️ Norte',
        luxo: '🍸 Luxo',
    };
    return map[zone] || zone;
}

function acceptRoute(routeId) {
    fetch(`https://${getResourceName()}/acceptRoute`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ routeId }),
    })
    .then(r => r.json())
    .then(res => {
        if (res.success) {
            closeUI();
            activeRoute = routeId;
            // HUD será atualizado via evento do cliente
        } else {
            showToast(res.msg || 'Erro ao iniciar rota.', 'error');
        }
    });
}

// ─── Garagem ──────────────────────────────────────────────────────────────────
function renderGarage() {
    renderRent();
    renderBuy();
}

function renderRent() {
    const container = document.getElementById('rentList');
    container.innerHTML = '';

    rentOptions.forEach(opt => {
        const card = document.createElement('div');
        card.className = 'vehicle-card';
        card.innerHTML = `
            <img class="vehicle-img" src="${opt.image}" alt="${opt.label}" onerror="this.style.display='none'">
            <div class="vehicle-body">
                <div class="vehicle-name">${opt.label}</div>
                <div class="vehicle-desc">${opt.desc}</div>
                <div class="vehicle-price">R$ ${opt.price.toLocaleString('pt-BR')}</div>
                <button class="btn btn-rent" data-id="${opt.id}">🔑 Alugar</button>
            </div>
        `;
        card.querySelector('button').addEventListener('click', () => rentBus(opt.id));
        container.appendChild(card);
    });
}

function renderBuy() {
    const container = document.getElementById('buyList');
    container.innerHTML = '';

    const owned = playerData?.owned_buses || [];

    buyOptions.forEach(opt => {
        const alreadyOwned = owned.includes(opt.model);
        const card = document.createElement('div');
        card.className = 'vehicle-card';
        card.innerHTML = `
            <img class="vehicle-img" src="${opt.image}" alt="${opt.label}" onerror="this.style.display='none'">
            <div class="vehicle-body">
                <div class="vehicle-name">${opt.label}</div>
                <div class="vehicle-desc">${opt.desc}</div>
                <div class="vehicle-price">R$ ${opt.price.toLocaleString('pt-BR')}</div>
                <button class="btn ${alreadyOwned ? 'btn-disabled' : 'btn-buy'}"
                        ${alreadyOwned ? 'disabled' : ''}
                        data-model="${opt.model}">
                    ${alreadyOwned ? '✅ Já Possuído' : '🏷️ Comprar'}
                </button>
            </div>
        `;
        if (!alreadyOwned) {
            card.querySelector('button').addEventListener('click', () => buyBus(opt.model));
        }
        container.appendChild(card);
    });
}

function rentBus(optionId) {
    fetch(`https://${getResourceName()}/rentBus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ optionId }),
    })
    .then(r => r.json())
    .then(res => {
        if (res.success) {
            showToast('Ônibus alugado com sucesso!', 'success');
            closeUI();
        } else {
            showToast(res.msg || 'Erro ao alugar.', 'error');
        }
    });
}

function buyBus(model) {
    fetch(`https://${getResourceName()}/buyBus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model }),
    })
    .then(r => r.json())
    .then(res => {
        if (res.success) {
            showToast('Ônibus comprado com sucesso!', 'success');
            if (playerData) playerData.owned_buses.push(model);
            renderBuy();
            closeUI();
        } else {
            showToast(res.msg || 'Erro ao comprar.', 'error');
        }
    });
}

// ─── Histórico ────────────────────────────────────────────────────────────────
function renderHistory() {
    const container = document.getElementById('historyList');
    container.innerHTML = '';

    const history = playerData?.history || [];

    if (!history.length) {
        container.innerHTML = '<p class="empty-msg">Sem histórico ainda.</p>';
        return;
    }

    history.forEach(h => {
        const item = document.createElement('div');
        item.className = 'history-item';
        item.innerHTML = `
            <div>
                <div class="history-label">${h.route}</div>
                <div class="history-date">${h.date}</div>
            </div>
            <div class="history-right">
                <div class="history-pay">+ R$ ${(h.bonus || 0).toLocaleString('pt-BR')}</div>
                <div class="history-xp">+ ${h.bonusXP || 0} XP bônus</div>
                <div class="history-cond">Satisfação: ${h.condition}%</div>
            </div>
        `;
        container.appendChild(item);
    });
}

// ─── Ranking ──────────────────────────────────────────────────────────────────
function renderRanking(list) {
    const container = document.getElementById('rankingList');
    container.innerHTML = '';

    if (!list || !list.length) {
        container.innerHTML = '<p class="empty-msg">Sem dados de ranking.</p>';
        return;
    }

    list.forEach((p, i) => {
        const pos  = i + 1;
        const cls  = pos === 1 ? 'gold' : pos === 2 ? 'silver' : pos === 3 ? 'bronze' : '';
        const icon = pos === 1 ? '🥇' : pos === 2 ? '🥈' : pos === 3 ? '🥉' : `${pos}`;

        const item = document.createElement('div');
        item.className = 'ranking-item';
        item.innerHTML = `
            <div class="rank-pos ${cls}">${icon}</div>
            <div>
                <div class="rank-name">${p.name}</div>
                <div class="rank-level">Nível ${p.level}</div>
            </div>
            <div class="rank-right">
                <div class="rank-xp">${p.xp.toLocaleString('pt-BR')} XP</div>
                <div class="rank-routes">${p.total_routes} rotas</div>
            </div>
        `;
        container.appendChild(item);
    });
}

// ─── HUD ──────────────────────────────────────────────────────────────────────
function showHUD(route) {
    const hud = document.getElementById('hud');
    hud.classList.remove('hidden');
    document.getElementById('hudRoute').textContent = route.label;
    document.getElementById('hudStop').textContent  = '1/' + (route.stops?.length || '?');
}

function updateHUD({ condition, stopIndex, totalStops }) {
    if (condition !== undefined) {
        const fill  = document.getElementById('hudCondFill');
        const label = document.getElementById('hudCond');
        if (fill)  fill.style.width = condition + '%';
        if (label) label.textContent = condition;

        // Muda cor conforme satisfação
        if (fill) {
            fill.style.background =
                condition >= 70 ? 'var(--success)' :
                condition >= 40 ? '#f59e0b' : 'var(--danger)';
        }
    }
    if (stopIndex !== undefined && totalStops !== undefined) {
        const el = document.getElementById('hudStop');
        if (el) el.textContent = `${stopIndex}/${totalStops}`;
    }
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.dataset.tab;
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(`tab-${tab}`)?.classList.add('active');
    });
});

// Ranking tabs
document.querySelectorAll('.rank-tab').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.rank-tab').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        fetch(`https://${getResourceName()}/getRanking`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ category: btn.dataset.cat }),
        })
        .then(r => r.json())
        .then(res => renderRanking(res.ranking));
    });
});

// ─── Fechar ───────────────────────────────────────────────────────────────────
function closeUI() {
    document.getElementById('app').classList.add('hidden');
    fetch(`https://${getResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
}

document.getElementById('closeBtn').addEventListener('click', closeUI);

// ─── Guardar Ônibus ───────────────────────────────────────────────────────────
document.getElementById('cancelRouteBtn').addEventListener('click', () => {
    if (!confirm('Tem certeza que deseja cancelar a rota? Você não receberá pagamento.')) return;
    fetch(`https://${getResourceName()}/cancelRoute`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    })
    .then(r => r.json())
    .then(res => {
        if (res.success) {
            showToast('Rota cancelada.', 'error');
            document.getElementById('cancelRouteBtn').style.display = 'none';
            closeUI();
        } else {
            showToast(res.msg || 'Erro ao cancelar.', 'error');
        }
    })
    .catch(() => showToast('Erro ao cancelar a rota.', 'error'));
});

document.getElementById('storeBtn').addEventListener('click', () => {
    fetch(`https://${getResourceName()}/storeVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    })
    .then(r => r.json())
    .then(res => {
        if (res.success) {
            showToast('Ônibus guardado com sucesso!', 'success');
            closeUI();
        } else {
            showToast(res.msg || 'Não foi possível guardar.', 'error');
        }
    })
    .catch(() => showToast('Erro ao guardar o ônibus.', 'error'));
});

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeUI();
});

// ─── Toast simples ────────────────────────────────────────────────────────────
function showToast(msg, type = 'info') {
    const el = document.createElement('div');
    el.style.cssText = `
        position:fixed; bottom:20px; left:50%; transform:translateX(-50%);
        background:${type === 'error' ? '#ef4444' : type === 'success' ? '#10b981' : '#3b82f6'};
        color:#fff; padding:10px 20px; border-radius:8px; font-size:13px;
        font-weight:600; z-index:9999; box-shadow:0 4px 20px rgba(0,0,0,.4);
        animation:fadeIn .2s ease;
    `;
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 3000);
}

function showLevelUp(label) {
    showToast(`🎉 Level UP! Agora você é: ${label}`, 'success');
}

// ─── Helper: resource name ────────────────────────────────────────────────────
const _nativeGetParentResourceName = window.GetParentResourceName;
function getResourceName() {
    return typeof _nativeGetParentResourceName === 'function'
        ? _nativeGetParentResourceName()
        : 'mri_qbus';
}
