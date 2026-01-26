async function fetchEnv(){
  const r = await fetch('/api/env');
  const env = await r.json();
  const container = document.getElementById('env');
  container.innerHTML='';
  for(const k of Object.keys(env)){
    const row=document.createElement('div');
    row.innerHTML=`<strong>${k}</strong>: <input data-key="${k}" value="${env[k]}" style="width:260px" />`;
    container.appendChild(row);
  }
}

async function saveEnv(){
  const inputs=document.querySelectorAll('#env input');
  const body={};
  inputs.forEach(i=>body[i.dataset.key]=i.value);
  await fetch('/api/env',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  alert('Saved');
}

async function loadPackages(){
  const r=await fetch('/api/packages');
  const pkgs=await r.json();
  const tbody=document.querySelector('#pkgtbl tbody');
  tbody.innerHTML='';
  for(const p of pkgs){
    const tr=document.createElement('tr');
    tr.innerHTML=`<td>${p.type}</td><td>${p.mac}</td><td>${p.win}</td><td>${p.desc}</td><td id="s-${encodeURIComponent(p.desc)}">checking...</td>`;
    tbody.appendChild(tr);
    // check availability by desc (app name)
    checkApp(p.desc, `s-${encodeURIComponent(p.desc)}`);
  }
}

async function checkApp(name, id){
  try{
    const r=await fetch(`/api/check?app=${encodeURIComponent(name)}`);
    const j=await r.json();
    const el=document.getElementById(id);
    if(j.available){ el.innerHTML=`<span class='ok'>Available</span>`; }
    else{ el.innerHTML=`<span class='nok'>Not available</span>`; }
  }catch(e){console.error(e)}
}

async function doSearch(){
  const q=document.getElementById('search').value.trim();
  if(!q) return alert('enter query');
  const r=await fetch(`/api/search?q=${encodeURIComponent(q)}&store=all`);
  const j=await r.json();
  console.log(j);
  alert('Search results logged to console');
}

fetchEnv();
loadPackages();
