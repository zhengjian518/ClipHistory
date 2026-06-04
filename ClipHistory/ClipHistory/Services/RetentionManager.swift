import CoreData
import Foundation

final class RetentionManager {
    static let shared = RetentionManager()
    static let retentionDaysKey = "retentionDays"

    private let context: NSManagedObjectContext
    private let maxItems = 100
    private var timer: Timer?

    var retentionDays: Int {
        let value = UserDefaults.standard.integer(forKey: Self.retentionDaysKey)
        return value == 0 ? 3 : value
    }

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    func start() {
        cleanup()
        timer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.cleanup()
        }
    }

    func cleanup() {
        cleanupExpired()
        enforceItemLimit()
        save()
    }

    private func cleanupExpired() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) else { return }
        let request = NSFetchRequest<NSManagedObject>(entityName: "ClipItemEntity")
        request.predicate = NSPredicate(format: "isPinned == NO AND createdAt < %@", cutoff as NSDate)
        if let expired = try? context.fetch(request) {
            for obj in expired {
                context.delete(obj)
            }
            if !expired.isEmpty {
                print("[ClipHistory] 清理过期记录 \(expired.count) 条（保留 \(retentionDays) 天）")
            }
        }
    }

    private func enforceItemLimit() {
        let countRequest = NSFetchRequest<NSManagedObject>(entityName: "ClipItemEntity")
        let total = (try? context.count(for: countRequest)) ?? 0
        guard total > maxItems else { return }

        let overflow = total - maxItems
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

    private func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}
