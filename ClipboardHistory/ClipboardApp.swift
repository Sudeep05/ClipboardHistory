import SwiftUI
import AppKit
import Combine
import Foundation
import SwiftData

// --- 1. DATA MODEL: ClipboardItem ---

@Model
final class ClipboardItem: Identifiable {
    var id: UUID
    var timestamp: Date
    var typeRawValue: String
    var content: String
    
    var type: ItemType {
        return ItemType(rawValue: typeRawValue) ?? .unsupported
    }
    
    enum ItemType: String {
        case text
        case filePath
        case unsupported
        
        var iconName: String {
            switch self {
            case .text: return "doc.text"
            case .filePath: return "folder"
            case .unsupported: return "questionmark.circle"
            }
        }
    }
    
    var preview: String {
        if type == .filePath {
            return URL(fileURLWithPath: content).lastPathComponent
        }
        let maxLength = 50
        return content.count > maxLength
            ? content.prefix(maxLength) + "..."
            : content
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), type: ItemType, content: String) {
        self.id = id
        self.timestamp = timestamp
        self.typeRawValue = type.rawValue
        self.content = content
    }
}

// --- 2. SETTINGS ---

@Observable
class AppSettings {
    var retentionDays: Int = UserDefaults.standard.integer(forKey: "RetentionDays") {
        didSet {
            UserDefaults.standard.set(retentionDays, forKey: "RetentionDays")
        }
    }
    
    init() {
        if UserDefaults.standard.object(forKey: "RetentionDays") == nil {
            self.retentionDays = 30
        }
    }
}

// --- 3. ENGINE: ClipboardMonitor ---

@Observable
class ClipboardMonitor {
    var history: [ClipboardItem] = []
    
    @ObservationIgnored private let pasteboard = NSPasteboard.general
    @ObservationIgnored private var lastChangeCount: Int
    @ObservationIgnored private var timer: AnyCancellable?
    @ObservationIgnored private var modelContext: ModelContext?
    
    init() {
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func setup(context: ModelContext) {
        self.modelContext = context
        cleanOldData()
        loadHistory()
        startPolling()
    }
    
    private func loadHistory() {
        guard let context = modelContext else { return }
        var fetchDescriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 10
        
        do {
            self.history = try context.fetch(fetchDescriptor)
        } catch {
            print("Failed to fetch history: \(error)")
        }
    }

    func cleanOldData() {
        guard let context = modelContext else { return }
        
        let storedDays = UserDefaults.standard.integer(forKey: "RetentionDays")
        let retentionDays = storedDays == 0 ? 30 : storedDays
        
        if retentionDays == 0 { return }
        
        let retentionCutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!
        
        let predicate = #Predicate<ClipboardItem> { item in
            item.timestamp < retentionCutoff
        }
        
        do {
            try context.delete(model: ClipboardItem.self, where: predicate)
            try context.save()
            loadHistory()
        } catch {
            print("Failed to clean up old data: \(error)")
        }
    }
    
