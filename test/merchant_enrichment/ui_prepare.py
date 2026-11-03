"""Disposable, offline E08 verification copy; no .env/env.g.dart or keys copied."""
from pathlib import Path
import hashlib
import json
import subprocess
import uuid

bo = Path(__file__).resolve().parents[2]
target = bo / ".dart_tool" / ("e08-ui-" + uuid.uuid4().hex[:10])
target.mkdir()
tracked = subprocess.check_output([
    "git", "-c", f"safe.directory={bo.as_posix()}", "-C", str(bo),
    "ls-files", "lib", "test", "assets", "pubspec.yaml", "pubspec.lock",
    "analysis_options.yaml", ".metadata", "docs/merchant-enrichment",
], text=True).splitlines()
extra = [p.relative_to(bo).as_posix() for root in [
    bo / "lib/presentation/widgets/merchant_enrichment/ui",
    bo / "test/merchant_enrichment",
] for p in root.rglob("*") if p.is_file() and p.suffix in {".dart", ".py"}]
manifest = {}
for relative in sorted(set(tracked + extra)):
    if (relative.startswith(("lib/env/", "assets/keys/"))
            or relative.endswith((".env", ".pem"))):
        continue
    source = bo / relative
    if not source.is_file():
        continue
    dest = target / relative
    dest.parent.mkdir(parents=True, exist_ok=True)
    data = source.read_bytes()
    dest.write_bytes(data)
    digest = hashlib.sha256(data).hexdigest()
    assert hashlib.sha256(dest.read_bytes()).hexdigest() == digest
    manifest[relative] = digest
# Direct synthetic class in disposable copy: no generation or copy of env.g.dart.
(target / "lib/env").mkdir(parents=True, exist_ok=True)
(target / "lib/env/env.dart").write_text(
    "abstract class Env { static const String kUrl = 'http://127.0.0.1:9/'; }\n",
    encoding="utf-8", newline="\n")
for relative in ["assets/png", "assets/svg", "assets/keys", "assets/images/assistant"]:
    (target / relative).mkdir(parents=True, exist_ok=True)
config_path = bo / ".dart_tool/package_config.json"
config = json.loads(config_path.read_text(encoding="utf-8"))
from urllib.parse import urljoin
for package in config["packages"]:
    package["rootUri"] = ("../" if package["name"] == "back_office_tribuneo_v2"
                          else urljoin(config_path.as_uri(), package["rootUri"]))
(target / ".dart_tool").mkdir(exist_ok=True)
(target / ".dart_tool/package_config.json").write_text(
    json.dumps(config), encoding="utf-8", newline="\n")
(target / ".dart_tool/package_graph.json").write_bytes(
    (bo / ".dart_tool/package_graph.json").read_bytes())
(target / "sources.json").write_text(json.dumps(manifest, indent=2) + "\n",
                                   encoding="utf-8", newline="\n")
print(target)
print(f"SUT: {len(manifest)} files SHA-256 verified; no private Env or key material")
