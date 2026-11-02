import Foundation
import SwiftData

@MainActor
protocol TemplateService {
    func templates(ownerID: UUID) throws -> [PaymentTemplate]
    func save(_ template: PaymentTemplate) throws
    func delete(_ template: PaymentTemplate) throws
}

/// Payment templates in SwiftData, separately for every user.
@MainActor
final class LocalTemplateService: TemplateService {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    func templates(ownerID: UUID) throws -> [PaymentTemplate] {
        let descriptor = FetchDescriptor<PaymentTemplate>(
            predicate: #Predicate { $0.ownerID == ownerID },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func save(_ template: PaymentTemplate) throws {
        context.insert(template)
        try commit()
    }

    func delete(_ template: PaymentTemplate) throws {
        context.delete(template)
        try commit()
    }

    private func commit() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
