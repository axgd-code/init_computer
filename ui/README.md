# ok_computer UI

A minimal cross-platform web UI (Flask) to:
- view and edit `.env.local`
- list `src/packages.conf` entries and check availability across Homebrew/Chocolatey/Debian
- search stores (basic)

Quick start:

```bash
cd ui
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# ok_computer UI

A small cross-platform web UI (Flask) for basic management and inspection of the repository.

Features
- Edit and preview `.env.local`
- View `src/packages.conf` and check package availability across Homebrew / Chocolatey / Debian
- Basic search of package stores (Homebrew, Chocolatey, Debian)

Quick start (local development)

```bash
cd ui
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
# open http://localhost:5000 in your browser
```

Notes
- Prototype-level UI: it helps inspect and edit config, but it does not apply system-level changes automatically.
- Checks use public package APIs and return best-effort results.

Build a standalone executable

PyInstaller can produce a platform-specific binary. A convenience script is provided:

```bash
cd ui
chmod +x build.sh
./build.sh   # produces dist/ok_computer_ui
```

CI builds
- A GitHub Actions workflow (if present) builds platform-specific artifacts on `ubuntu-latest`, `macos-latest`, and `windows-latest` runners.
- Building Windows or macOS executables locally generally requires the corresponding OS or a suitable runner; PyInstaller is not designed for cross-compiling between major OS families.

Security & privacy
- The UI runs locally by default and does not send local secrets anywhere. Still, avoid exposing the dev server to untrusted networks.

Contributing
- Improvements and bug fixes are welcome. Open a PR with a short description and a screenshot or test steps when relevant.

License
- See repository [LICENSE](../LICENSE)
