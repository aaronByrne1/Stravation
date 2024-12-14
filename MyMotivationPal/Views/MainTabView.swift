import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MotivatorView()
                .tabItem {
                    Label("Motivator", systemImage: "figure.run")
                }

            PublicRunsView()
                .tabItem {
                    Label("Public Runs", systemImage: "globe")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}
