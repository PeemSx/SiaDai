//
//  Sia_DaiApp.swift
//  Sia-Dai
//
//  Created by Supanat Kampapan on 3/4/2569 BE.
//

import SwiftUI
import SwiftData

@main
struct Root: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FoodItem.self])
    }
}
