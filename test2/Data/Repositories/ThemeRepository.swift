//
//  ThemeRepository.swift
//  test2
//

import Foundation
import CoreData

protocol ThemeRepositoryProtocol {
    func getAllThemes() -> [ThemeModel]
    func createTheme(_ theme: ThemeModel) throws
    func updateTheme(_ theme: ThemeModel) throws
    func deleteTheme(id: UUID) throws
}

class ThemeRepository: ThemeRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getAllThemes() -> [ThemeModel] {
        let request: NSFetchRequest<Theme> = Theme.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Theme.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Theme.name, ascending: true)
        ]
        do {
            let themes = try context.fetch(request)
            return themes.compactMap { theme in
                guard let id = theme.id, let name = theme.name else { return nil }
                return ThemeModel(
                    id: id,
                    name: name,
                    colorHex: theme.colorHex,
                    sortOrder: Int(theme.sortOrder)
                )
            }
        } catch {
            print("Error fetching themes: \(error)")
            return []
        }
    }
    
    func createTheme(_ theme: ThemeModel) throws {
        let request: NSFetchRequest<Theme> = Theme.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Theme.sortOrder, ascending: false)]
        request.fetchLimit = 1
        var maxOrder = 0
        if let last = try? context.fetch(request).first {
            maxOrder = Int(last.sortOrder)
        }
        
        let entity = Theme(context: context)
        entity.id = theme.id
        entity.name = theme.name
        entity.colorHex = theme.colorHex
        entity.sortOrder = Int32(maxOrder + 1)
        try context.save()
    }
    
    func updateTheme(_ theme: ThemeModel) throws {
        let request: NSFetchRequest<Theme> = Theme.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", theme.id as CVarArg)
        guard let entity = try context.fetch(request).first else { return }
        entity.name = theme.name
        entity.colorHex = theme.colorHex
        try context.save()
    }
    
    func deleteTheme(id: UUID) throws {
        let request: NSFetchRequest<Theme> = Theme.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }
}
