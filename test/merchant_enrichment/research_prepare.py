"""Build a synthetic, verified harness inside the E06 allowed test prefix. No dependency resolution."""
from pathlib import Path
import json, hashlib, subprocess
bo = Path(__file__).resolve().parents[2]
target = bo / "test/merchant_enrichment/research_runtime"
if target.exists() and not (target / "sources.json").exists():
    raise SystemExit("Unidentified harness exists")
target.mkdir(exist_ok=True)
tracked = subprocess.check_output(["git", "-c", f"safe.directory={bo.as_posix()}", "-C", str(bo), "ls-files", "lib", "test", "pubspec.yaml", "pubspec.lock", "analysis_options.yaml", "docs/merchant-enrichment", "assets/png", "assets/svg", "assets/images/assistant"], text=True).splitlines()
extra = [str(p.relative_to(bo)).replace("\\", "/") for p in
    [*(bo / "lib").rglob("research_*.dart"), *(bo / "test/merchant_enrichment").glob("research_*.dart")]]
manifest = {}
for relative in sorted(set(tracked + extra)):
    if relative == "lib/env/env.g.dart" or relative.endswith(".env"):
        continue
    source = bo / relative
    dest = target / relative
    dest.parent.mkdir(parents=True, exist_ok=True)
    data = source.read_bytes()
    dest.write_bytes(data)
    assert hashlib.sha256(dest.read_bytes()).digest() == hashlib.sha256(data).digest()
    manifest[relative] = hashlib.sha256(data).hexdigest()
for directory in ["assets/png", "assets/svg", "assets/keys", "assets/images/assistant"]:
    (target / directory).mkdir(parents=True, exist_ok=True)
# A synthetic Env stub, never a copy of a secret or generated private environment.
(target / "lib/env/env.g.dart").write_text("part of 'env.dart';\nclass _Env { static final String kUrl = 'http://127.0.0.1:9/'; }\n", encoding="utf-8", newline="\n")
config = json.loads((bo / ".dart_tool/package_config.json").read_text(encoding="utf-8"))
for package in config["packages"]:
    package["rootUri"] = "../" if package["name"] == "back_office_tribuneo_v2" else package["rootUri"]
(target / ".dart_tool").mkdir(exist_ok=True)
(target / ".dart_tool/package_config.json").write_text(json.dumps(config), encoding="utf-8", newline="\n")
(target / ".dart_tool/package_graph.json").write_bytes((bo / ".dart_tool/package_graph.json").read_bytes())
(target / "sources.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8", newline="\n")
print(f"SUT: {len(manifest)} source files verified against E06 worktree; synthetic Env only")
