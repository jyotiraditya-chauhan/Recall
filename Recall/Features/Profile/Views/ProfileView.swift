import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    @StateObject private var authViewModel = AuthenticationViewModel.shared
    @EnvironmentObject var router: Router
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showEditProfileSheet = false
    @State private var showAboutSheet = false
    @State private var showHelpSheet = false
    @State private var showPrivacySheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerView

                    if let user = viewModel.currentUser {
                        userInfoCard(user: user)
                        statsCard(user: user)
                        settingsSection
                    } else if viewModel.isLoading {
                        ProgressView()
                            .tint(AppColor.primary)
                        Text("Loading profile...")
                            .foregroundColor(AppColor.grey)
                            .font(.appCaption)
                    } else {
                        // Debug info when no user and not loading
                        VStack(spacing: 12) {
                            Text("No Profile Data")
                                .font(.appHeadline)
                                .foregroundColor(AppColor.white)
                            
                            if let errorMessage = viewModel.errorMessage {
                                Text("Error: \(errorMessage)")
                                    .font(.appBodyText)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Text("Auth Status: \(Auth.auth().currentUser?.email ?? "Not logged in")")
                                .font(.appCaption)
                                .foregroundColor(AppColor.grey)
                                .multilineTextAlignment(.center)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 16) {
                                    Button("Retry") {
                                        print("📱 ProfileView: Retry button tapped")
                                        Task {
                                            await viewModel.fetchUserProfile()
                                        }
                                    }
                                    .foregroundColor(AppColor.primary)
                                    .font(.appBodyLarge)
                                    
                                    Button("Debug") {
                                        print("📱 ProfileView: Debug info:")
                                        print("📱 Current user: \(viewModel.currentUser?.email ?? "nil")")
                                        print("📱 Is loading: \(viewModel.isLoading)")
                                        print("📱 Error: \(viewModel.errorMessage ?? "nil")")
                                        print("📱 Auth user: \(Auth.auth().currentUser?.email ?? "nil")")
                                    }
                                    .foregroundColor(.orange)
                                    .font(.appBodyLarge)
                                }
                                
                                Button("Sign Out") {
                                    Task {
                                        await handleLogout()
                                    }
                                }
                                .foregroundColor(.red)
                                .font(.appBodyLarge)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(hex: "#1C1C1C"))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                Task {
                    await handleLogout()
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await handleDeleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. All your memories will be permanently deleted.")
        }
        .onAppear {
            print("📱 ProfileView: onAppear called")
            print("📱 ProfileView: Current user: \(viewModel.currentUser?.email ?? "nil")")
            print("📱 ProfileView: Is loading: \(viewModel.isLoading)")
            print("📱 ProfileView: Error message: \(viewModel.errorMessage ?? "nil")")
            
            Task {
                print("📱 ProfileView: Calling fetchUserProfile")
                await viewModel.fetchUserProfile()
            }
        }
        .sheet(isPresented: $showEditProfileSheet) {
            EditProfileSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
        .sheet(isPresented: $showHelpSheet) {
            HelpSheet()
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacySheet()
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColor.white)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#1C1C1C"))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Profile")
                .font(.appScreenTitle)
                .foregroundColor(AppColor.white)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.top, 16)
    }

    private func userInfoCard(user: UserEntity) -> some View {
        VStack(spacing: 16) {
            if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text(user.initials)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 100, height: 100)
                .background(AppColor.primary)
                .clipShape(Circle())
            } else {
                Text(user.initials)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(AppColor.primary)
                    .clipShape(Circle())
            }

            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.appHeadline)
                    .foregroundColor(AppColor.white)

                Text(user.email)
                    .font(.appBodyText)
                    .foregroundColor(AppColor.grey)
            }

            HStack(spacing: 8) {
                Image(systemName: authProviderIcon(user.authProvider))
                    .font(.system(size: 14))
                    .foregroundColor(AppColor.grey)

                Text(user.authProvider.rawValue.capitalized)
                    .font(.appCaption)
                    .foregroundColor(AppColor.grey)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(hex: "#1C1C1C"))
        .cornerRadius(16)
    }

    private func statsCard(user: UserEntity) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("\(user.totalMemories)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColor.primary)

                Text("Memories")
                    .font(.appCaption)
                    .foregroundColor(AppColor.grey)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(AppColor.grey.opacity(0.3))
                .frame(width: 1, height: 50)

            VStack(spacing: 8) {
                Text(user.isPremium ? "Premium" : "Free")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(user.isPremium ? .yellow : AppColor.white)

                Text("Account")
                    .font(.appCaption)
                    .foregroundColor(AppColor.grey)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(Color(hex: "#1C1C1C"))
        .cornerRadius(16)
    }

    private var settingsSection: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.appHeadline)
                .foregroundColor(AppColor.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    showToggle: true,
                    isToggleOn: $viewModel.notificationsEnabled,
                    onToggle: {
                        Task {
                            await viewModel.toggleNotifications()
                        }
                    }
                )

                Divider()
                    .background(AppColor.grey.opacity(0.3))

                SettingsRow(
                    icon: "person.fill",
                    title: "Edit Profile",
                    showChevron: true,
                    action: {
                        showEditProfileSheet = true
                    }
                )

                Divider()
                    .background(AppColor.grey.opacity(0.3))

                SettingsRow(
                    icon: "lock.fill",
                    title: "Privacy & Security",
                    showChevron: true,
                    action: {
                        showPrivacySheet = true
                    }
                )

                Divider()
                    .background(AppColor.grey.opacity(0.3))

                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    showChevron: true,
                    action: {
                        showHelpSheet = true
                    }
                )

                Divider()
                    .background(AppColor.grey.opacity(0.3))

                SettingsRow(
                    icon: "info.circle.fill",
                    title: "About",
                    showChevron: true,
                    action: {
                        showAboutSheet = true
                    }
                )
            }
            .padding(16)
            .background(Color(hex: "#1C1C1C"))
            .cornerRadius(16)

            VStack(spacing: 12) {
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)

                        Text("Logout")
                            .font(.appBodyLarge)
                            .foregroundColor(.red)

                        Spacer()
                    }
                    .padding(16)
                    .background(Color(hex: "#1C1C1C"))
                    .cornerRadius(12)
                }

                Button(action: {
                    showDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)

                        Text("Delete Account")
                            .font(.appBodyLarge)
                            .foregroundColor(.red)

                        Spacer()
                    }
                    .padding(16)
                    .background(Color(hex: "#1C1C1C"))
                    .cornerRadius(12)
                }
            }
        }
    }

    private func authProviderIcon(_ provider: AuthProvider) -> String {
        switch provider {
        case .email:
            return "envelope.fill"
        case .google:
            return "g.circle.fill"
        case .apple:
            return "apple.logo"
        }
    }

    private func handleLogout() async {
        do {
            try await viewModel.signOut()
            router.navigateTo(.login)
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }

    private func handleDeleteAccount() async {
        do {
            try await viewModel.deleteAccount()
            router.navigateTo(.login)
        } catch {
            print("Error deleting account: \(error.localizedDescription)")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var showToggle: Bool = false
    var isToggleOn: Binding<Bool>?
    var onToggle: (() -> Void)?
    var showChevron: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColor.primary)
                    .frame(width: 30)

                Text(title)
                    .font(.appBodyLarge)
                    .foregroundColor(AppColor.white)

                Spacer()

                if showToggle, let isToggleOn = isToggleOn {
                    Toggle("", isOn: isToggleOn)
                        .labelsHidden()
                        .tint(AppColor.primary)
                        .onChange(of: isToggleOn.wrappedValue) { _ in
                            onToggle?()
                        }
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.grey)
                }
            }
        }
        .disabled(false)
    }
}

