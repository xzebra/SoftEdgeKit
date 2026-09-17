# SoftEdgeKit

Restore soft, blurred scroll edges on iOS 27 with one call. Works with UIKit scroll views, table views, collection views, and SwiftUI views backed by them, including lists and sheets.

```swift
import SoftEdgeKit

SoftEdgeKit.install()
```

Zero dependencies. Swift Package Manager. iOS 15+ deployment target; the override only activates on iOS 27+.

> **Disclaimer — private APIs and method swizzling:** SoftEdgeKit calls private UIKit style factories and swizzles UIKit methods to override scroll-edge styling process-wide. Private selector names are obfuscated, but this does **not** guarantee App Store approval or make private API usage compliant with [App Review Guideline 2.5.1](https://developer.apple.com/app-store/review/guidelines/#software-requirements), which requires public APIs. Apps using this library may be rejected. OS updates can break the behavior, and swizzling can conflict with other code modifying the same methods. Use at your own risk. Public `.soft` is the fallback when neither private factory is available.

## Installation

**The minimum supported iOS version is 15. Apps targeting iOS 18 can use this package without changing their deployment target.**

| Requirement | Version |
| --- | --- |
| Minimum app deployment target | iOS 15 |
| Build toolchain | Xcode 26+ (includes the SDK declarations for `UIScrollEdgeEffect`) |
| Scroll-edge override activates | iOS 27+; earlier versions are unchanged |

Supports iPhone and iPad; Mac Catalyst and other platforms are not supported.

### Xcode

Choose **File → Add Package Dependencies**, enter the repository URL, select **Up to Next Major Version** from **1.0.0**, and add the **SoftEdgeKit** product to your app target:

```text
https://github.com/xzebra/SoftEdgeKit
```

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/xzebra/SoftEdgeKit.git", from: "1.0.0")
]
```

Add the product to the target that imports it:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SoftEdgeKit", package: "SoftEdgeKit")
    ]
)
```

For local development, use **Add Local** in Xcode and select this directory.

## Usage

Call `install()` on the main actor during app startup, **before creating the UI**. You do not need an availability check. On iOS 26 and earlier it returns `false` without changing UIKit.

### SwiftUI

```swift
import SwiftUI
import SoftEdgeKit

@main
struct MyApp: App {
    init() {
        SoftEdgeKit.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView() // Your existing root view.
        }
    }
}
```

### UIKit

```swift
import UIKit
import SoftEdgeKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        SoftEdgeKit.install()
        return true
    }
}
```

Keep your existing app delegate and scene setup; add the import and installation call.

## Behavior

- Replaces `.automatic`, `.hard`, and public `.soft` with the private Photos blur style, then Messages if Photos is unavailable, then public `.soft`.
- Applies to top, bottom, left, and right edges when a scroll view enters a window, and intercepts subsequent style assignments.
- Preserves `isHidden` and other custom styles.
- Installs once per process. Repeated calls return the same result without wrapping methods again.
- Returns `true` when installed, or `false` on older iOS versions or when required runtime methods are missing. `true` does not guarantee a private factory was available.

Installation is global and lasts until the process exits. There is no per-view opt-out or uninstall operation. Install before views appear; existing visible scroll views are updated when they reenter a window or receive another style assignment. Custom subclasses that override `didMoveToWindow()` must call `super`. Other libraries replacing the same UIKit methods can interfere with this behavior.

## Development

Open `Package.swift` in Xcode and select an iOS simulator to build or test. `swift test` on macOS cannot run UIKit tests. Run the suite on iOS 27 for override behavior and iOS 26 for the no-op check.

To run the tests from the command line, select an installed iOS simulator:

```sh
xcodebuild test \
  -scheme SoftEdgeKit \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

GitHub Actions builds the release library.

Validated with an Xcode 26.6 release build and Xcode 27 beta 6 runtime tests on iOS 27 and iOS 26.5. The suite covers all four edges across scroll/table/collection views, later assignments, hidden edges, custom styles, repeated installation, factory fallbacks, and the older-OS no-op.

## Credits and license

Extracted from the iOS 27 scroll-edge fix originally developed for Whop. Distributed under the [MIT license](LICENSE).
