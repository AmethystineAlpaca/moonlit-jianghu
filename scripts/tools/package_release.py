"""Build notice-complete desktop ZIPs from an allowlisted 3D-only project."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
FILES = ("project.godot", "export_presets.cfg", "icon.svg", "LICENSE",
         "LICENSE_SCOPE.md", "THIRD_PARTY_NOTICES.md", "scripts/interface/Soundscape.gd")
DIRECTORIES = ("scripts/rebirth", "scenes/rebirth", "assets/characters/kaykit",
               "assets/fonts", "assets/audio/combat", "licenses")
NOTICES = ("LICENSE", "LICENSE_SCOPE.md", "THIRD_PARTY_NOTICES.md")


def run_engine(godot, stage, log, *args, check_errors=True):
    result = subprocess.run([*godot, "--headless", "--path", str(stage), *args],
                            capture_output=True, text=True, timeout=600)
    output = result.stdout + result.stderr
    log.write_text(output)
    if result.returncode or (check_errors and "ERROR:" in output):
        raise RuntimeError(f"Godot failed; inspect {log}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revision", required=True, help="Full source commit SHA")
    parser.add_argument("--version", default="v0.4.1-preview.1")
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args()
    if len(args.revision) != 40 or any(c not in "0123456789abcdef" for c in args.revision):
        parser.error("--revision must be a full lowercase Git commit SHA")
    if not args.version.startswith("v") or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-" for c in args.version):
        parser.error("--version must be a simple version label")
    out = ROOT / "output" / "releases" / args.version
    if out.exists():
        parser.error(f"Output already exists: {out}; choose a new version directory")
    stage = out / "project"
    stage.mkdir(parents=True)
    for name in FILES:
        target = stage / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, target)
    for name in DIRECTORIES:
        shutil.copytree(ROOT / name, stage / name,
                        ignore=shutil.ignore_patterns(".DS_Store", "__pycache__", "*.pyc"))
    manifest = {"version": args.version, "source_commit": args.revision,
                "engine": "4.6.2.stable", "scope": "current 3D game only",
                "files": {str(p.relative_to(stage)): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in sorted(stage.rglob("*")) if p.is_file()}}
    (out / "BUILD_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
    if args.prepare_only:
        print(stage)
        return
    executable = shutil.which("godot")
    if not executable:
        raise RuntimeError("Godot 4.6.2 must be on PATH")
    godot = [executable]
    if sys.platform == "darwin":
        silicon = subprocess.run(["/usr/sbin/sysctl", "-n", "hw.optional.arm64"],
                                 capture_output=True, text=True)
        if silicon.returncode == 0 and silicon.stdout.strip() == "1":
            # Python itself may be running under Rosetta. Import models with
            # the native engine to avoid translated importer crashes.
            godot = ["/usr/bin/arch", "-arm64", executable]
    version = subprocess.check_output([*godot, "--version"], text=True).strip()
    if not version.startswith("4.6.2.stable"):
        raise RuntimeError(f"Expected Godot 4.6.2.stable, found {version}")
    # A fresh import can report the not-yet-imported project font. The second
    # pass must be completely error-free before either export is attempted.
    run_engine(godot, stage, out / "import-initial.log", "--editor", "--import", "--quit", check_errors=False)
    run_engine(godot, stage, out / "import-verified.log", "--editor", "--import", "--quit")
    mac_zip = out / "Stillwater-macOS.zip"
    windows = out / "Stillwater-Windows"
    windows.mkdir()
    run_engine(godot, stage, out / "macOS-export.log", "--export-release", "macOS", str(mac_zip))
    run_engine(godot, stage, out / "Windows-export.log", "--export-release", "Windows Desktop", str(windows / "Stillwater.exe"))
    readme = ("Stillwater 0.4.1 preview — 3D desktop release\n\n"
              "Extract the entire archive before running the application.\n"
              "Keep the accompanying license files when redistributing.\n"
              "Source: https://github.com/AmethystineAlpaca/moonlit-jianghu\n"
              f"Source commit: {args.revision}\n"
              "Legacy 2D artwork is not included. See LICENSE_SCOPE.md.\n"
              "macOS is not Apple-notarized. Windows is cross-exported;\n"
              "Windows hardware compatibility has not been verified.\n")
    (out / "README.txt").write_text(readme)
    companions = [stage / n for n in NOTICES] + sorted((stage / "licenses").glob("*.txt"))
    companions += [out / "BUILD_MANIFEST.json", out / "README.txt"]
    with zipfile.ZipFile(mac_zip, "a", compression=zipfile.ZIP_DEFLATED) as archive:
        for file in companions:
            relative = "licenses/" + file.name if file.parent.name == "licenses" else file.name
            archive.write(file, relative)
            target = windows / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file, target)
    win_zip = out / "Stillwater-Windows.zip"
    with zipfile.ZipFile(win_zip, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for file in sorted(windows.rglob("*")):
            if file.is_file():
                archive.write(file, str(file.relative_to(windows)))
    required = set(NOTICES) | {"licenses/" + p.name for p in (stage / "licenses").glob("*.txt")}
    for file in (mac_zip, win_zip):
        with zipfile.ZipFile(file) as archive:
            if not required.issubset(archive.namelist()) or archive.testzip():
                raise RuntimeError(f"Invalid release archive: {file}")
    artifacts = (mac_zip, win_zip, out / "BUILD_MANIFEST.json")
    (out / "SHA256SUMS.txt").write_text("".join(
        f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n" for p in artifacts))
    print(f"Created and checked archives in {out}")


if __name__ == "__main__":
    main()
