import SwiftUI
import Supabase

struct AuthView: View {
  @State var email = ""
  @State var isLoading = false
  @State var result: Result<Void, Error>?

  var body: some View {
    Form {
      Section {
        TextField("Email", text: $email)
          .textContentType(.emailAddress)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
      }

      Section {
        Button("Sign in") {
          signInButtonTapped()
        }

        if isLoading {
          ProgressView()
        }
      }

      if let result {
        Section {
          switch result {
          case .success:
            Text("Check your inbox.")
          case .failure(let error):
            Text(error.localizedDescription).foregroundStyle(.red)
          }
        }
      }
    }
    .onOpenURL(perform: { url in
      Task {
        do {
          try await supabase.auth.session(from: url)
        } catch {
          self.result = .failure(error)
        }
      }
    })
  }

  func signInButtonTapped() {
    Task {
      isLoading = true
      defer { isLoading = false }

      do {
        try await supabase.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "io.hackathon.motivation-app://login-callback")
        )
        result = .success(())
      } catch {
        result = .failure(error)
      }
    }
  }
}
