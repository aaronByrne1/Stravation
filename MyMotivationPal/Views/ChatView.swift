//import SwiftUI
//
//struct ChatView: View {
//    @ObservedObject var viewModel: ChatViewModel
//
//    var body: some View {
//        VStack {
//            List(viewModel.messages) { message in
//                VStack(alignment: .leading) {
//                    Text("\(message.sender): \(message.text)")
//                        .font(.body)
//                }
//            }
//
//            if !viewModel.aiResponse.isEmpty {
//                Text("AI says: \(viewModel.aiResponse)")
//                    .font(.headline)
//                    .padding()
//            }
//        }
//    }
//}
