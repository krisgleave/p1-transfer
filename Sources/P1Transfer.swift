import Cocoa

struct Recording {
  let id: String
  let name: String
  let size: Int64
}
final class App: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {
  func tool(_ name: String) -> String {
    Bundle.main.resourceURL!.appendingPathComponent("Tools").appendingPathComponent(name).path
  }
  let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 740, height: 490),
    styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
  let status = NSTextField(
    labelWithString: "Connect and power on your P1. Keep other MTP apps closed.")
  let table = NSTableView()
  let refresh = NSButton(title: "Refresh", target: nil, action: nil)
  let download = NSButton(title: "Download selected…", target: nil, action: nil)
  let transferBar = NSProgressIndicator()
  let transferInfo = NSTextField(labelWithString: "")
  let progress = NSProgressIndicator()
  var files: [Recording] = []
  var busy = false
  var timer: Timer?
  var connected = false
  var checked = Set<String>()
  var checkingUSB = false
  let selectAll = NSButton(title: "Select All", target: nil, action: nil)
  let clearSelection = NSButton(title: "Clear", target: nil, action: nil)
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    let menu = NSMenu()
    let item = NSMenuItem()
    menu.addItem(item)
    let submenu = NSMenu()
    submenu.addItem(
      withTitle: "Quit P1 Transfer", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    item.submenu = submenu
    NSApp.mainMenu = menu
    window.title = "P1 Transfer"
    window.center()
    let root = NSStackView()
    root.orientation = .vertical
    root.spacing = 16
    root.edgeInsets = NSEdgeInsets(top: 22, left: 22, bottom: 22, right: 22)
    root.translatesAutoresizingMaskIntoConstraints = false
    window.contentView!.addSubview(root)
    NSLayoutConstraint.activate([
      root.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
      root.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
      root.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
      root.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),
    ])
    let heading = NSTextField(labelWithString: "Your P1 recordings")
    heading.font = .systemFont(ofSize: 24, weight: .semibold)
    root.addArrangedSubview(heading)
    status.lineBreakMode = .byWordWrapping
    status.maximumNumberOfLines = 3
    root.addArrangedSubview(status)
    transferBar.isIndeterminate = false
    transferBar.minValue = 0
    transferBar.maxValue = 100
    transferBar.doubleValue = 0
    root.addArrangedSubview(transferBar)
    transferBar.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
    transferInfo.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    transferInfo.textColor = .secondaryLabelColor
    transferInfo.stringValue = "Download progress will appear here."
    root.addArrangedSubview(transferInfo)
    for (id, title, width) in [
      ("check", "", CGFloat(42)), ("name", "File", CGFloat(420)), ("size", "Size", CGFloat(150)),
    ] {
      let c = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
      c.title = title
      c.width = width
      table.addTableColumn(c)
    }
    table.delegate = self
    table.dataSource = self
    table.allowsMultipleSelection = false
    table.selectionHighlightStyle = .none
    table.usesAlternatingRowBackgroundColors = true
    let scroll = NSScrollView()
    scroll.documentView = table
    scroll.hasVerticalScroller = true
    scroll.borderType = .bezelBorder
    root.addArrangedSubview(scroll)
    scroll.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
    let row = NSStackView()
    row.spacing = 12
    refresh.target = self
    refresh.action = #selector(scan)
    download.target = self
    download.action = #selector(copySelected)
    download.isEnabled = false
    progress.style = .spinning
    progress.controlSize = .small
    progress.isDisplayedWhenStopped = false
    selectAll.target = self
    selectAll.action = #selector(checkAll)
    clearSelection.target = self
    clearSelection.action = #selector(uncheckAll)
    row.addArrangedSubview(refresh)
    row.addArrangedSubview(selectAll)
    row.addArrangedSubview(clearSelection)
    row.addArrangedSubview(progress)
    let spacer = NSView()
    row.addArrangedSubview(spacer)
    row.addArrangedSubview(download)
    root.addArrangedSubview(row)
    row.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
    let foot = NSTextField(
      labelWithString:
        "Copies only • Originals stay on the P1 • Tick the files you want to download")
    foot.font = .systemFont(ofSize: 11)
    foot.textColor = .secondaryLabelColor
    root.addArrangedSubview(foot)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    scan()
    startWatching()
  }
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  func numberOfRows(in tableView: NSTableView) -> Int { files.count }
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    let f = files[row]
    if tableColumn?.identifier.rawValue == "check" {
      let box = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleFile(_:)))
      box.tag = row
      box.state = checked.contains(f.id) ? .on : .off
      box.isEnabled = !busy
      box.setAccessibilityLabel("Select \(f.name)")
      return box
    }
    let text =
      tableColumn?.identifier.rawValue == "size"
      ? ByteCountFormatter.string(fromByteCount: f.size, countStyle: .file) : f.name
    return NSTextField(labelWithString: text)
  }
  func selectionShouldChange(in tableView: NSTableView) -> Bool { false }
  @objc func toggleFile(_ sender: NSButton) {
    guard !busy, files.indices.contains(sender.tag) else { return }
    let id = files[sender.tag].id
    if sender.state == .on { checked.insert(id) } else { checked.remove(id) }
    updateSelectionControls()
  }
  @objc func checkAll() {
    guard !busy else { return }
    checked = Set(files.map { $0.id })
    table.reloadData()
    updateSelectionControls()
  }
  @objc func uncheckAll() {
    guard !busy else { return }
    checked.removeAll()
    table.reloadData()
    updateSelectionControls()
  }
  func updateSelectionControls() {
    download.isEnabled = !busy && !checked.isEmpty
    download.title = checked.isEmpty ? "Download selected…" : "Download \(checked.count) files…"
    selectAll.isEnabled = !busy && !files.isEmpty
    clearSelection.isEnabled = !busy && !checked.isEmpty
  }
  func setBusy(_ value: Bool) {
    busy = value
    refresh.isEnabled = !value
    updateSelectionControls()
    table.reloadData()
    if value { progress.startAnimation(nil) } else { progress.stopAnimation(nil) }
  }
  func startWatching() {
    guard !connected, timer == nil else { return }
    timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
      self?.checkUSB()
    }
  }
  func run(_ path: String, _ args: [String], timeout: Double = 30, tick: (() -> Void)? = nil) -> (
    Int32, String
  ) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    let out = Pipe()
    p.standardOutput = out
    p.standardError = out
    var data = Data()
    let lock = NSLock()
    out.fileHandleForReading.readabilityHandler = { h in
      let d = h.availableData
      lock.lock()
      data.append(d)
      lock.unlock()
    }
    do { try p.run() } catch {
      out.fileHandleForReading.readabilityHandler = nil
      return (-1, error.localizedDescription)
    }
    let deadline = Date().addingTimeInterval(timeout)
    while p.isRunning && Date() < deadline {
      tick?()
      Thread.sleep(forTimeInterval: 0.2)
    }
    tick?()
    let timedOut = p.isRunning
    if timedOut {
      p.terminate()
      Thread.sleep(forTimeInterval: 0.5)
      if p.isRunning { kill(p.processIdentifier, SIGKILL) }
    }
    p.waitUntilExit()
    out.fileHandleForReading.readabilityHandler = nil
    let rest = out.fileHandleForReading.readDataToEndOfFile()
    lock.lock()
    data.append(rest)
    let result = String(decoding: data, as: UTF8.self)
    lock.unlock()
    return (timedOut ? -2 : p.terminationStatus, result)
  }
  func checkUSB() {
    guard !busy, !connected, !checkingUSB else { return }
    checkingUSB = true
    DispatchQueue.global().async {
      let (_, text) = self.run("/usr/sbin/ioreg", ["-p", "IOUSB", "-w", "0"], timeout: 5)
      let present = text.contains("Sirius@")
      DispatchQueue.main.async {
        self.checkingUSB = false
        if present && !self.busy && !self.connected { self.scan() }
      }
    }
  }
  @objc func scan() {
    guard !busy else { return }
    guard FileManager.default.isExecutableFile(atPath: self.tool("mtp-files")) else {
      status.stringValue = "The bundled transfer tool is missing. Please reinstall P1 Transfer."
      return
    }
    setBusy(true)
    status.stringValue = "Reading the P1 file list…"
    DispatchQueue.global().async {
      let (code, text) = self.run(self.tool("mtp-files"), [])
      var parsed: [Recording] = []
      var id = ""
      var name = ""
      for raw in text.components(separatedBy: .newlines) {
        let l = raw.trimmingCharacters(in: .whitespaces)
        if l.hasPrefix("File ID: ") {
          id = String(l.dropFirst(9))
          name = ""
        } else if l.hasPrefix("Filename: ") {
          name = String(l.dropFirst(10))
        } else if l.hasPrefix("File size "),
          let size = Int64(l.dropFirst(10).split(separator: " ").first ?? ""), !id.isEmpty,
          !name.isEmpty, !name.hasPrefix("."), !name.contains("/"), name != ".."
        {
          parsed.append(Recording(id: id, name: name, size: size))
        }
      }
      let result = parsed.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
      DispatchQueue.main.async {
        self.files = result
        self.checked = Set(result.map { $0.id })
        self.table.reloadData()
        self.setBusy(false)
        self.connected = code == 0 && text.contains("OK.")
        if self.connected {
          self.timer?.invalidate()
          self.timer = nil
        } else {
          self.startWatching()
        }
        if !result.isEmpty {
          self.status.stringValue =
            "\(result.count) files ready. Choose Download selected to save a copy."
        } else if self.connected {
          self.status.stringValue = "P1 connected. No recordings found."
        } else {
          self.status.stringValue =
            text.lowercased().contains("no devices")
            ? "Connect and power on your P1, then click Refresh."
            : "Couldn’t list recordings. Quit other MTP apps and reconnect the P1, then Refresh."
          if code == -2 {
            self.status.stringValue = "P1 did not respond in time. Reconnect it and click Refresh."
          }
        }
      }
    }
  }
  @objc func copySelected() {
    let selected = files.filter { checked.contains($0.id) }
    guard !busy && !selected.isEmpty else { return }
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.prompt = "Save recordings here"
    panel.directoryURL =
      FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    guard panel.runModal() == .OK, let folder = panel.url else { return }
    setBusy(true)
    transferBar.doubleValue = 0
    transferInfo.stringValue = "Starting download…"
    DispatchQueue.global().async {
      let started = Date()
      let total = selected.reduce(Int64(0)) { $0 + $1.size }
      var completed: Int64 = 0
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.dateFormat = "yyyyMMdd-HHmmss"
      let fm = FileManager.default
      let dest = folder.appendingPathComponent("P1-recordings-\(formatter.string(from:Date()))")
      var errorText: String?
      var count = 0
      do {
        try fm.createDirectory(at: dest, withIntermediateDirectories: true)
        for (index, f) in selected.enumerated() {
          DispatchQueue.main.async {
            self.status.stringValue = "Downloading \(index+1) of \(selected.count): \(f.name)…"
          }
          let target = dest.appendingPathComponent(f.name)
          let partial = dest.appendingPathComponent("\(UUID().uuidString).partial")
          let completedBefore = completed
          let update: () -> Void = {
            let current =
              (try? fm.attributesOfItem(atPath: partial.path)[.size] as? NSNumber)?.int64Value ?? 0
            let received = min(total, completedBefore + min(f.size, max(0, current)))
            let elapsed = Date().timeIntervalSince(started)
            let percent = total > 0 ? Double(received) / Double(total) * 100 : 0
            let speed = elapsed > 0 ? Double(received) / elapsed : 0
            var eta = "Estimating time remaining…"
            if elapsed >= 2 && speed > 0 {
              let remaining = Int(ceil(Double(total - received) / speed))
              eta =
                remaining >= 60
                ? "About \(remaining/60)m \(remaining%60)s remaining"
                : "About \(remaining)s remaining"
            }
            let amount = ByteCountFormatter.string(fromByteCount: received, countStyle: .file)
            let full = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
            let rate = ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .file)
            DispatchQueue.main.async {
              self.transferBar.doubleValue = min(99.9, percent)
              self.transferInfo.stringValue =
                String(format: "%.0f%%", min(99, percent))
                + " • \(amount) of \(full) • \(rate)/s • \(eta)"
            }
          }
          let (code, output) = self.run(
            self.tool("mtp-getfile"), [f.id, partial.path], timeout: 600, tick: update)
          let size = (try? fm.attributesOfItem(atPath: partial.path)[.size] as? NSNumber)?
            .int64Value
          guard code == 0 && size == f.size else {
            try? fm.removeItem(at: partial)
            throw NSError(
              domain: "P1Transfer", code: 1,
              userInfo: [
                NSLocalizedDescriptionKey: "Couldn’t complete \(f.name). \(output.suffix(700))"
              ])
          }
          try fm.moveItem(at: partial, to: target)
          try fm.setAttributes([.extensionHidden: false], ofItemAtPath: target.path)
          if chflags(target.path, 0) != 0 {
            throw NSError(
              domain: NSPOSIXErrorDomain, code: Int(errno),
              userInfo: [
                NSLocalizedDescriptionKey:
                  "Copied \(f.name), but could not make it visible in Finder."
              ])
          }
          count += 1
          completed += f.size
        }
      } catch { errorText = error.localizedDescription }
      let message = errorText
      DispatchQueue.main.async {
        self.setBusy(false)
        if message == nil {
          self.transferBar.doubleValue = 100
          let seconds = Int(Date().timeIntervalSince(started))
          self.transferInfo.stringValue = "100% • Finished in \(seconds/60)m \(seconds%60)s"
        } else {
          self.transferInfo.stringValue = "Transfer stopped. Completed files have been kept."
        }
        self.status.stringValue =
          message == nil
          ? "Saved \(count) files. Originals remain on the P1."
          : "Stopped after \(count) files. Completed copies are saved."
        NSWorkspace.shared.open(dest)
        if let message = message {
          let alert = NSAlert()
          alert.messageText = "Transfer stopped"
          alert.informativeText = message
          alert.runModal()
        }
      }
    }
  }
}
let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.run()
