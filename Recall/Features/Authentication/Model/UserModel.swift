import Foundation
import FirebaseFirestore

struct UserEntity: Codable, Identifiable {

    
    @DocumentID var id: String?
    var email: String
    var fullName: String
    var profileImageUrl: String?
    var authProvider: AuthProvider
    var createdAt: Date
    var updatedAt: Date
    var totalMemories: Int
    var notificationsEnabled: Bool
    var isPremium: Bool
    

    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let firstInitial = components.first?.first ?? Character("")
        let lastInitial = components.count > 1 ? components.last?.first ?? Character("") : Character("")
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    var displayName: String {
        fullName.isEmpty ? email.components(separatedBy: "@").first ?? "User" : fullName
    }
    
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case profileImageUrl = "profile_image_url"
        case authProvider = "auth_provider"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalMemories = "total_memories"
        case notificationsEnabled = "notifications_enabled"
        case isPremium = "is_premium"
    }
    
    
    
    init(
        id: String? = nil,
        email: String,
        fullName: String = "",
        profileImageUrl: String? = nil,
        authProvider: AuthProvider = .email,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        totalMemories: Int = 0,
        notificationsEnabled: Bool = true,
        isPremium: Bool = false
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.profileImageUrl = profileImageUrl
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalMemories = totalMemories
        self.notificationsEnabled = notificationsEnabled
        self.isPremium = isPremium
    }
}


enum AuthProvider: String, Codable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}



extension UserEntity {
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "full_name": fullName,
            "profile_image_url": profileImageUrl ?? "",
            "auth_provider": authProvider.rawValue,
            "created_at": Timestamp(date: createdAt),
            "updated_at": Timestamp(date: updatedAt),
            "total_memories": totalMemories,
            "notifications_enabled": notificationsEnabled,
            "is_premium": isPremium
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> UserEntity? {
        guard let email = data["email"] as? String else { return nil }
        
        let fullName = data["full_name"] as? String ?? ""
        let profileImageUrl = data["profile_image_url"] as? String
        let authProviderString = data["auth_provider"] as? String ?? "email"
        let authProvider = AuthProvider(rawValue: authProviderString) ?? .email
        
        let createdAtTimestamp = data["created_at"] as? Timestamp
        let updatedAtTimestamp = data["updated_at"] as? Timestamp
        
        let totalMemories = data["total_memories"] as? Int ?? 0
        let notificationsEnabled = data["notifications_enabled"] as? Bool ?? true
        let isPremium = data["is_premium"] as? Bool ?? false
        
        return UserEntity(
            id: id,
            email: email,
            fullName: fullName,
            profileImageUrl: profileImageUrl,
            authProvider: authProvider,
            createdAt: createdAtTimestamp?.dateValue() ?? Date(),
            updatedAt: updatedAtTimestamp?.dateValue() ?? Date(),
            totalMemories: totalMemories,
            notificationsEnabled: notificationsEnabled,
            isPremium: isPremium
        )
    }
}


//extension UserEntity {
//    static var mockUser: UserEntity {
//        UserEntity(
//            id: "mock_user_123",
//            email: "aditya@example.com",
//            fullName: "Aditya Chauhan",
//            profileImageUrl: nil,
//            authProvider: .email,
//            createdAt: Date(),
//            updatedAt: Date(),
//            totalMemories: 42,
//            notificationsEnabled: true,
//            isPremium: false
//        )
//    }
//    
//    static var mockGoogleUser: UserEntity {
//        UserEntity(
//            id: "mock_google_456",
//            email: "aditya@gmail.com",
//            fullName: "Aditya Chauhan",
//            profileImageUrl: "https://example.com/avatar.jpg",
//            authProvider: .google,
//            createdAt: Date(),
//            updatedAt: Date(),
//            totalMemories: 15,
//            notificationsEnabled: true,
//            isPremium: true
//        )
//    }
//}
