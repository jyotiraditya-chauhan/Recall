import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    @StateObject private var authViewModel = AuthenticationViewModel.shared
    @EnvironmentObject var router: Router
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false

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
                    action: {}
                )

                Divider()
                    .background(AppColor.grey.opacity(0.3))

                SettingsRow(
                    icon: "lock.fill",
                    title: "Privacy & Security",
                    showChevron: true,
                    action: {}
                )

                Divider()
                    .background(AppColor.grey.opacity(0.3))

                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    showChevron: true,
                    action: {}
                )

                Divider()
                    .background(AppColor.grey.opacity(0.3))

                SettingsRow(
                    icon: "info.circle.fill",
                    title: "About",
                    showChevron: true,
                    action: {}
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
        .disabled(showToggle)
    }
}

#Preview {
    ProfileView()
        .environmentObject(Router())
}
