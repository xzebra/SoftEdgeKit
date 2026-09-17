import UIKit

/// Restores soft scroll edges throughout an iOS app.
///
/// Call ``install()`` on the main actor before creating your app's UI. The override
/// uses private UIKit APIs and remains installed for the lifetime of the process.
@MainActor
@available(macCatalyst, unavailable)
public enum SoftEdgeKit {
    /// Installs the process-wide scroll-edge override once.
    ///
    /// On iOS 27 and later, automatic, hard, and soft styles are replaced with
    /// UIKit's Photos blur style, falling back to Messages and then public soft.
    /// Hidden edges and other custom styles are preserved. Earlier iOS versions
    /// are left unchanged. Repeated calls are safe.
    ///
    /// - Returns: `true` when the override is installed (including a previous
    ///   installation), or `false` on older iOS versions or if UIKit's required
    ///   runtime methods cannot be found.
    @discardableResult
    public static func install() -> Bool {
        guard #available(iOS 27.0, *) else { return false }
        return ScrollEdgeOverride.installOnce
    }
}
