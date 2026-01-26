// TABS
function switchTab(id) {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    document.querySelector(`.tab[onclick="switchTab('${id}')"]`).classList.add('active');
    document.getElementById(id).classList.add('active');
}

// LOAD DATA
window.addEventListener('DOMContentLoaded', () => {
    // Detect lang (simple)
    const lang = navigator.language.startsWith('fr') ? 'fr' : 'en';
    setLanguage(lang);
    
    loadEnv();
    loadPackages();
});

async function loadEnv() {
    const res = await fetch('/api/env');
    const data = await res.json();
    const container = document.getElementById('env-form');
    container.innerHTML = '';
    
    // data is now an array of {key, value, desc}
    data.forEach(item => {
        const div = document.createElement('div');
        div.className = 'env-item';
        
        div.innerHTML = `
            <label class="env-label">${item.key}</label>
            <div class="env-desc">${item.desc || ''}</div>
            <input type="text" data-key="${item.key}" value="${item.value || ''}">
        `;
        container.appendChild(div);
    });
}

async function saveEnv() {
    const inputs = document.querySelectorAll('#env-form input');
    const data = {};
    inputs.forEach(i => data[i.dataset.key] = i.value);
    
    await fetch('/api/env', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(data)
    });
    alert(t('settings_saved'));
}

async function loadPackages() {
    const res = await fetch('/api/packages');
    const data = await res.json();
    let html = `<table><thead><tr><th style="width:50px">Icon</th><th>Name (Mac)</th><th>Name (Win)</th><th>Type</th><th>Desc</th><th>Actions</th></tr></thead><tbody>`;
    document.getElementById('pkg-list').innerHTML = html + `<tr><td colspan="6">${t('loading')}</td></tr></tbody></table>`;
    
    let rows = '';
    for (const p of data) {
        // Determine best name for icon lookup
        let iconName = p.mac;
        if(!iconName || iconName=='-') iconName = p.win;
        
        // Unique ID for icon img
        const imgId = 'icon-' + (p.mac || p.win).replace(/[^a-zA-Z0-9]/g, '');
        
        rows += `<tr>
            <td><img id="${imgId}" src="" alt="" style="width:32px;height:32px;border-radius:6px;background:#eee;"></td>
            <td>${p.mac}</td>
            <td>${p.win}</td>
            <td>${p.type}</td>
            <td>${p.desc}</td>
            <td>
                <button class="secondary" style="font-size:10px; padding:4px 8px;" onclick="checkAvail('${p.mac || p.win}')">${t('check')}</button>
            </td>
        </tr>`;
        
        // Lazy load icon
        fetchIcon(imgId, iconName);
    }
    document.getElementById('pkg-list').innerHTML = html + rows + '</tbody></table>';
}

async function fetchIcon(imgId, name) {
     if(!name || name=='-') return;
     try {
         const res = await fetch('/api/icon?name=' + name);
         const d = await res.json();
         if(d.url) {
             document.getElementById(imgId).src = d.url;
         }
     } catch(e) {}
}

async function checkAvail(app) {
    if(!app || app=='-') return;
    alert('Checking availability for ' + app + '...'); // Could utilize t() here but simple alert ok
    const res = await fetch('/api/check?app=' + app);
    const data = await res.json();
    alert(JSON.stringify(data, null, 2));
}

// ACTIONS
async function runUpdate() {
    const btn = document.getElementById('btn-update');
    const log = document.getElementById('update-log');
    const out = document.getElementById('update-output');
    
    btn.disabled = true;
    const originalText = btn.innerText;
    btn.innerText = t('running');
    out.style.display = 'block';
    log.innerText = t('starting_update');
    
    try {
        const res = await fetch('/api/action/update', { method: 'POST' });
        const data = await res.json();
        console.log(data);
        if(data.error) {
            log.innerText = 'Error: ' + data.error;
        } else {
            log.innerText = 'Exit Code: ' + data.code + '\n\nSTDOUT:\n' + data.stdout + '\n\nSTDERR:\n' + data.stderr;
        }
    } catch(e) {
        log.innerText = 'Request failed: ' + e;
    } finally {
        btn.disabled = false;
        btn.innerText = originalText; // restore or use t('run_update')
    }
}

async function importInstalled() {
    // Placeholder: currently calls update.sh? No, we need import_installed.sh
    alert("This feature triggers 'src/import_installed.sh' (not fully wired in API yet, assuming bash access)");
}

// SEARCH
async function doSearch() {
    const q = document.getElementById('search-input').value;
    const store = document.getElementById('search-store').value;
    const resultsDiv = document.getElementById('search-results');
    
    resultsDiv.innerHTML = t('loading');
    
    const res = await fetch(`/api/search?q=${q}&store=${store}`);
    const data = await res.json();
    
    let html = '';
    if(data.results) {
        data.results.forEach(r => {
            html += `<h3>${r.store}</h3>`;
            if(r.store === 'homebrew') {
                r.data.forEach && r.data.forEach(item => {
                    const name = item.name || item.token;
                    const desc = item.desc || '';
                    // encode name for js call
                    html += `<div class="search-result-item">
                        <strong>${name}</strong> <span style="color:#888">${desc}</span>
                        <button style="float:right; font-size:10px;" onclick="installApp('${name}')">Install</button>
                    </div>`;
                });
            } else {
                html += `<pre>${r.data}</pre>`;
            }
        });
    }
    resultsDiv.innerHTML = html || 'No results.';
}

async function installApp(name) {
    if(!confirm(t('install_confirm', {name: name}))) return;
    
    alert(t('installing', {name: name}));
    const res = await fetch('/api/action/install', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({app: name})
    });
    const data = await res.json();
    alert('Result:\n' + (data.stdout || data.error));
}

async function promptWifiExport() {
    // Check if DB path is set in env
    const envRes = await fetch('/api/env');
    const envData = await envRes.json() || []; // returns array now
    // convert array to obj
    let envMap = {};
    envData.forEach(e => envMap[e.key] = e.value);

    let dbPath = envMap['WIFI_KDBX_DB'] || '';
    
    dbPath = prompt(t('enter_db_path'), dbPath);
    if(!dbPath) return;
    
    const password = prompt(t('enter_db_pass'));
    if(!password) return;
    
    const btn = document.querySelector('button[onclick="promptWifiExport()"]');
    const originalText = btn.innerText;
    btn.innerText = t('exporting');
    btn.disabled = true;
    
    try {
        const res = await fetch('/api/action/wifi-export', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({db: dbPath, password: password})
        });
        const data = await res.json();
        if(data.error) {
            alert('Error: ' + data.error);
        } else {
            if(data.code !== 0) {
                 alert('Failed (Exit Code ' + data.code + '):\n' + data.stderr + '\n' + data.stdout);
            } else {
                 alert('Success:\n' + data.stdout.slice(-500)); 
            }
        }
    } catch(e) {
        alert('Request failed: ' + e);
    } finally {
        btn.innerText = originalText;
        btn.disabled = false;
    }
}
