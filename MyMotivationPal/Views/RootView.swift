import SwiftUI

struct RootView: View {
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
            }
        }
        .task {
            // Monitor Supabase Auth State Changes
            for await state in supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    isAuthenticated = (state.session != nil)
                }
            }
        }
    }
}
