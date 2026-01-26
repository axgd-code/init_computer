from flask import Flask, jsonify, request, render_template, send_from_directory
from dotenv import load_dotenv, set_key
import os
import requests
from pathlib import Path
import multiprocessing
import socket

BASE_DIR = Path(__file__).resolve().parents[1]
ENV_LOCAL = BASE_DIR / '.env.local'
PACKAGES_CONF = BASE_DIR / 'src' / 'packages.conf'

app = Flask(__name__, static_folder='static', template_folder='templates')

# Load environment
def load_env_dict():
    env = {}
    if ENV_LOCAL.exists():
        load_dotenv(dotenv_path=ENV_LOCAL, override=False)
        with ENV_LOCAL.open() as f:
            for line in f:
                line=line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                k,v=line.split('=',1)
                env[k.strip()]=v.strip().strip('"')
    return env

# Packages parsing
def read_packages():
    packages = []
    if PACKAGES_CONF.exists():
        with PACKAGES_CONF.open() as f:
            for line in f:
                line=line.strip()
                if not line or line.startswith('#'):
                    continue
                parts=line.split('|')
                # expected format: type|mac|win|desc
                if len(parts) < 4:
                    continue
                pkg = {
                    'type': parts[0],
                    'mac': parts[1],
                    'win': parts[2],
                    'desc': parts[3]
                }
                packages.append(pkg)
    return packages

# Simple availability checks
def check_homebrew(app):
    url_formula = f"https://formulae.brew.sh/api/formula/{app}.json"
    url_cask = f"https://formulae.brew.sh/api/cask/{app}.json"
    try:
        r = requests.get(url_formula, timeout=5)
        if r.status_code == 200 and 'name' in r.text:
            return True
    except Exception:
        pass
    try:
        r = requests.get(url_cask, timeout=5)
        if r.status_code == 200 and 'token' in r.text:
            return True
    except Exception:
        pass
    return False

def check_chocolatey(app):
    # Query Chocolatey OData endpoint
    q = f"https://community.chocolatey.org/api/v2/Packages()?%24filter=tolower(Id)%20eq%20tolower(%27{app}%27)&%24select=Id"
    try:
        r = requests.get(q, timeout=6)
        if r.status_code == 200 and app.lower() in r.text.lower():
            return True
    except Exception:
        pass
    return False

def check_debian(app):
    try:
        url = f"https://packages.debian.org/search?keywords={app}&searchon=names&suite=stable&section=all"
        r = requests.get(url, timeout=6)
        if r.status_code == 200 and 'Exact hits' in r.text:
            return True
    except Exception:
        pass
    return False

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/env', methods=['GET','POST'])
def api_env():
    if request.method == 'GET':
        return jsonify(load_env_dict())
    data = request.json or {}
    # write keys back to .env.local
    if not ENV_LOCAL.exists():
        ENV_LOCAL.write_text('')
    for k,v in data.items():
        set_key(str(ENV_LOCAL), k, str(v))
    return jsonify({'status':'ok'})

@app.route('/api/packages')
def api_packages():
    pkgs=read_packages()
    return jsonify(pkgs)

@app.route('/api/check')
def api_check():
    appname = request.args.get('app')
    target = request.args.get('target','auto')
    if not appname:
        return jsonify({'error':'missing app parameter'}),400
    result = {'app':appname,'available':False,'sources':{}}
    # check homebrew
    try:
        hb = check_homebrew(appname)
        result['sources']['homebrew']=hb
        if hb:
            result['available']=True
    except Exception:
        result['sources']['homebrew']=False
    # check chocolatey
    try:
        ch = check_chocolatey(appname)
        result['sources']['chocolatey']=ch
        if ch:
            result['available']=True
    except Exception:
        result['sources']['chocolatey']=False
    # check debian
    try:
        de = check_debian(appname)
        result['sources']['debian']=de
        if de:
            result['available']=True
    except Exception:
        result['sources']['debian']=False
    return jsonify(result)

@app.route('/api/search')
def api_search():
    q = request.args.get('q')
    store = request.args.get('store','all')
    if not q:
        return jsonify({'error':'missing q parameter'}),400
    out = {'query':q,'store':store,'results':[]}
    if store in ('all','homebrew'):
        try:
            r = requests.get(f"https://formulae.brew.sh/api/search?q={q}", timeout=6)
            if r.status_code==200:
                out['results'].append({'store':'homebrew','data':r.json()})
        except Exception:
            pass
    if store in ('all','chocolatey'):
        try:
            r = requests.get(f"https://community.chocolatey.org/packages?search={q}", timeout=6)
            out['results'].append({'store':'chocolatey','data':r.text})
        except Exception:
            pass
    if store in ('all','debian'):
        try:
            r = requests.get(f"https://packages.debian.org/search?keywords={q}&searchon=names&suite=stable&section=all", timeout=6)
            out['results'].append({'store':'debian','data':r.text})
        except Exception:
            pass
    return jsonify(out)

# static files
@app.route('/static/<path:p>')
def static_files(p):
    return send_from_directory(os.path.join(os.path.dirname(__file__),'static'), p)

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

if __name__=='__main__':
    multiprocessing.freeze_support()
    
    port = int(os.environ.get('PORT', 5000))
    if is_port_in_use(port):
        print(f" * Port {port} is in use. Trying to find another port...")
        if port == 5000:
            port = 5001
        while is_port_in_use(port):
            port += 1
            if port > 5010: # Limit searches
                break
    
    debug = os.environ.get('FLASK_DEBUG', 'false').lower() == 'true'
    print(f" * Starting server on http://localhost:{port} (debug={debug})")
    app.run(host='0.0.0.0', port=port, debug=debug)
