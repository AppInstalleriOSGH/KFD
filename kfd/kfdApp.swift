/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

import SwiftUI

@main
struct kfdApp: App {
    init() {
        UIPasteboard.general.string = "test 1"
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
            .onAppear {
                UIPasteboard.general.string = "test 2"
            }
        }
    }
}