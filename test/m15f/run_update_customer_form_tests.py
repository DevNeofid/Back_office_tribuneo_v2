"""Run the M15F widget tests on the real customer update form, without Env.

A temporary package receives lib/ byte for byte from the working tree (or
HEAD with --head, for the regression baseline). Only
lib/domain/usecases/customer_usecase.dart is replaced by a recording double, so
no repository, transport, secure storage or Env is reachable from the form.
Uses an existing package resolution; never runs pub or generates Env.
With --mode analyze-lib the real use case is kept for the baseline comparison;
analyze-harness analyzes the test installed with the double. Mutations affect
only the temporary form and never the worktree.
"""

import argparse
import io
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile


BO = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
USECASE = "lib/domain/usecases/customer_usecase.dart"
FORM = "lib/presentation/widgets/forms/customers/update_customers_form.dart"
TEST = "test/m15f/update_customers_form_test.dart"


def git(*args):
    return subprocess.check_output(
        ["git", "-c", f"safe.directory={BO.as_posix()}", *args], cwd=BO
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--head", action="store_true", help="Read lib/ from HEAD")
    parser.add_argument("--flutter", default=shutil.which("flutter"))
    parser.add_argument(
        "--resolution", type=Path, default=BO,
        help="Resolved BO checkout providing pubspec.lock and .dart_tool (read only)",
    )
    parser.add_argument("--mode", choices=["test", "analyze-lib", "analyze-harness"], default="test")
    parser.add_argument("--mutation", choices=["editable", "fabricated-code", "required-code"])
    args = parser.parse_args()
    if args.mutation and args.mode != "test":
        parser.error("Mutations are only supported in test mode")
    if not args.flutter:
        parser.error("Pass --flutter with the installed Flutter executable")

    resolution = args.resolution.resolve()
    needed = ["pubspec.yaml", "pubspec.lock",
              ".dart_tool/package_config.json", ".dart_tool/package_graph.json"]
    missing = [name for name in needed if not (resolution / name).is_file()]
    if missing:
        parser.error(f"Resolution {resolution} lacks {', '.join(missing)}")

    pubspec = (git("show", "HEAD:pubspec.yaml") if args.head
               else (BO / "pubspec.yaml").read_bytes())
    if pubspec.replace(b"\r\n", b"\n") != \
            (resolution / "pubspec.yaml").read_bytes().replace(b"\r\n", b"\n"):
        parser.error("pubspec.yaml differs from the resolution; refusing to reuse it")

    env = dict(os.environ, DART_SUPPRESS_ANALYTICS="true")
    with tempfile.TemporaryDirectory(prefix="m15f-") as directory:
        mirror = Path(directory)
        if args.head:
            with tarfile.open(fileobj=io.BytesIO(git("archive", "HEAD", "lib"))) as archive:
                archive.extractall(mirror, filter="data")
        else:
            shutil.copytree(BO / "lib", mirror / "lib")
        if not (mirror / USECASE).is_file() or not (mirror / FORM).is_file():
            raise FileNotFoundError("Form or use case moved; review harness")

        (mirror / "pubspec.yaml").write_bytes(pubspec)
        # Declared asset folders stay empty: no asset (keys included) is copied.
        for line in pubspec.decode("utf-8").splitlines():
            entry = line.strip()
            if entry.startswith("- assets/") and entry.endswith("/"):
                (mirror / entry[2:]).mkdir(parents=True, exist_ok=True)
        (mirror / ".dart_tool").mkdir()
        for name in needed[1:]:
            shutil.copyfile(resolution / name, mirror / name)

        if args.mutation:
            form = (mirror / FORM).read_text(encoding="utf-8")
            replacements = {
                "editable": ("readOnly: true,", "readOnly: false,"),
                "fabricated-code": ("widget.entity?.code ?? '';", "(widget.entity?.code?.trim().isEmpty ?? true) ? 'FABRIQUE' : widget.entity!.code!;"),
                "required-code": ("controller: customerCodeController,", "controller: customerCodeController,\n                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'Code requis simule' : null,"),
            }
            old, new = replacements[args.mutation]
            if form.count(old) != 1:
                raise ValueError("Mutation target must occur exactly once")
            (mirror / FORM).write_text(form.replace(old, new), encoding="utf-8", newline="\n")

        double = (HERE / "customer_usecase_double.dart.template").read_bytes()
        if args.mode != "analyze-lib":
            (mirror / USECASE).write_bytes(double)
        (mirror / TEST).parent.mkdir(parents=True)
        test = (HERE / "update_customers_form_test.dart.template").read_bytes()
        (mirror / TEST).write_bytes(test)

        dart = Path(args.flutter).parent / ("dart.bat" if os.name == "nt" else "dart")
        command = ([args.flutter, "test", "--no-pub", "--suppress-analytics", "--reporter", "expanded", TEST]
                   if args.mode == "test" else
                   [str(dart), "analyze", "lib" if args.mode == "analyze-lib" else TEST])
        result = subprocess.run(
            command,
            cwd=mirror, env=env, check=False, timeout=180,
        )
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
