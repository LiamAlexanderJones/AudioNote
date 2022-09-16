//
//  ContentView.swift
//  AudioNote
//
//  Created by Liam Jones on 03/01/2022.
//

import SwiftUI
import CoreData


struct ContentView: View {
  
  init() {
    let coloredAppearance = UINavigationBarAppearance()
    coloredAppearance.configureWithOpaqueBackground()
    coloredAppearance.backgroundColor = .systemTeal
    coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
    coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    
    UINavigationBar.appearance().standardAppearance = coloredAppearance
    UINavigationBar.appearance().compactAppearance = coloredAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    
    UINavigationBar.appearance().tintColor = .white
  }
  
  
  @Environment(\.managedObjectContext) private var viewContext
  @State var showNoteCreation = false
  @FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \NoteManagedObject.creationDate, ascending: true)],
    animation: .default)
  
  private var notes: FetchedResults<NoteManagedObject>
  
  var body: some View {
    
    NavigationView {
      GeometryReader { geometry in
        ZStack(alignment: .bottomTrailing) {
          VStack {
            List {
              ForEach(notes) { note in
                NoteView(note: note)
                  .frame(maxWidth: .infinity)
                  .listRowSeparator(.hidden)
              }
              .onDelete(perform: deleteItems)
              Spacer()
            }
            .listStyle(PlainListStyle())
            .toolbar {
              ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
              }
            }
            
          }
          NavigationLink(
            destination: RecordAudioView(showNoteCreation: self.$showNoteCreation)
              .navigationBarBackButtonHidden(true),
            isActive: self.$showNoteCreation,
            label: {
              Image(systemName: "mic.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.teal)
                .background(Color.white)
                .frame(width: geometry.size.width / 4, height: geometry.size.width / 4)
            })
            .clipShape(Circle())
            .padding()
        }
        .navigationTitle("AudioNote")
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
  
  
  
  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      offsets.map { notes[$0] }.forEach { note in
        note.delete(context: viewContext)
      }
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
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
