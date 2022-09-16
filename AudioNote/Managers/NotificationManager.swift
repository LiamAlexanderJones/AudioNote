//
//  NotificationManager.swift
//  AudioNote
//
//  Created by Liam Jones on 25/01/2022.
//

import Foundation
import NotificationCenter

class NotificationManager {
  
  static let shared = NotificationManager()
  
  func requestAuthorisation(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        DispatchQueue.main.async {
          if let error = error { print("Error in new request function: \(error)") }
          completion(granted)
        }
      }
  }
  
  func scheduleNotification(id: String, date: Date, repeats: Bool) {
    let content = UNMutableNotificationContent()
    content.title = "It is time for your scheduled AudioNote"
    content.body = "Click to play"
    let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error { print("Error in scheduleNotification: \(error)") }
    }
  }
  
  func removeNotification(forNoteId id: String) {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [id])
  }
  
}

