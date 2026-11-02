"""Run the active submission methods with an in-memory transport, without Env.

No business method is reimplemented here: exact method slices from the working
tree (or HEAD for the regression baseline) are compiled into the Dart harness.
Flutter rendering, secure storage and the backend/parser are outside this test.
Uses only the existing package configuration; never runs pub or generates Env.
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


BO = Path(__file__).resolve().parents[2]
FORM = "lib/presentation/widgets/forms/orders/order_form.dart"
REPOSITORY = "lib/domain/repositories/orders_repository.dart"
USECASE = "lib/domain/usecases/orders_usecase.dart"
BASE = "lib/domain/repositories/_base_repository.dart"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--head", action="store_true", help="Read methods from HEAD")
    parser.add_argument("--dart", default=shutil.which("dart"))
    parser.add_argument("--target", choices=["js", "vm"], default="js")
    parser.add_argument("--node", default=shutil.which("node"))
    args = parser.parse_args()
    if not args.dart:
        parser.error("Pass --dart with the installed Dart executable")
    if args.target == "js" and not args.node:
        parser.error("Pass --node with the installed Node executable")

    def source(path):
        if args.head:
            return subprocess.check_output(
                ["git", "-c", f"safe.directory={BO.as_posix()}",
                 "show", f"HEAD:{path}"], cwd=BO
            ).decode("utf-8")
        return (BO / path).read_text(encoding="utf-8")

    def method(path, start, end):
        text = source(path)
        if text.count(start) != 1 or text.count(end) != 1:
            raise ValueError(f"Method boundaries changed in {path}; review harness")
        return text[text.index(start):text.index(end, text.index(start))]

    methods = {
        "FORM_SUBMIT": method(FORM, "  Future<void> addOrder()", "  Future<void> addData()"),
        "FORM_LOAD": method(FORM, "  Future<void> getUrssaf()", "  Future<void> pickAndStoreFile()"),
        "INIT_LOAD": method(FORM, "    getUrssaf().then(", "\n\n    if (alternativeByController.text"),
        "REPO_SUBMIT": method(REPOSITORY, "  Future<bool> addOrders(", "  /// Modifie une commande"),
        "REPO_LOAD": method(REPOSITORY, "  Future<List<UrssafModel>> getUrssaf()", "  Future createQrCode("),
        "USECASE_SUBMIT": method(USECASE, "  Future<bool> addOrder(", "  Future<OrderUpdateResult> updateOrder("),
        "USECASE_LOAD": method(USECASE, "  Future<List<UrssafModel>> getUrssaf()", "  Future createQRCode("),
        "ERROR_HELPERS": method(BASE, "  Map<String, dynamic>? decodeApiError(", "  /// [tenantErrorMessageForCode] appliqué"),
    }
    template = Path(__file__).with_name("submission_harness.dart.template").read_text(encoding="utf-8")
    for name, body in methods.items():
        marker = f"/* {name} */"
        if template.count(marker) != 1:
            raise ValueError(f"Missing harness marker {name}")
        template = template.replace(marker, body)

    env = dict(os.environ, DART_SUPPRESS_ANALYTICS="true")
    with tempfile.TemporaryDirectory(prefix="m15b-") as directory:
        target = Path(directory) / "submission_harness.dart"
        target.write_text(template, encoding="utf-8", newline="\n")
        packages = f"--packages={BO / '.dart_tool/package_config.json'}"
        command = [args.dart, packages, str(target)]
        if args.target == "js":
            compiled = target.with_suffix(".js")
            build = subprocess.run(
                [args.dart, "compile", "js", packages, "-O1", "-o", str(compiled), str(target)],
                cwd=BO, env=env, check=False,
            )
            if build.returncode:
                return build.returncode
            # Dart's browser runtime expects self and Web Crypto. Node supplies
            # these locally; no DOM, browser, credential or network is involved.
            command = [args.node, "-e",
                       "globalThis.self=globalThis;globalThis.crypto=require('node:crypto').webcrypto;require(process.argv[1]);",
                       str(compiled)]
        result = subprocess.run(command, cwd=BO, env=env, check=False)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
