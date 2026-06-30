"""Documentary Montage content-kit loader."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import yaml


ROOT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_KIT_PATH = ROOT_DIR / "content_kits" / "documentary_montage.yaml"


def load_documentary_kit(path: Path | str = DEFAULT_KIT_PATH) -> dict[str, Any]:
    """Load the documentary montage content kit."""
    kit_path = Path(path)
    with kit_path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}
    if not isinstance(data, dict):
        raise ValueError(f"Kit must be a mapping: {kit_path}")
    return data


def list_local_assets(kit: dict[str, Any], root_dir: Path = ROOT_DIR) -> dict[str, list[dict[str, Any]]]:
    """Return local library files grouped by library type."""
    results: dict[str, list[dict[str, Any]]] = {}
    for library_type, entries in (kit.get("local_libraries") or {}).items():
        found: list[dict[str, Any]] = []
        for entry in entries or []:
            rel_path = entry.get("path")
            if not rel_path:
                continue
            base = (root_dir / rel_path).resolve()
            extensions = {ext.lower() for ext in entry.get("accepted_extensions", [])}
            files: list[str] = []
            if base.exists():
                for path in sorted(p for p in base.rglob("*") if p.is_file()):
                    if path.name in {".gitkeep", "README.md"}:
                        continue
                    if not extensions or path.suffix.lower() in extensions:
                        files.append(str(path))
            found.append({
                "path": str(base),
                "exists": base.exists(),
                "description": entry.get("description", ""),
                "file_count": len(files),
                "files": files[:20],
            })
        results[library_type] = found
    return results


def summarize_kit(kit: dict[str, Any]) -> dict[str, Any]:
    """Create a compact summary for agents and humans."""
    stock = kit.get("stock_sources") or {}
    templates = kit.get("social_templates") or {}
    return {
        "name": kit.get("name"),
        "version": kit.get("version"),
        "pipeline": kit.get("default_pipeline"),
        "render_runtime": kit.get("default_render_runtime"),
        "stock_sources": {
            "zero_key": [item.get("name") for item in stock.get("zero_key", [])],
            "free_key": [item.get("name") for item in stock.get("free_key", [])],
        },
        "bgm_profiles": sorted((kit.get("bgm_profiles") or {}).keys()),
        "social_templates": {
            name: {
                "media_profile": value.get("media_profile"),
                "aspect_ratio": value.get("aspect_ratio"),
                "duration_seconds": value.get("duration_seconds"),
                "slot_count": value.get("slot_count"),
            }
            for name, value in templates.items()
        },
        "brief_presets": sorted((kit.get("brief_presets") or {}).keys()),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Inspect the Documentary Montage content kit.")
    parser.add_argument("--kit", default=str(DEFAULT_KIT_PATH), help="Path to content kit YAML.")
    parser.add_argument("--json", action="store_true", help="Print JSON.")
    parser.add_argument("--assets", action="store_true", help="Include local library file counts.")
    args = parser.parse_args(argv)

    kit = load_documentary_kit(args.kit)
    payload: dict[str, Any] = summarize_kit(kit)
    if args.assets:
        payload["local_assets"] = list_local_assets(kit)

    if args.json:
        print(json.dumps(payload, indent=2))
        return 0

    print(f"Documentary kit: {payload['name']} v{payload['version']}")
    print(f"Pipeline: {payload['pipeline']} | runtime: {payload['render_runtime']}")
    print()
    print("Zero-key sources:")
    print("  " + ", ".join(payload["stock_sources"]["zero_key"]))
    print("Free-key sources:")
    print("  " + ", ".join(payload["stock_sources"]["free_key"]))
    print()
    print("Social templates:")
    for name, template in payload["social_templates"].items():
        print(
            f"  {name}: {template['media_profile']}, {template['aspect_ratio']}, "
            f"{template['duration_seconds']}s, {template['slot_count']} slots"
        )
    print()
    print("BGM profiles:")
    print("  " + ", ".join(payload["bgm_profiles"]))

    if args.assets:
        print()
        print("Local libraries:")
        for kind, entries in payload["local_assets"].items():
            for entry in entries:
                status = "exists" if entry["exists"] else "missing"
                print(f"  {kind}: {entry['path']} ({status}, {entry['file_count']} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
