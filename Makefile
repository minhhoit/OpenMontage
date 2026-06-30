.PHONY: help setup install install-dev install-gpu run doctor test test-contracts lint clean preflight preflight-full demo demo-one demo-list remotion-studio remotion-render remotion-upgrade hyperframes-doctor hyperframes-warm

PYTHON ?= python
DEMO ?=

help:
	@echo "OpenMontage local commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup              Install Python deps, Remotion deps, Piper TTS, HyperFrames cache, and .env"
	@echo "  make install            Install Python runtime dependencies only"
	@echo "  make install-dev        Install developer/test dependencies"
	@echo "  make install-gpu        Install optional local GPU video-generation dependencies"
	@echo ""
	@echo "Run / inspect:"
	@echo "  make run                Run the system preflight capability summary"
	@echo "  make preflight          Show configured providers and composition runtimes"
	@echo "  make preflight-full     Show the full provider menu for deeper debugging"
	@echo "  make doctor             Run local runtime checks"
	@echo "  make demo-list          List zero-key demo videos"
	@echo "  make demo               Render all zero-key demo videos"
	@echo "  make demo-one DEMO=name Render one zero-key demo"
	@echo "  make remotion-studio    Open the Remotion Studio dev UI"
	@echo "  make remotion-render    Render the default Remotion composition"
	@echo ""
	@echo "Quality:"
	@echo "  make lint               Compile-check key Python modules"
	@echo "  make test               Run the full pytest suite"
	@echo "  make test-contracts     Run contract tests"
	@echo "  make clean              Remove Python cache files"

# ---- One-command setup ----

setup:
	@echo "==> Installing Python dependencies..."
	pip install -r requirements.txt
	@echo ""
	@echo "==> Installing Remotion composer..."
	cd remotion-composer && npm install
	@echo ""
	@echo "==> Installing free offline TTS (Piper)..."
	pip install piper-tts || echo "  [skip] piper-tts install failed — TTS will use cloud providers instead"
	@echo ""
	@echo "==> Installing HyperFrames runtime (cache-warm via npx)..."
	@echo "    Pulls the 'hyperframes' npm package into the local npx cache so the"
	@echo "    first render doesn't pay a 30-60s cold-fetch penalty. ~20MB of disk."
	@npx --yes hyperframes --version >/dev/null 2>&1 && echo "    HyperFrames CLI cached (npx)" || echo "  [skip] HyperFrames cache-warm failed — offline or npm unavailable; first render will fetch on demand"
	@python -c "from tools.video.hyperframes_compose import HyperFramesCompose; HyperFramesCompose._npm_resolve_cache=None; c=HyperFramesCompose()._runtime_check(); print(f'    HyperFrames runtime_available={c[\"runtime_available\"]}, npm={c.get(\"npm_package_version\") or c.get(\"npm_resolve_error\")}'); [print(f'    note: {r}') for r in c['reasons']]" || echo "  [skip] HyperFrames check failed — runtime can be set up later"
	@echo ""
	python -c "import shutil, os; e=os.path.exists('.env'); shutil.copy('.env.example','.env') if not e else None; print('==> Created .env from .env.example — add your API keys there.' if not e else '==> .env already exists — skipping.')"
	@echo ""
	@echo "Done! Open this project in your AI coding assistant and start creating."
	@echo "  Optional: add API keys to .env to unlock cloud providers."
	@echo "  Optional: run 'make install-gpu' if you have an NVIDIA GPU."
	@echo "  Optional: run 'make hyperframes-doctor' to fully validate the HyperFrames runtime."
	@echo "  Optional: run 'make hyperframes-warm' anytime to refresh the npx cache to the latest hyperframes version."

# ---- Individual installs ----

install:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements-dev.txt

install-gpu:
	pip install -r requirements-gpu.txt
	pip install diffusers transformers accelerate

# ---- Run / inspect ----

run: preflight

doctor:
	@echo "==> Python"
	@$(PYTHON) --version
	@echo ""
	@echo "==> Node"
	@node --version
	@npm --version
	@echo ""
	@echo "==> FFmpeg"
	@ffmpeg -version | head -n 1
	@echo ""
	@$(MAKE) preflight

# ---- Testing ----

test:
	$(PYTHON) -m pytest tests/ -v

test-contracts:
	$(PYTHON) -m pytest tests/contracts/ -v

# ---- Utilities ----

preflight:
	$(PYTHON) -c "from tools.tool_registry import registry; import json; registry.discover(); print(json.dumps(registry.provider_menu_summary(), indent=2))"

preflight-full:
	$(PYTHON) -c "from tools.tool_registry import registry; import json; registry.discover(); print(json.dumps(registry.provider_menu(), indent=2))"

hyperframes-doctor:
	@echo "==> Probing HyperFrames runtime (node/ffmpeg/npx + hyperframes doctor)..."
	python -c "from tools.video.hyperframes_compose import HyperFramesCompose; r=HyperFramesCompose().execute({'operation':'doctor'}); import json; print(json.dumps(r.data, indent=2)); print('OK' if r.success else f'FAIL: {r.error}')"

hyperframes-warm:
	@echo "==> Refreshing the HyperFrames npx cache to latest..."
	@echo "    Uses --prefer-online so npx picks up new releases since your last run."
	npx --yes --prefer-online hyperframes --version
	@echo "==> Cache warm complete."

demo:
	@echo "==> Rendering zero-key demo videos (no API keys needed)..."
	@echo "    These use only Remotion components — animated charts, text, data viz."
	@echo ""
	$(PYTHON) render_demo.py

demo-one:
	@test -n "$(DEMO)" || (echo "Usage: make demo-one DEMO=world-in-numbers"; $(PYTHON) render_demo.py --list; exit 1)
	$(PYTHON) render_demo.py "$(DEMO)"

demo-list:
	@$(PYTHON) render_demo.py --list

remotion-studio:
	cd remotion-composer && npm run start

remotion-render:
	cd remotion-composer && npm run build

remotion-upgrade:
	cd remotion-composer && npm run upgrade

lint:
	$(PYTHON) -m py_compile tools/base_tool.py
	$(PYTHON) -m py_compile tools/tool_registry.py
	$(PYTHON) -m py_compile tools/cost_tracker.py
	$(PYTHON) -m py_compile tools/analysis/composition_validator.py

clean:
	$(PYTHON) -c "import pathlib, shutil; [shutil.rmtree(p) for p in pathlib.Path('.').rglob('__pycache__')]; [p.unlink() for p in pathlib.Path('.').rglob('*.pyc')]"
