//
//  NoteManagedObject+.swift
//  AudioNote
//
//  Created by Liam Jones on 06/01/2022.
//

import Foundation
import CoreData

extension NoteManagedObject {
  
  static func save(audioUrl: URL, comment: String, duration: Double, creationDate: Date, reminderDate: Date?, id: String, context: NSManagedObjectContext) {
    
    let newNote = Self.init(context: context)
    newNote.audioUrl = audioUrl
    newNote.comment = comment
    newNote.duration = duration
    newNote.creationDate = creationDate
    newNote.reminderDate = reminderDate
    newNote.identifier = id
    do {
      try context.save()
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func delete(context: NSManagedObjectContext) {
    
    if self.reminderDate != nil,
       let id = self.identifier {
      NotificationManager.shared.removeNotification(forNoteId: id)
    }
    if let audioUrl = self.audioUrl {
      do {
        try FileManager.default.removeItem(at: audioUrl)
      } catch {
        print("Error: FileManager couldn't remove the audio file: \(error)")
      }
    } else {
      print("Error: note.audioUrl turned out to be nil. This should never happen.")
    }
    context.delete(self)
    
  }
  
  
  
  
  
}
