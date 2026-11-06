#!/usr/bin/env python3
"""Build and package P1 Transfer. End users do not need this script."""
import argparse
import hashlib
import os
from pathlib import Path
import plistlib
import shutil
import struct
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '1.1'

def run(*args):
    return subprocess.check_output([str(a) for a in args], text=True)

def copy_file(source, destination, executable=False):
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    destination.chmod(0o755 if executable else 0o644)

def package(dependency_app=None):
    if os.uname().machine != 'arm64':
        raise SystemExit('This build script currently targets Apple Silicon only.')
    if dependency_app:
        contents = dependency_app.resolve() / 'Contents'
        tools = contents / 'Resources/Tools'
        libs = contents / 'Frameworks'
        dependencies = {'mtp-files': tools/'mtp-files', 'mtp-getfile': tools/'mtp-getfile',
                        'libmtp.9.dylib': libs/'libmtp.9.dylib', 'libusb-1.0.0.dylib': libs/'libusb-1.0.0.dylib'}
    else:
        brew = shutil.which('brew')
        if not brew:
            raise SystemExit('For development, install Homebrew and run brew install libmtp, or supply --dependencies-from-app.')
        mtp = Path(run(brew, '--prefix', 'libmtp').strip())
        usb = Path(run(brew, '--prefix', 'libusb').strip())
        dependencies = {'mtp-files': mtp/'bin/mtp-files', 'mtp-getfile': mtp/'bin/mtp-connect',
                        'libmtp.9.dylib': mtp/'lib/libmtp.9.dylib', 'libusb-1.0.0.dylib': usb/'lib/libusb-1.0.0.dylib'}
        if mtp.name != '1.1.23' or usb.name != '1.0.30':
            # Homebrew opt paths often use names libmtp/libusb. Resolve first.
            if mtp.resolve().name != '1.1.23' or usb.resolve().name != '1.0.30':
                raise SystemExit('This release expects libmtp 1.1.23 and libusb 1.0.30. Update source archives/notices before upgrading.')
    for path in dependencies.values():
        if not path.is_file():
            raise SystemExit(f'Missing dependency: {path}')
    for name, expected in [('libmtp-1.1.23.tar.gz','74a2b6e8cb4a0304e95b995496ea3ac644c29371649b892b856e22f12a0bdeed'),
                           ('libusb-1.0.30.tar.bz2','fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf')]:
        actual = hashlib.sha256((ROOT/'third_party/sources'/name).read_bytes()).hexdigest()
        if actual != expected:
            raise SystemExit(f'Source archive checksum mismatch: {name}')
    build = ROOT/'build'
    build.mkdir(exist_ok=True)
    # Build outside synced folders to avoid Finder metadata invalidating signing.
    with tempfile.TemporaryDirectory(prefix='p1-build-') as work:
        work = Path(work)
        app = work/'P1 Transfer.app'
        c = app/'Contents'
        (c/'MacOS').mkdir(parents=True)
        (c/'Resources').mkdir()
        (c/'Info.plist').write_bytes(plistlib.dumps({
            'CFBundleExecutable':'P1Transfer', 'CFBundleIdentifier':'com.kristalkstech.p1transfer',
            'CFBundleName':'P1 Transfer', 'CFBundleDisplayName':'P1 Transfer', 'CFBundlePackageType':'APPL',
            'CFBundleShortVersionString':VERSION, 'CFBundleVersion':VERSION,
            'CFBundleIconFile':'P1Transfer', 'LSMinimumSystemVersion':'27.0',
            'NSHighResolutionCapable':True,
            'NSHumanReadableCopyright':'Copyright © 2026 Kris Gleave (KrisTalksTech). MIT licence.'}))
        run('xcrun','swiftc','-swift-version','5','-O','-target','arm64-apple-macos27.0',
            '-module-cache-path',work/'module-cache',ROOT/'Sources/P1Transfer.swift',
            '-framework','Cocoa','-o',c/'MacOS/P1Transfer')
        for name, source in dependencies.items():
            dest = c/('Frameworks' if name.endswith('.dylib') else 'Resources/Tools')/name
            copy_file(source,dest,True)
        for binary in list((c/'Frameworks').iterdir()) + list((c/'Resources/Tools').iterdir()):
            if binary.suffix == '.dylib':
                run('install_name_tool','-id','@loader_path/'+binary.name,binary)
            for line in run('otool','-L',binary).splitlines()[1:]:
                dep = line.strip().split(' (')[0]
                name = Path(dep).name
                if name not in ['libmtp.9.dylib','libusb-1.0.0.dylib']:
                    continue
                new = ('@loader_path/' if binary.parent.name == 'Frameworks' else '@loader_path/../../Frameworks/')+name
                if dep != new:
                    run('install_name_tool','-change',dep,new,binary)
            if '/opt/homebrew/' in run('otool','-L',binary):
                raise SystemExit(f'Unbundled dependency remains in {binary}')
        iconset = work/'iconset'
        iconset.mkdir()
        sizes = {'icp4':16,'icp5':32,'icp6':64,'ic07':128,'ic08':256,'ic09':512,'ic10':1024,
                 'ic11':32,'ic12':64,'ic13':256,'ic14':512}
        chunks = []
        for tag,size in sizes.items():
            image = iconset/(tag+'.png')
            run('sips','-s','format','png','-z',size,size,ROOT/'assets/icon.jpg','--out',image)
            data = image.read_bytes()
            chunks.append(tag.encode()+struct.pack('>I',len(data)+8)+data)
        body = b''.join(chunks)
        (c/'Resources/P1Transfer.icns').write_bytes(b'icns'+struct.pack('>I',len(body)+8)+body)
        for source in (ROOT/'third_party/licences').iterdir():
            copy_file(source,c/'Resources/Licences'/source.name)
        for source in (ROOT/'third_party/sources').iterdir():
            copy_file(source,c/'Resources/Source'/source.name)
        for name in ['LICENSE','THIRD_PARTY_NOTICES.md']:
            copy_file(ROOT/name,c/'Resources'/name)
        copy_file(ROOT/'Sources/P1Transfer.swift',c/'Resources/Source/P1Transfer.swift')
        copy_file(ROOT/'docs/BUILDING.md',c/'Resources/Source/BUILDING.md')
        copy_file(ROOT/'scripts/build.py',c/'Resources/Source/build.py')
        for folder in ['Frameworks','Resources/Tools']:
            for binary in (c/folder).iterdir():
                run('codesign','--force','--sign','-',binary)
        run('codesign','--force','--sign','-',app)
        run('codesign','--verify','--deep','--strict',app)
        archive = build/f'P1-Transfer-{VERSION}-macOS-arm64.zip'
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
            for file in app.rglob('*'):
                if file.is_file():
                    z.write(file,file.relative_to(work))
        checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
        archive.with_suffix('.zip.sha256').write_text(f'{checksum}  {archive.name}\n')
        print(f'Built and signature-verified: {archive}\nSHA-256: {checksum}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dependencies-from-app',type=Path,help='Reuse bundled tools/libraries from a trusted previous release')
    args = parser.parse_args()
    package(args.dependencies_from_app)
