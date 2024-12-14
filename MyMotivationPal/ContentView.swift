import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            // Once signed in, wrap content in a NavigationStack to show a navigation bar
            NavigationStack {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, signed-in world!")
                }
                .padding()
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Sign out") {
                            isAuthenticated = false
                        }
                    }
                }
            }
        } else {
            // When not signed in, show a sign-in button
            VStack(spacing: 20) {
                Text("Please sign in")
                    .font(.title)
                Button("Sign in") {
                    // Replace with your actual sign-in logic
                    isAuthenticated = true
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
