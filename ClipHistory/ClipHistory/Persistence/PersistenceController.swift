import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init() {
        container = NSPersistentContainer(name: "ClipHistory")

        if let description = container.persistentStoreDescriptions.first {
            let supportDir = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ClipHistory", isDirectory: true)

            try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)

            description.url = supportDir.appendingPathComponent("ClipHistory.sqlite")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("CoreData 加载失败: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("CoreData 保存失败: \(nsError), \(nsError.userInfo)")
        }
    }
}
