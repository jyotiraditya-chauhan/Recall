import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol ProfileViewModelProtocol: ObservableObject {
    var currentUser: UserEntity? { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var notificationsEnabled: Bool { get set }

    func fetchUserProfile() async
    func updateProfile(fullName: String?, profileImageUrl: String?) async
    func toggleNotifications() async
    func signOut() async throws
}

@MainActor
class ProfileViewModel: ProfileViewModelProtocol, ObservableObject {
    static let shared = ProfileViewModel()

    @Published var currentUser: UserEntity?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var notificationsEnabled = true

    private let db = Firestore.firestore()
    private let authService = AuthService.shared

    private init() {
        Task {
            await fetchUserProfile()
        }
    }

    func fetchUserProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let data = doc.data() {
                currentUser = try? Firestore.Decoder().decode(UserEntity.self, from: data)
                notificationsEnabled = currentUser?.notificationsEnabled ?? true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateProfile(fullName: String?, profileImageUrl: String?) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        var updateData: [String: Any] = [
            "updated_at": Timestamp(date: Date())
        ]

        if let fullName = fullName {
            updateData["full_name"] = fullName
        }

        if let profileImageUrl = profileImageUrl {
            updateData["profile_image_url"] = profileImageUrl
        }

        do {
            try await db.collection("users").document(userId).updateData(updateData)
            await fetchUserProfile()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleNotifications() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        notificationsEnabled.toggle()

        do {
            try await db.collection("users").document(userId).updateData([
                "notifications_enabled": notificationsEnabled,
                "updated_at": Timestamp(date: Date())
            ])
        } catch {
            errorMessage = error.localizedDescription
            notificationsEnabled.toggle()
        }
    }

    func signOut() async throws {
        try authService.signOut()
        currentUser = nil
        notificationsEnabled = true
    }

    func deleteAccount() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ProfileViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        isLoading = true
        errorMessage = nil

        do {
            try await db.collection("memories").whereField("user_id", isEqualTo: userId).getDocuments().documents.forEach { doc in
                Task {
                    try await doc.reference.delete()
                }
            }

            try await db.collection("users").document(userId).delete()

            try await Auth.auth().currentUser?.delete()

            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }
}
