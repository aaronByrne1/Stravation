import SwiftUI

struct ProfileView: View {
    @State private var username = ""
    @State private var fullName = ""
    @State private var website = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    TextField("Username", text: $username)
                    TextField("Full name", text: $fullName)
                    TextField("Website", text: $website)
                }

                Section {
                    Button("Update Profile") {
                        updateProfile()
                    }

                    if isLoading {
                        ProgressView()
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        Task {
                            try? await supabase.auth.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                Task {
                    await loadProfile()
                }
            }
        }
    }

    func loadProfile() async {
        do {
            let user = try await supabase.auth.session.user
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .single()
                .execute()
                .value
            username = profile.username ?? ""
            fullName = profile.fullName ?? ""
            website = profile.website ?? ""
        } catch {
            //print("Error loading profile: \(error)")
        }
    }

    func updateProfile() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let user = try await supabase.auth.session.user
                try await supabase.from("profiles").update(UpdateProfileParams(username: username, fullName: fullName, website: website))
                    .eq("id", value: user.id)
                    .execute()
            } catch {
                //print("Error updating profile: \(error)")
            }
        }
    }
}
