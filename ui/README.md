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
python app.py
# open http://localhost:5000 in your browser
```

Notes:
- This is a lightweight prototype. It does not apply patches automatically yet.
- It uses public APIs (Homebrew, Chocolatey, Debian) for checks/searches.

Build distributable executables
--------------------------------
You can create a standalone executable for the current platform using PyInstaller. A convenience script is provided:

```bash
cd ui
chmod +x build.sh
./build.sh   # produces dist/ok_computer_ui
```

For cross-platform CI builds the repository includes a GitHub Actions workflow at `.github/workflows/build-ui.yml` which builds executables for `ubuntu-latest`, `macos-latest` and `windows-latest` and uploads them as workflow artifacts.

Notes about cross-platform builds:
- Building Windows/macOS executables typically requires running the build on the corresponding OS runner (the provided workflow does this using GitHub-hosted runners).
- If you prefer to build locally for another OS, use native machines or remote runners; cross-compiling PyInstaller binaries across OSes is not generally supported.
