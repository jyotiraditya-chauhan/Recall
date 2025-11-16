import SwiftUI

extension Font {
    // Urbanist Regular
    static func urbanistRegular(size: CGFloat) -> Font {
        return .custom("Urbanist-Regular", size: size)
    }
    
    // Urbanist Light
    static func urbanistLight(size: CGFloat) -> Font {
        return .custom("Urbanist-Light", size: size)
    }
    
    // Urbanist SemiBold
    static func urbanistSemiBold(size: CGFloat) -> Font {
        return .custom("Urbanist-SemiBold", size: size)
    }
    
    // Urbanist Bold
    static func urbanistBold(size: CGFloat) -> Font {
        return .custom("Urbanist-Bold", size: size)
    }
}

// Predefined text styles for your app
extension Font {
    // Titles
    static var appTitle: Font {
        .urbanistBold(size: 32)
    }
    
    static var screenTitle: Font {
        .urbanistBold(size: 28)
    }
    
    // Headlines
    static var headline: Font {
        .urbanistSemiBold(size: 20)
    }
    
    // Body text
    static var bodyText: Font {
        .urbanistRegular(size: 16)
    }
    
    static var bodyLarge: Font {
        .urbanistRegular(size: 18)
    }
    
    // Captions & Labels
    static var caption: Font {
        .urbanistLight(size: 14)
    }
    
    static var label: Font {
        .urbanistSemiBold(size: 14)
    }
    
    // Buttons
    static var buttonText: Font {
        .urbanistSemiBold(size: 16)
    }
    
    static var buttonLarge: Font {
        .urbanistBold(size: 18)
    }
}
