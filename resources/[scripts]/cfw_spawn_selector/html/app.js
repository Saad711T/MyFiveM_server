const $app  = document.getElementById('app');
const $grid = document.getElementById('grid');

function show()  { $app.classList.remove('hidden'); }
function hide()  { $app.classList.add('hidden');   }
function clear() { $grid.innerHTML = '';           }

function render(options) {
  clear();
  options.forEach(o => {
    const btn = document.createElement('button');
    btn.className = 'btn';
    btn.innerHTML = `<h3>${o.label}</h3><p>Spawn here</p>`;
    btn.onclick = () => {
      hide();
      fetch('https://cfw_spawn_selector/chooseSpawn', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: o.id })
      }).catch(()=>{});
    };
    $grid.appendChild(btn);
  });
}

window.addEventListener('message', (e) => {
  const msg = e.data || {};
  if (msg.action === 'open') {
    render(msg.options || []);
    show();
  } else if (msg.action === 'close') {
    hide();
  } else if (msg.action === 'poke') {
  }
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    e.preventDefault();
    fetch('https://cfw_spawn_selector/noClose', { method: 'POST' }).catch(()=>{});
  }
});
