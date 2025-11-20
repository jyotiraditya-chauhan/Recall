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
        print("🔄 ProfileViewModel: Starting fetchUserProfile")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ ProfileViewModel: User not authenticated")
            errorMessage = "User not authenticated"
            return
        }

        print("✅ ProfileViewModel: User authenticated with ID: \(userId)")
        isLoading = true
        errorMessage = nil

        do {
            print("🔍 ProfileViewModel: Fetching user document from Firestore")
            let doc = try await db.collection("users").document(userId).getDocument()
            
            if let data = doc.data() {
                print("✅ ProfileViewModel: User document found, data: \(data)")
                currentUser = UserEntity.fromDictionary(data, id: userId)
                
                if let user = currentUser {
                    print("✅ ProfileViewModel: User successfully decoded: \(user.email)")
                    notificationsEnabled = user.notificationsEnabled
                } else {
                    print("❌ ProfileViewModel: Failed to decode user data")
                    errorMessage = "Failed to decode user data"
                }
            } else {
                print("⚠️ ProfileViewModel: User document doesn't exist, creating new one")
                await createUserProfile(userId: userId)
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching user profile: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
        print("🔄 ProfileViewModel: fetchUserProfile completed. Current user: \(currentUser?.email ?? "nil")")
    }
    
    private func createUserProfile(userId: String) async {
        print("🔨 ProfileViewModel: Creating new user profile for ID: \(userId)")
        
        guard let firebaseUser = Auth.auth().currentUser else {
            print("❌ ProfileViewModel: No Firebase user found")
            return
        }
        
        print("🔨 ProfileViewModel: Firebase user found - email: \(firebaseUser.email ?? "no email")")
        
        let userEntity = UserEntity(
            id: userId,
            email: firebaseUser.email ?? "",
            fullName: firebaseUser.displayName ?? "User",
            profileImageUrl: firebaseUser.photoURL?.absoluteString,
            authProvider: determineAuthProvider(firebaseUser),
            createdAt: Date(),
            updatedAt: Date(),
            totalMemories: 0,
            notificationsEnabled: true,
            isPremium: false
        )
        
        print("🔨 ProfileViewModel: Created UserEntity: \(userEntity.email)")
        
        do {
            let dictionary = userEntity.toDictionary()
            print("🔨 ProfileViewModel: User dictionary: \(dictionary)")
            
            try await db.collection("users").document(userId).setData(dictionary)
            print("✅ ProfileViewModel: Successfully saved user document to Firestore")
            
            currentUser = userEntity
            notificationsEnabled = true
            print("✅ ProfileViewModel: Set currentUser in memory")
        } catch {
            print("❌ ProfileViewModel: Failed to create user profile: \(error)")
            errorMessage = "Failed to create user profile: \(error.localizedDescription)"
        }
    }
    
    private func determineAuthProvider(_ user: User) -> AuthProvider {
        for userInfo in user.providerData {
            switch userInfo.providerID {
            case "google.com":
                return .google
            case "apple.com":
                return .apple
            default:
                continue
            }
        }
        return .email
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
            let documents = try await db.collection("memories").whereField("user_id", isEqualTo: userId).getDocuments().documents
            try await withThrowingTaskGroup(of: Void.self) { group in
                for doc in documents {
                    group.addTask {
                        try await doc.reference.delete()
                    }
                }
                try await group.waitForAll()
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