// MARK: - Sheet Views

struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var profileImageUrl: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    // Profile Image Section
                    if let user = viewModel.currentUser {
                        if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Text(user.initials)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 100, height: 100)
                            .background(AppColor.primary)
                            .clipShape(Circle())
                        } else {
                            Text(user.initials)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(AppColor.primary)
                                .clipShape(Circle())
                        }
                    }
                    
                    Button("Change Photo") {
                        // TODO: Add image picker
                    }
                    .foregroundColor(AppColor.primary)
                    .font(.appBodyLarge)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        TextField("Enter your name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(Color(hex: "#1C1C1C"))
                            .foregroundColor(AppColor.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(Color(hex: "#1C1C1C"))
                            .foregroundColor(AppColor.white)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Spacer()
                
                Button("Save Changes") {
                    Task {
                        await viewModel.updateProfile(fullName: fullName.isEmpty ? nil : fullName, profileImageUrl: profileImageUrl.isEmpty ? nil : profileImageUrl)
                        dismiss()
                    }
                }
                .foregroundColor(.white)
                .font(.appBodyLarge)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColor.primary)
                .cornerRadius(12)
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.primary)
                }
            }
        }
        .onAppear {
            if let user = viewModel.currentUser {
                fullName = user.fullName
                email = user.email
                profileImageUrl = user.profileImageUrl ?? ""
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(AppColor.primary)
                        
                        Text("Recall")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColor.white)
                        
                        Text("Version 1.0.0")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About Recall")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                        
                        Text("Recall is your personal memory assistant, designed to help you capture, organize, and retrieve your thoughts and reminders effortlessly. With powerful voice integration through Siri, you can save memories on the go and never forget important moments or tasks.")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                            .lineSpacing(4)
                        
                        Text("Features")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Voice-activated memory storage with Siri")
                            Text("• Priority-based organization")
                            Text("• Person and context-based tagging")
                            Text("• Secure cloud synchronization")
                            Text("• Smart search and filtering")
                        }
                        .font(.appBodyText)
                        .foregroundColor(AppColor.grey)
                        
                        Text("Developer")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                            .padding(.top)
                        
                        Text("Developed with ❤️ by the Recall Team")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.primary)
                }
            }
        }
    }
}

struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Getting Started")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                        
                        Text("Welcome to Recall! Here's how to get the most out of your memory assistant:")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HelpItem(
                                title: "Creating Memories",
                                description: "Tap the + button to add a new memory, or use Siri with phrases like 'Remember to call mom in Recall'"
                            )
                            
                            HelpItem(
                                title: "Using Siri",
                                description: "Say 'Remember [your memory] in Recall' or 'Add urgent reminder [task] in Recall' to quickly save thoughts"
                            )
                            
                            HelpItem(
                                title: "Organizing Memories",
                                description: "Set priorities (Low, Medium, High, Urgent) and add tags to keep your memories organized"
                            )
                            
                            HelpItem(
                                title: "Finding Memories",
                                description: "Use the search bar or filter by priority and completion status to find what you need"
                            )
                        }
                        
                        Text("Frequently Asked Questions")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HelpItem(
                                title: "How do I enable Siri?",
                                description: "Go to Settings > Siri & Search, then enable Siri for Recall app"
                            )
                            
                            HelpItem(
                                title: "Can I sync across devices?",
                                description: "Yes! Your memories are securely stored in the cloud and sync across all your devices"
                            )
                            
                            HelpItem(
                                title: "How do I delete a memory?",
                                description: "Swipe left on any memory in your list and tap the delete button"
                            )
                        }
                        
                        Text("Need More Help?")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                            .padding(.top)
                        
                        Text("Contact us at support@recallapp.com for additional assistance.")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.primary)
                }
            }
        }
    }
}

struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy & Security")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                        
                        Text("Your privacy is our priority. Here's how we protect your data:")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HelpItem(
                                title: "Data Encryption",
                                description: "All your memories are encrypted both in transit and at rest using industry-standard encryption"
                            )
                            
                            HelpItem(
                                title: "Secure Authentication",
                                description: "We use Firebase Authentication to ensure only you can access your memories"
                            )
                            
                            HelpItem(
                                title: "No Data Sharing",
                                description: "We never share your personal memories or data with third parties"
                            )
                            
                            HelpItem(
                                title: "Data Ownership",
                                description: "Your memories belong to you. You can export or delete your data at any time"
                            )
                        }
                        
                        Text("Account Security")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HelpItem(
                                title: "Two-Factor Authentication",
                                description: "Enable 2FA in your account settings for additional security"
                            )
                            
                            HelpItem(
                                title: "Regular Security Updates",
                                description: "We regularly update our security measures to protect against new threats"
                            )
                            
                            HelpItem(
                                title: "Account Recovery",
                                description: "Secure account recovery options are available if you lose access to your account"
                            )
                        }
                        
                        Text("Contact Us")
                            .font(.appHeadline)
                            .foregroundColor(AppColor.white)
                            .padding(.top)
                        
                        Text("If you have privacy or security concerns, contact us at privacy@recallapp.com")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.primary)
                }
            }
        }
    }
}

struct HelpItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.appBodyLarge)
                .foregroundColor(AppColor.white)
            
            Text(description)
                .font(.appBodyText)
                .foregroundColor(AppColor.grey)
                .lineSpacing(2)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(Router())
}