    func clearAllData() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: ClipboardItem.self)
            try context.save()
            loadHistory()
        } catch {
            print("Failed to clear all data: \(error)")
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        guard let context = modelContext else { return }
        context.delete(item)
        do {
            try context.save()
            loadHistory()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
    
    private func startPolling() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForChanges()
            }
    }
    
    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        self.lastChangeCount = pasteboard.changeCount
        
        guard let item = processPasteboardItem() else { return }
        
        if let lastItem = history.first, lastItem.content == item.content {
            return
        }
        
        saveItem(item)
    }
    
    private func processPasteboardItem() -> ClipboardItem? {
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [NSURL],
           let firstURL = fileURLs.first,
           let path = firstURL.path {
            return ClipboardItem(type: .filePath, content: path)
        }
        
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            return ClipboardItem(type: .text, content: content)
        }
        
        return ClipboardItem(type: .unsupported, content: "Unsupported content type.")
    }
    
    private func saveItem(_ item: ClipboardItem) {
        guard let context = modelContext else { return }
        context.insert(item)
        
        do {
            try context.save()
            loadHistory()
        } catch {
            print("Failed to save new item: \(error)")
        }
    }
    
    func pasteItem(_ item: ClipboardItem, shouldOpen: Bool) {
        if item.type == .filePath {
            let url = URL(fileURLWithPath: item.content)

            if shouldOpen {
                let success = NSWorkspace.shared.open(url)
                if !success {
                    Task { @MainActor in
                        let alert = NSAlert()
                        alert.messageText = "Unable to Open File"
                        alert.informativeText = "The app could not open the file at:\n\n\(item.content)\n\nThis may be due to permission restrictions or because the file no longer exists."
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
                return
            } else {
                pasteboard.clearContents()
                pasteboard.writeObjects([url as NSURL])
            }
        }

        if item.type == .text {
            pasteboard.clearContents()
            pasteboard.setString(item.content, forType: .string)
        }
        
        NSApp.hide(nil)
    }
    
    deinit {
        timer?.cancel()
    }
}

// --- 4. VIEWS ---

struct MenuBarList: View {
    var monitor: ClipboardMonitor
    @Environment(\.openWindow) var openWindow
    @Environment(\.openSettings) var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Text("Clipboard History (\(monitor.history.count) items)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            
            Divider()
            
            Button("View Full History") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "full-history")
            }
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(monitor.history) { item in
                        Button(action: {
                            let event = NSApp.currentEvent
                            let isOptionDown = event?.modifierFlags.contains(.option) ?? false
                            
                            var shouldOpen = false
                            if item.type == .filePath {
                                shouldOpen = !isOptionDown
                            }
                            
                            monitor.pasteItem(item, shouldOpen: shouldOpen)
                        }) {
                            HStack {
                                Image(systemName: item.type.iconName)
                                    .frame(width: 16)
                                Text(item.preview)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if item.type == .filePath {
                                    Text("Open")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .help(item.content)
                    }
                }
            }
            .frame(maxHeight: 400)
            
            if monitor.history.isEmpty {
                Text("Copy something to start.")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Button("Settings") {
                NSApp.activate(ignoringOtherApps: true)
                try? openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
            
            // --- NEW: About Button ---
            Button("About Clipboard History") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "about")
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(4)
        .frame(minWidth: 300)
    }
}

// --- VIEW: About Window (Credits) ---

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.accentColor)
            
            Text("Clipboard History")
                .font(.title)
                .bold()
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Created by")
                .font(.headline)
            
            // YOUR NAME HERE
            Text("PALA SUDEEP KUMAR")
                .font(.body)
            
            Text("© 2025 All Rights Reserved")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
        .padding(40)
        .frame(width: 300, height: 350)
    }
}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(ClipboardMonitor.self) var monitor
    @State private var showingPruneConfirmation = false
    @State private var showingClearAllConfirmation = false

    let retentionOptions = [7, 30, 90, 0]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Clipboard History Settings")
                .font(.title)
                .bold()

            Divider()

            VStack(alignment: .leading) {
                Text("Retention Period:")
                    .font(.headline)
                
                Picker("Retention Period", selection: $settings.retentionDays) {
                    ForEach(retentionOptions, id: \.self) { days in
                        Text(days == 0 ? "Forever" : "\(days) Days")
                            .tag(days)
                    }
                }
                .pickerStyle(.segmented)

                Text("Data older than this selection will be auto-deleted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Button("Prune Old History") {
                    showingPruneConfirmation = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Clear All Data") {
                    showingClearAllConfirmation = true
                }
                .tint(.red)
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 400, height: 350)
        .confirmationDialog("Confirm Prune", isPresented: $showingPruneConfirmation) {
            Button("Prune Old Data", role: .destructive) {
                monitor.cleanOldData()
            }
        } message: {
            if settings.retentionDays == 0 {
                Text("Retention is set to 'Forever'. Pruning will NOT delete anything.")
            } else {
                Text("This will delete items older than \(settings.retentionDays) days.")
            }
        }
        .confirmationDialog("Confirm Clear All", isPresented: $showingClearAllConfirmation) {
            Button("Delete Everything", role: .destructive) {
                monitor.clearAllData()
            }
        } message: {
            Text("This will immediately delete ALL history items. This cannot be undone.")
        }
    }
}

struct FullHistoryView: View {
    @Query(sort: [SortDescriptor(\ClipboardItem.timestamp, order: .reverse)]) private var items: [ClipboardItem]
    var monitor: ClipboardMonitor

    var body: some View {
        VStack {
            Text("Full Clipboard History")
                .font(.title2)
                .padding(.top, 10)
            
            Divider()

            if items.isEmpty {
                ContentUnavailableView("No History", systemImage: "doc.text.image")
            } else {
                List {
                    ForEach(items) { item in
                        FullHistoryRow(item: item, monitor: monitor)
                            .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: items)
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

struct FullHistoryRow: View {
    let item: ClipboardItem
    var monitor: ClipboardMonitor
    
    private var timeAgo: String {
        item.timestamp.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }

    var body: some View {
        HStack {
            Image(systemName: item.type.iconName)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(item.preview)
                    .lineLimit(3)
                
                HStack(spacing: 5) {
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(item.type == .filePath ? "Path" : "Text")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(item.type == .filePath ? "Open" : "Copy") {
                monitor.pasteItem(item, shouldOpen: true)
            }
            .help(item.type == .filePath ? "Open file" : "Copy to clipboard")
        }
        .contextMenu {
            Button("Delete Item", role: .destructive) {
                monitor.deleteItem(item)
            }
        }
    }
}

// --- 5. MAIN APP ---

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct ClipboardHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var monitor = ClipboardMonitor()
    @State private var settings = AppSettings()
    
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: ClipboardItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        Settings {
            SettingsView(settings: settings)
                .modelContainer(container)
                .environment(monitor)
        }
        
        Window("Full History", id: "full-history") {
            FullHistoryView(monitor: monitor)
                .modelContainer(container)
        }
        
        // NEW: About Window
        Window("About", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize) // Make it a fixed size dialog
        
        MenuBarExtra {
            MenuBarList(monitor: monitor)
                .onAppear {
                    monitor.setup(context: container.mainContext)
                }
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .modelContainer(container)
        .environment(settings)
    }
}
