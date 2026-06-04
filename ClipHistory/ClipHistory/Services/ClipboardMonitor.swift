import AppKit
import CoreData

final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    var isSelfPasting = false

    private let pasteboard = NSPasteboard.general
    private let context: NSManagedObjectContext
    private let pollInterval: TimeInterval = 0.5
    private let maxItems = 100

    private var lastChangeCount: Int
    private var timer: Timer?

    private let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    private let sensitiveApps: Set<String> = [
        "com.agilebits.onepassword7",
        "com.agilebits.onepassword-osx",
        "com.1password.1password",
        "com.bitwarden.desktop",
        "com.lastpass.lastpass",
        "com.apple.keychainaccess",
        "in.sinew.Enpass-Desktop",
        "com.keepassxc.keepassxc",
        "com.dashlane.dashlane",
    ]

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        print("[ClipHistory] 剪贴板监听已启动（间隔 \(pollInterval)s）")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        print("[ClipHistory] 剪贴板监听已停止")
    }

    private func checkClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if isSelfPasting {
            isSelfPasting = false
            return
        }

        if let types = pasteboard.types, types.contains(concealedType) {
            print("[ClipHistory] 检测到敏感内容(ConcealedType)，已跳过")
            return
        }

        let sourceBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        if let bundleID = sourceBundleID, sensitiveApps.contains(bundleID) {
            print("[ClipHistory] 检测到密码管理器(\(bundleID))，已跳过")
            return
        }

        let text = pasteboard.string(forType: .string)
        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if isDuplicateText(text) {
                print("[ClipHistory] 文字与最新记录重复，已跳过")
                return
            }
            saveTextItem(text, appSource: sourceBundleID)
            return
        }

        if let imageData = readImageData() {
            if isDuplicateImage(imageData) {
                print("[ClipHistory] 图片与最新记录重复，已跳过")
                return
            }
            saveImageItem(imageData, appSource: sourceBundleID)
            return
        }
    }

    private func readImageData() -> Data? {
        guard let image = NSImage(pasteboard: pasteboard) else { return nil }
        return image.pngData()
    }

    private func isDuplicateText(_ text: String) -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ClipItemEntity")
        request.predicate = NSPredicate(format: "typeRaw == %@", ClipItemType.text.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        let latest = (try? context.fetch(request))?.first
        return (latest?.value(forKey: "content") as? String) == text
    }

    private func isDuplicateImage(_ data: Data) -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ClipItemEntity")
        request.predicate = NSPredicate(format: "typeRaw == %@", ClipItemType.image.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        let latest = (try? context.fetch(request))?.first
        return (latest?.value(forKey: "imageData") as? Data) == data
    }

    private func saveTextItem(_ text: String, appSource: String?) {
        let item = NSEntityDescription.insertNewObject(forEntityName: "ClipItemEntity", into: context)
        item.setValue(UUID(), forKey: "id")
        item.setValue(ClipItemType.text.rawValue, forKey: "typeRaw")
        item.setValue(text, forKey: "content")
        item.setValue(Date(), forKey: "createdAt")
        item.setValue(false, forKey: "isPinned")
        item.setValue(appSource, forKey: "appSource")

        enforceItemLimit()

        do {
            try context.save()
            let preview = text.prefix(30).replacingOccurrences(of: "\n", with: " ")
            print("[ClipHistory] 已记录文字：\"\(preview)\"（来源：\(appSource ?? "未知")）")
        } catch {
            print("[ClipHistory] 写入失败：\(error)")
        }
    }

    private func saveImageItem(_ data: Data, appSource: String?) {
        let item = NSEntityDescription.insertNewObject(forEntityName: "ClipItemEntity", into: context)
        item.setValue(UUID(), forKey: "id")
        item.setValue(ClipItemType.image.rawValue, forKey: "typeRaw")
        item.setValue(data, forKey: "imageData")
        item.setValue(Date(), forKey: "createdAt")
        item.setValue(false, forKey: "isPinned")
        item.setValue(appSource, forKey: "appSource")

        enforceItemLimit()

        do {
            try context.save()
            print("[ClipHistory] 已记录图片（\(data.count / 1024) KB，来源：\(appSource ?? "未知")）")
        } catch {
            print("[ClipHistory] 图片写入失败：\(error)")
        }
    }

    private func enforceItemLimit() {
        let countRequest = NSFetchRequest<NSManagedObject>(entityName: "ClipItemEntity")
        let total = (try? context.count(for: countRequest)) ?? 0
        guard total >= maxItems else { return }

        let overflow = total - maxItems + 1
        let request = NSFetchRequest<NSManagedObject>(entityName: "ClipItemEntity")
        request.predicate = NSPredicate(format: "isPinned == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchLimit = overflow

        if let oldest = try? context.fetch(request) {
            for obj in oldest {
                context.delete(obj)
            }
        }
    }
}
