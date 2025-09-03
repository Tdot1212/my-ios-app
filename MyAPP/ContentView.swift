//
//  ContentView.swift
//  MyAPP
//
//  Created by Tosh Yagishita on 21/8/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Dashboard", systemImage: "house") }
            TasksView().tabItem { Label("Tasks", systemImage: "list.bullet") }
            CalendarView().tabItem { Label("Calendar", systemImage: "calendar") }
            NotesView().tabItem { Label("Notes", systemImage: "note.text") }
            TrendsView().tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
            NavigationStack { AISettingsView() }.tabItem { Label("Settings", systemImage: "gear") }
        }
        .task { await NotificationManager.requestAuth() }
        .onAppear { RolloverService.autoRollover(context) }
        .onChange(of: scenePhase) { _, p in if p == .active { RolloverService.autoRollover(context) } }
        .accentColor(Color(hex: "#4F46E5"))
    }
}

#Preview {
    ContentView()
}
