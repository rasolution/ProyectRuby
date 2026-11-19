'use strict';
document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('catalog-app');
  if (!root) return;
  const $ = id => document.getElementById(id);
  let token = '', actor, products = [], exchanges = [], busy = false, sequence = 0, generation = 0;
  const number = new Intl.NumberFormat('es-CR', {maximumFractionDigits: 0});
  function message(text, error = false) {
    $('message').textContent = text; $('message').hidden = !text;
    $('message').classList.toggle('error', error); $('message').setAttribute('role', error ? 'alert' : 'status');
  }
  function locked(value) {
    busy = value; root.querySelectorAll('button').forEach(button => button.disabled = value);
  }
  function clearSession() {
    token = ''; actor = undefined; ++generation; ++sequence;
    $('workspace').hidden = true; $('identity').hidden = true; $('login-panel').hidden = false;
    $('login-form').reset(); $('password-form').reset(); products = []; exchanges = [];
  }
  async function api(url, options = {}) {
    const usedToken = token;
    const response = await fetch(url, {...options, cache: 'no-store', headers: {
      Accept: 'application/json', ...(options.body ? {'Content-Type': 'application/json'} : {}),
      ...(usedToken ? {Authorization: 'Bearer ' + usedToken} : {})
    }});
    const data = response.status === 204 ? null : await response.json().catch(() => ({error: 'Respuesta no válida del servidor.'}));
    if (!response.ok) {
      if (response.status === 401 && usedToken && usedToken === token) clearSession();
      const errors = Array.isArray(data?.errors) ? data.errors : Object.values(data?.errors || {}).flat();
      throw new Error(data?.error || errors.join('\n') || 'No se pudo completar la operación.');
    }
    return data;
  }
  const element = (tag, text) => {const el = document.createElement(tag); if (text !== undefined) el.textContent = text; return el;};
  function actions(row, edit, remove) {
    const cell = element('td'); cell.dataset.label = 'Acciones'; cell.className = 'actions-cell';
    for (const [label, callback] of [['Editar', edit], ['Eliminar', remove]]) {
      const button = element('button', label); button.type = 'button'; button.className = label === 'Eliminar' ? 'secondary danger' : 'secondary';
      button.setAttribute('aria-label', label + ' ' + row); button.disabled = busy;
      button.addEventListener('click', callback); cell.append(button);
    }
    return cell;
  }
  function renderProducts() {
    const query = $('search').value.trim().toLocaleLowerCase('es');
    const rows = products.filter(row => row.name.toLocaleLowerCase('es').includes(query));
    const fragment = document.createDocumentFragment();
    for (const product of rows) {
      const row = element('tr');
      [product.name, number.format(product.price), product.state].forEach((value, index) => {
        const cell = element('td', value); cell.dataset.label = ['Nombre', 'Precio', 'Estado'][index]; row.append(cell);
      });
      row.append(actions(product.name, () => editProduct(product), () => deleteProduct(product))); fragment.append(row);
    }
    $('product-rows').replaceChildren(fragment); $('product-count').textContent = `${rows.length} de ${products.length} productos`;
    $('products-empty').hidden = rows.length > 0;
    $('products-empty').textContent = products.length ? 'No hay coincidencias.' : 'Aún no hay productos. Crea el primero.';
  }
  function fillSelectors() {
    for (const id of ['offered', 'requested']) {
      const previous = $(id).value;
      $(id).replaceChildren(new Option('Selecciona un producto', ''), ...products.map(p => new Option(p.name, p.id)));
      if (products.some(p => String(p.id) === previous)) $(id).value = previous;
    }
  }
  function renderExchanges() {
    const byId = new Map(products.map(p => [String(p.id), p.name]));
    const fragment = document.createDocumentFragment();
    for (const exchange of exchanges) {
      const row = element('tr');
      [exchange.offert_product_id, exchange.require_product_id].forEach((id, index) => {
        const cell = element('td', byId.get(String(id)) || `Producto no disponible (#${id})`);
        cell.dataset.label = index ? 'Solicitado' : 'Ofrecido'; row.append(cell);
      });
      row.append(actions('intercambio ' + exchange.id, () => editExchange(exchange), () => deleteExchange(exchange))); fragment.append(row);
    }
    $('transaction-rows').replaceChildren(fragment); $('transaction-count').textContent = `${exchanges.length} intercambios`;
    $('transactions-empty').hidden = exchanges.length > 0; fillSelectors();
  }
  async function load() {
    const current = ++sequence, session = generation;
    const [catalog, trades, identities] = await Promise.all([api('/products.json'), api('/transactions.json'), api('/users.json')]);
    if (current !== sequence || session !== generation) return;
    products = catalog; exchanges = trades; actor = identities[0];
    $('username').textContent = actor.username; $('account-name').textContent = 'Usuario: ' + actor.username;
    renderProducts(); renderExchanges();
  }
  async function write(action, done) {
    if (busy) return;
    locked(true); ++sequence;
    try {await action(); if (done) done(); if (token) await load();}
    catch (error) {message(error.message || 'No se pudo conectar al servidor.', true);}
    finally {locked(false);}
  }
  function editProduct(product) {
    if (busy) return;
    const form = $('product-form'); form.reset();
    for (const name of ['id', 'name', 'price', 'state']) form.elements.namedItem(name).value = product?.[name] ?? (name === 'state' ? '1' : '');
    $('product-form-title').textContent = product ? 'Editar producto' : 'Nuevo producto';
    form.hidden = false; $('product-name').focus(); message('');
  }
  function deleteProduct(product) {
    if (busy || !confirm(`¿Eliminar «${product.name}»?`)) return;
    write(() => api(`/products/${product.id}.json`, {method: 'DELETE'}), () => message('Producto eliminado.'));
  }
  function editExchange(exchange) {
    if (busy) return;
    const form = $('transaction-form'); form.reset();
    form.elements.namedItem('id').value = exchange?.id || '';
    $('offered').value = exchange?.offert_product_id || ''; $('requested').value = exchange?.require_product_id || '';
    $('transaction-form-title').textContent = exchange ? 'Editar intercambio' : 'Nuevo intercambio';
    form.hidden = false; $('offered').focus(); message('');
  }
  function deleteExchange(exchange) {
    if (busy || !confirm('¿Eliminar este intercambio?')) return;
    write(() => api(`/transactions/${exchange.id}.json`, {method: 'DELETE'}), () => message('Intercambio eliminado.'));
  }
  $('login-form').addEventListener('submit', async event => {
    event.preventDefault(); if (busy) return; locked(true);
    try {
      const credentials = Object.fromEntries(new FormData(event.currentTarget));
      const result = await api('/login', {method: 'POST', body: JSON.stringify({user: credentials})});
      token = result.auth_token; ++generation; $('login-form').reset();
      $('product-form').reset(); $('product-form').hidden = true; $('transaction-form').reset(); $('transaction-form').hidden = true;
      await load(); $('login-panel').hidden = true; $('workspace').hidden = false; $('identity').hidden = false; message('Sesión iniciada.');
    } catch (error) {message(error.message || 'No se pudo conectar al servidor.', true);}
    finally {locked(false);}
  });
  $('logout').addEventListener('click', () => write(() => api('/logout', {method: 'DELETE'}), () => {clearSession(); message('Sesión cerrada.');}));
  $('refresh').addEventListener('click', () => write(async () => {}, () => message('Datos actualizados.')));
  $('new-product').addEventListener('click', () => editProduct());
  $('cancel-product').addEventListener('click', () => {$('product-form').hidden = true; $('product-form').reset();});
  $('new-transaction').addEventListener('click', () => editExchange());
  $('cancel-transaction').addEventListener('click', () => {$('transaction-form').hidden = true; $('transaction-form').reset();});
  $('search').addEventListener('input', renderProducts);
  $('product-form').addEventListener('submit', event => {
    event.preventDefault(); if (busy) return;
    const data = Object.fromEntries(new FormData(event.currentTarget)), id = data.id; delete data.id;
    write(() => api(id ? `/products/${id}.json` : '/products.json', {method: id ? 'PATCH' : 'POST', body: JSON.stringify({product: data})}),
      () => {$('product-form').hidden = true; $('product-form').reset(); message('Producto guardado.');});
  });
  $('transaction-form').addEventListener('submit', event => {
    event.preventDefault(); if (busy) return;
    const data = Object.fromEntries(new FormData(event.currentTarget)), id = data.id; delete data.id;
    write(() => api(id ? `/transactions/${id}.json` : '/transactions.json', {method: id ? 'PATCH' : 'POST', body: JSON.stringify({transaction: data})}),
      () => {$('transaction-form').hidden = true; $('transaction-form').reset(); message('Intercambio guardado.');});
  });
  $('password-form').addEventListener('submit', event => {
    event.preventDefault(); if (busy) return;
    const data = Object.fromEntries(new FormData(event.currentTarget));
    if (data.password !== data.password_confirmation) {message('Las contraseñas nuevas no coinciden.', true); return;}
    write(() => api(`/users/${actor.id}.json`, {method: 'PATCH', body: JSON.stringify({user: data})}),
      () => {clearSession(); message('Contraseña actualizada. Inicia sesión de nuevo.');});
  });
  function setView(name) {
    for (const view of ['products', 'transactions', 'account']) {
      $(view + '-panel').hidden = view !== name;
      $('tab-' + view).setAttribute('aria-selected', String(view === name)); $('tab-' + view).tabIndex = view === name ? 0 : -1;
    }
  }
  const tabs = [...root.querySelectorAll('[data-view]')];
  for (const tab of tabs) {
    tab.addEventListener('click', () => {if (!busy) setView(tab.dataset.view);});
    tab.addEventListener('keydown', event => {
      const offset = event.key === 'ArrowRight' ? 1 : event.key === 'ArrowLeft' ? -1 : 0;
      if (!offset || busy) return; event.preventDefault();
      const next = tabs[(tabs.indexOf(tab) + offset + tabs.length) % tabs.length]; next.click(); next.focus();
    });
  }
});
