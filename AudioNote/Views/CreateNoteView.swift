//
//  CreateNoteView.swift
//  AudioNote
//
//  Created by Liam Jones on 05/01/2022.
//

import SwiftUI
import CoreData

struct CreateNoteView: View {
  
  @Environment(\.managedObjectContext) var viewContext
  @FocusState private var commentFocused
  @State private var comment: String = ""
  @State private var reminderDate = Date()
  @State private var createReminder = false
  @State private var notificationRepeats = false
  @State private var hasNotificationAccess = false
  @State private var showAlert = false
  @Binding var showNoteCreation: Bool
  
  
  var audioManager: AudioManager
  
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack {
          VStack(alignment: .leading, spacing: 5) {
            Text("Comments")
              .font(.headline.weight(.semibold))
            TextEditor(text: $comment)
              .focused($commentFocused)
              .textFieldStyle(PlainTextFieldStyle())
              .multilineTextAlignment(.leading)
              .font(.body)
              .frame(height: geometry.size.height * (commentFocused ? 0.5 : 0.25))
              .padding(.vertical, 12)
              .padding(.horizontal, 16)
              .background(
                RoundedRectangle(cornerRadius: 10).fill(Color.white)
                  .shadow(color: .gray, radius: 5, x: 1, y: 1)
              )
          }
          .padding(.bottom)
          Toggle(isOn: $createReminder) {
            Text("Set reminder date")
            Image(systemName: "calendar")
          }
          .tint(.teal)
          if createReminder {
            DatePicker(selection: $reminderDate, in: Date()...) {
              Text("select a date")
            }
            .datePickerStyle(CompactDatePickerStyle())
            .animation(.easeIn, value: createReminder)
            Toggle("Repeating reminder", isOn: $notificationRepeats)
              .tint(.teal)
          }
          Spacer()
          Button(action: saveNote, label: {
            Text("Save")
              .fontWeight(.bold)
              .padding()
              .foregroundColor(.white)
              .font(.largeTitle)
              .background(
                Capsule()
                  .fill(Color.teal)
                  .frame(width: geometry.size.width * 0.8)
                  .animation(.easeIn, value: audioManager.duration)
              )
          })
        }
        .padding(16)
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Cancel", action: cancel)
      }
      ToolbarItem(placement: .keyboard) {
        Button("Done") {
          commentFocused = false
        }
      }
    }
    .onChange(of: createReminder, perform: { newValue in
      if newValue {
        NotificationManager.shared.requestAuthorisation { granted in
          showAlert = !granted
          createReminder = granted
        }
      }
    })
    .alert(isPresented: $showAlert) {
      Alert(
        title: Text("AudioNote needs permission to set notifications"),
        message: Text("Go to settings > AudioNote > Allow AudioNote to use notifcations. \nSet switch to enable"),
        dismissButton: .default(Text("OK")))
    }
  }
  
  func saveNote() {
    guard let url = audioManager.recordUrl else {
      print("Couldn't save. The url was unexpectedly nil")
      return
    }
    
    let id = UUID().uuidString
    
    if createReminder {
      NotificationManager.shared.scheduleNotification(id: id, date: reminderDate, repeats: notificationRepeats)
    }
    
    let creationDate = Date.now
    NoteManagedObject.save(audioUrl: url, comment: comment, duration: audioManager.duration, creationDate: creationDate, reminderDate: (createReminder ? reminderDate : nil), id: id, context: viewContext)
    showNoteCreation = false
  }
  
  func cancel() {
    audioManager.cancelAndCleanUp()
    showNoteCreation = false
  }
  
  
}

struct CreateNoteView_Previews: PreviewProvider {
  static var previews: some View {
    CreateNoteView(showNoteCreation: .constant(true), audioManager: AudioManager())
  }
}
