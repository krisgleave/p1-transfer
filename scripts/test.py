#!/usr/bin/env python3
"""Check application selection, connection monitoring, and copied-file visibility."""
from pathlib import Path
import subprocess
import tempfile
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'Sources/P1Transfer.swift').read_text()
# Compile the real App implementation with a check entry point instead of its UI loop.
marker='let app = NSApplication.shared'
assert marker in s, 'Update test entry-point replacement if app bootstrap changes'
s=s[:s.index(marker)] + r'''
let application = NSApplication.shared
let controller = App()
controller.files = [Recording(id:"2", name:"Video001.mp4", size:100), Recording(id:"3", name:"Video001.srt", size:10)]
controller.checkAll()
assert(controller.checked == Set(["2", "3"]))
controller.uncheckAll()
assert(controller.checked.isEmpty && !controller.download.isEnabled)
let box = NSButton(checkboxWithTitle:"", target:nil, action:nil)
box.tag = 1; box.state = .on
controller.toggleFile(box)
assert(controller.checked == Set(["3"]))
controller.setBusy(true); box.state = .off; controller.toggleFile(box)
assert(controller.checked == Set(["3"]))
controller.setBusy(false); controller.toggleFile(box)
assert(controller.checked.isEmpty)
controller.connected = true; controller.startWatching()
assert(controller.timer == nil)
controller.checkUSB()
assert(!controller.checkingUSB)
let fm = FileManager.default
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
try fm.createDirectory(at:dir, withIntermediateDirectories:true)
let part = dir.appendingPathComponent("sample.partial")
let final = dir.appendingPathComponent("sample.srt")
try Data("test".utf8).write(to:part)
assert(chflags(part.path, UInt32(UF_HIDDEN)) == 0)
try fm.moveItem(at:part, to:final)
try fm.setAttributes([.extensionHidden:false], ofItemAtPath:final.path)
assert(chflags(final.path, 0) == 0)
let values = try final.resourceValues(forKeys:[.isHiddenKey, .fileSizeKey])
assert(values.isHidden == false && values.fileSize == 4)
print("PASS: checkbox selection, transfer locking, stopped polling, and download visibility")
'''
with tempfile.TemporaryDirectory(prefix='p1-test-') as work:
    work=Path(work)
    (work/'Check.swift').write_text(s)
    subprocess.run(['xcrun','swiftc','-swift-version','5','-module-cache-path',str(work/'module-cache'),
                    str(work/'Check.swift'),'-framework','Cocoa','-o',str(work/'check')],check=True)
    subprocess.run([str(work/'check'),str(work/'files')],check=True)
