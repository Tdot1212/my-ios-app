//
//  MyAPPApp.swift
//  MyAPP
//
//  Created by Tosh Yagishita on 21/8/2025.
//

import SwiftUI
import SwiftData

@main
struct OrbitPlannerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: [
                TaskItem.self, LabelTag.self,
                ReminderItem.self, CalendarEvent.self,
                NoteItem.self
            ])
    }
}
