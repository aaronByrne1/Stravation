import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

            SecureField("Password", text: $password)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            if isLoading {
                ProgressView()
            } else {
                Button(action: signIn) {
                    Text("Sign In")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(email.isEmpty || password.isEmpty)
                .padding(.horizontal)
            }
        }
        .padding()
    }

    func signIn() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let session = try await supabase.auth.signIn(email: email, password: password)
                isAuthenticated = (session != nil)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
