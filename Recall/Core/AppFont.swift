import SwiftUI

extension Font {
    static func urbanistRegular(size: CGFloat) -> Font {
        return .custom("Urbanist-Regular", size: size)
    }

    static func urbanistLight(size: CGFloat) -> Font {
        return .custom("Urbanist-Light", size: size)
    }

    static func urbanistSemiBold(size: CGFloat) -> Font {
        return .custom("Urbanist-SemiBold", size: size)
    }

    static func urbanistBold(size: CGFloat) -> Font {
        return .custom("Urbanist-Bold", size: size)
    }
}

extension Font {
    static var appTitle: Font {
        .urbanistBold(size: 32)
    }

    static var screenTitle: Font {
        .urbanistBold(size: 28)
    }

    static var appScreenTitle: Font {
        .urbanistBold(size: 28)
    }

    static var headline: Font {
        .urbanistSemiBold(size: 20)
    }

    static var appHeadline: Font {
        .urbanistSemiBold(size: 20)
    }

    static var bodyText: Font {
        .urbanistRegular(size: 16)
    }

    static var appBodyText: Font {
        .urbanistRegular(size: 16)
    }

    static var bodyLarge: Font {
        .urbanistRegular(size: 18)
    }

    static var appBodyLarge: Font {
        .urbanistRegular(size: 18)
    }

    static var caption: Font {
        .urbanistLight(size: 14)
    }

    static var appCaption: Font {
        .urbanistLight(size: 14)
    }

    static var label: Font {
        .urbanistSemiBold(size: 14)
    }

    static var appLabel: Font {
        .urbanistSemiBold(size: 14)
    }

    static var buttonText: Font {
        .urbanistSemiBold(size: 16)
    }

    static var appButtonText: Font {
        .urbanistSemiBold(size: 16)
    }

    static var buttonLarge: Font {
        .urbanistBold(size: 18)
    }

    static var appButtonLarge: Font {
        .urbanistBold(size: 18)
    }
}
