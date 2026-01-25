//
//  ContentView.swift
//  newTestSwiftData
//
//  Created by cjx on 2026/1/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Post.self, inMemory: true)
}
