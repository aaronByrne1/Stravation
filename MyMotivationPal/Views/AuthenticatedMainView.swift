import SwiftUI

struct AuthenticatedMainView: View {
    var heartRateViewModel: HeartRateViewModel
    var onDisconnect: () -> Void  // This closure comes from the parent

    // If you have a ChatViewModel or any other views, add them here.

    var body: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            HeartRateView(viewModel: heartRateViewModel, onDisconnect: onDisconnect)
                            .tabItem {
                                Label("Heart Rate", systemImage: "heart.fill")
                            }

            // If you add ChatView back:
            // ChatView(viewModel: chatViewModel)
            //   .tabItem {
            //       Label("Chat", systemImage: "message.fill")
            //   }
        }
    }
}
