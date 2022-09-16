//
//  NotificationTests.swift
//  AudioNoteTests
//
//  Created by Liam Jones on 17/02/2022.
//

import XCTest
import NotificationCenter
@testable import AudioNote

class NotificationManagerTests: XCTestCase {
  
  var notificationManager = NotificationManager()
  
  func test_createNotification() {
    //Given
    let mockId = "TestNotification"
    let mockDate = Date(timeIntervalSinceNow: 3600)
    var notificationExists = false
    //When
    notificationManager.scheduleNotification(id: mockId, date: mockDate, repeats: false)
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      notificationExists = requests.contains { request in
        request.identifier == mockId
      }
    }
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [mockId])
    //Then
    XCTAssert(notificationExists)
  }
  
  func test_deleteNotification() {
    //Given
    
    let mockId = "TestNotification"
    let mockDate = Date(timeIntervalSinceNow: 3600)
    var notificationExists = false
    
    let content = UNMutableNotificationContent()
    content.title = "Title"
    content.body = "Body"
    let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: mockDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: mockId, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error { print("Error in scheduleNotification: \(error)") }
    }
    
    //When
    notificationManager.removeNotification(forNoteId: mockId)
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      notificationExists = requests.contains { request in
        request.identifier == mockId
      }
    }
    //Then
    XCTAssertFalse(notificationExists)
  }
  
  func test_editNotification() {
    //Given
    let mockId = "TestNotification"
    let mockInitialDate = Date(timeIntervalSinceNow: 3600)
    let mockEditedDate = Date(timeIntervalSinceNow: 7200)
    let mockEditedDateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: mockEditedDate)
    let mockEditedTrigger = UNCalendarNotificationTrigger(dateMatching: mockEditedDateComponents, repeats: false)
    
    var notificationExists = false
    
    let content = UNMutableNotificationContent()
    content.title = "Title"
    content.body = "Body"
    let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: mockInitialDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: mockId, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error { print("Error in scheduleNotification: \(error)") }
    }
    //When
    notificationManager.removeNotification(forNoteId: mockId)
    notificationManager.scheduleNotification(id: mockId, date: mockEditedDate, repeats: false)
    
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      notificationExists = requests.contains { request in
        request.identifier == mockId && request.trigger == mockEditedTrigger
      }
    }
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [mockId])
    //Then
    XCTAssert(notificationExists)
  }
  
  
}


