import CoreData
import Combine
import AppKit

extension Notification.Name {
    static let clipHistoryRequestPaste = Notification.Name("clipHistoryRequestPaste")
}

final class ClipHistoryViewModel: ObservableObject {
    @Published var items: [ClipItemEntity] = []
    @Published var searchText: String = ""

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: context
        )
        $searchText
            .removeDuplicates()
            .sink { [weak self] text in
                self?.fetch(matching: text)
            }
            .store(in: &cancellables)
        refresh()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func contextDidSave() {
        refresh()
    }

    var totalCount: Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ClipItemEntity")
        return (try? context.count(for: request)) ?? 0
    }

    func refresh() {
        fetch(matching: searchText)
    }

    private func fetch(matching query: String) {
        let request = NSFetchRequest<ClipItemEntity>(entityName: "ClipItemEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "isPinned", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false),
        ]
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            request.predicate = NSPredicate(format: "content CONTAINS[cd] %@", trimmed)
        }
        items = (try? context.fetch(request)) ?? []
    }

    func togglePin(_ item: ClipItemEntity) {
        item.isPinned.toggle()
        save()
    }

    func delete(_ item: ClipItemEntity) {
        context.delete(item)
        save()
    }

    func paste(_ item: ClipItemEntity) {
        let pasteboard = NSPasteboard.general

        if item.typeRaw == ClipItemType.image.rawValue,
           let data = item.imageData {
            ClipboardMonitor.shared.isSelfPasting = true
            pasteboard.clearContents()
            pasteboard.setData(data, forType: .png)
            if let tiff = NSImage(data: data)?.tiffRepresentation {
                pasteboard.setData(tiff, forType: .tiff)
            }
        } else if let content = item.content {
            ClipboardMonitor.shared.isSelfPasting = true
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
        } else {
            return
        }

        NotificationCenter.default.post(name: .clipHistoryRequestPaste, object: nil)
    }

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[ClipHistory] 保存失败：\(error)")
        }
    }
}
