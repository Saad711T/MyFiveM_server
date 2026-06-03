const $app     = document.getElementById('app');
const $grid    = document.getElementById('grid');
const $empty   = document.getElementById('empty');
const $balance = document.getElementById('balance');
const $search  = document.getElementById('search');
const $close   = document.getElementById('closeBtn');

const RES = 'simeon_ownership';
let allVehicles = [];
let ownedModels = [];
let balance = 0;

function show() { $app.classList.remove('hidden'); }
function hide() { $app.classList.add('hidden'); }

function fmt(n) {
  return '$' + Number(n).toLocaleString('en-US');
}

function post(name, data) {
  return fetch(`https://${RES}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {})
  }).catch(() => {});
}

function render(filter) {
  $grid.innerHTML = '';
  const q = (filter || '').toLowerCase().trim();

  const list = allVehicles.filter(v =>
    !q || v.label.toLowerCase().includes(q) || v.model.toLowerCase().includes(q)
  );

  if (list.length === 0) {
    $empty.classList.remove('hidden');
    return;
  }
  $empty.classList.add('hidden');

  list.forEach(v => {
    const owned = ownedModels.includes(v.model.toLowerCase());
    const canAfford = balance >= v.price;

    const card = document.createElement('div');
    card.className = 'card';

    let actionHTML;
    if (owned) {
      actionHTML = `<span class="owned-tag">Owned</span>`;
    } else {
      actionHTML = `<button class="buy-btn" ${canAfford ? '' : 'disabled'}>
        ${canAfford ? 'Buy' : 'Not enough $'}
      </button>`;
    }

    card.innerHTML = `
      <p class="label">${v.label}</p>
      <span class="model">${v.model}</span>
      <span class="price">${fmt(v.price)}</span>
      ${actionHTML}
    `;

    if (!owned) {
      const btn = card.querySelector('.buy-btn');
      if (btn && canAfford) {
        btn.onclick = () => {
          btn.disabled = true;
          btn.textContent = 'Buying...';
          post('buy', { model: v.model });
        };
      }
    }

    $grid.appendChild(card);
  });
}

function closeMenu() {
  hide();
  post('close', {});
}

$close.onclick = closeMenu;
$search.addEventListener('input', () => render($search.value));

window.addEventListener('message', (e) => {
  const msg = e.data || {};
  if (msg.action === 'open') {
    allVehicles = msg.vehicles || [];
    ownedModels = (msg.owned || []).map(m => m.toLowerCase());
    balance     = msg.balance || 0;
    $balance.textContent = fmt(balance);
    $search.value = '';
    render('');
    show();
  } else if (msg.action === 'update') {
    // refresh after a purchase without closing
    ownedModels = (msg.owned || []).map(m => m.toLowerCase());
    balance     = msg.balance || 0;
    $balance.textContent = fmt(balance);
    render($search.value);
  } else if (msg.action === 'close') {
    hide();
  }
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    e.preventDefault();
    closeMenu();
  }
});