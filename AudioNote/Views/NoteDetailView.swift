//
//  NoteDetailView.swift
//  AudioNote
//
//  Created by Liam Jones on 13/01/2022.
//

import SwiftUI


struct NoteDetailView: View {
  
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.dismiss) var dismiss
  @FocusState private var editingComment: Bool
  @State var editingReminderDate = false
  @State var editCommentText = ""
  @State var editReminderDate = Date()
  @State var showDeleteReminderAlert = false
  @State var showDeleteNoteAlert = false
  
  @Namespace var textEditorID
  
  var note: NoteManagedObject
  
  var power: Double {
    let db = audioManager.audioPlayer?.averagePower(forChannel: 0) ?? -160
    return Double(pow(2, db / 30))
  }
  
  @ObservedObject var audioManager = AudioManager()
  @State private var progress: Double = 0
  
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .medium
    return formatter
  }()
  
  var body: some View {
    GeometryReader { geo in
      ScrollViewReader { scroller in
        ScrollView {
          Text(note.creationDate ?? Date(), formatter: dateFormatter)
            .fontWeight(.bold)
          
          LinearGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple]), startPoint: .top, endPoint: .bottom)
            .frame(width: geo.size.width / 2, height: 125)
            .mask(
              VStack(spacing: 2) {
                ForEach(0..<25) { index in
                  Capsule()
                    .opacity((30 - index) < Int(power * 30) ? 1 : 0)
                }
              }
            )
          
          
          VStack {
            Slider(value: $audioManager.timerOutput, in: 0...note.duration, onEditingChanged: {
              audioManager.respondToSlider(began: $0)
            })
              .tint(.red)
            HStack {
              Button(action: {
                audioManager.playOrPause(url: note.audioUrl)
              }, label: {
                Image(systemName: audioManager.status == . playing ? "pause" : "play.fill")
                  .resizable()
                  .scaledToFit()
                  .font(.largeTitle.weight(.black))
                  .foregroundColor(audioManager.status == . playing ? .orange : .green)
                  .shadow(color: .black, radius: 1, x: 1, y: 1)
                  .frame(width: 25, height: 25)
                  .animation(.linear, value: audioManager.status)
              })
                .font(.headline)
              Text("\(audioManager.timerOutput.timeDisplay()) / \(note.duration.timeDisplay())")
                .font(.body.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
              Spacer()
            }
          }
          .padding(5)
          .background(
            RoundedRectangle(cornerRadius: 5)
              .fill(Color.teal)
          )
          .padding([.horizontal, .bottom], 5)
          
          Divider()
          
          Text("Comments")
            .fontWeight(.semibold)
            .padding([.leading, .top], 5)
            .frame(maxWidth: .infinity, alignment: .leading)
          
          VStack(alignment: .trailing) {
            TextEditor(text: $editCommentText)
              .focused($editingComment)
              .onSubmit(saveNewComment)
              .multilineTextAlignment(.leading)
              .font(.body)
              .padding(.horizontal, 3)
            HStack {
              if editingComment {
                Button("Cancel") {
                  editCommentText = note.comment ?? ""
                  editingComment = false
                }
                .tint(.red)
                Button("Save") {
                  saveNewComment()
                  editingComment = false
                }
                .tint(.green)
              } else {
                Image(systemName: "pencil.circle")
                  .onTapGesture {
                    editingComment = true
                  }
              }
            }
          }
          .padding(.horizontal, 3)
          .background(
            RoundedRectangle(cornerRadius: 10).fill(Color.white)
              .shadow(color: .gray, radius: 5, x: 2, y: 2)
          )
          .padding([.horizontal, .bottom], 5)
          
          Divider()
            .id(textEditorID)
          
          if editingReminderDate {
            DatePicker("", selection: $editReminderDate, in: Date()...)
              .datePickerStyle(CompactDatePickerStyle())
            HStack {
              Button("Save") {
                editingReminderDate = false
                saveReminderDate()
              }
              .tint(.green)
              Button("Cancel") {
                editingReminderDate = false
              }
              .tint(.red)
            }
          } else {
            if let reminderDate = note.reminderDate {
              Text("Reminder date")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
              Text(reminderDate, formatter: dateFormatter)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
              Button((note.reminderDate != nil) ? "Edit" : "Add reminder date") {
                editingReminderDate = true
                editReminderDate = note.reminderDate ?? Date()
              }
              .tint(.teal)
              if note.reminderDate != nil {
                Button("Delete") {
                  showDeleteReminderAlert = true
                }
                .tint(.red)
                .alert(isPresented: $showDeleteReminderAlert) {
                    Alert(
                        title: Text("Delete reminder?"),
                        primaryButton: .cancel(),
                        secondaryButton: .destructive(Text("Delete"), action: deleteReminder)
                    )
                }
              }
            }
          }
          
          
          
        }
        
        .onReceive(
          NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
        ) { output in
          scroller.scrollTo(textEditorID, anchor: .bottom)
        }
        
      }
      .onAppear {
        editCommentText = note.comment ?? ""
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Delete Note", action: {
            showDeleteNoteAlert = true
          })
        }
      }
      .alert("Delete Note?", isPresented: $showDeleteNoteAlert) {
        Button("Delete", action: deleteNote)
        Button("Cancel", role: .cancel) { }
      }
      
      
      
      
    }
  }
  
  
  
  func saveNewComment() {
    note.comment = editCommentText
    do {
      try viewContext.save()
    } catch {
      print("The context couldn't save new comment: \(error)")
    }
  }
  
  func saveReminderDate() {
    if let id = note.identifier {
      NotificationManager.shared.removeNotification(forNoteId: id)
      NotificationManager.shared.scheduleNotification(id: id, date: editReminderDate, repeats: false)
      //Be careful here -- two async function together could be a problem.
      note.reminderDate = editReminderDate
      do {
        try viewContext.save()
      } catch {
        print("The context couldn't save new reminder date: \(error)")
      }
    }
  }
  
  func deleteReminder() {
    if let id = note.identifier {
      NotificationManager.shared.removeNotification(forNoteId: id)
      note.reminderDate = nil
      do {
        try viewContext.save()
      } catch {
        print("The context couldn't save new reminder date: \(error)")
      }
    }
  }
  
  func deleteNote() {
    dismiss()
    note.delete(context: viewContext)
    do {
        try viewContext.save()
    } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    
    
  }
  

  
  
  
}

struct NoteDetailView_Previews: PreviewProvider {
  static var previews: some View {
    let previewContext = PersistenceController.preview.container.viewContext
    let note = NoteManagedObject(context: previewContext)
    note.creationDate = Date.now
    note.reminderDate = Date()
    note.audioUrl = URL(string: "Dummy")!
    note.comment = ""
    note.duration = 30.0
    return NoteDetailView(note: note)
  }
}
