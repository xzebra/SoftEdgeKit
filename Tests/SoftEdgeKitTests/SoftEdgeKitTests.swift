import ObjectiveC
import UIKit
import XCTest
@testable import SoftEdgeKit

@MainActor
final class SoftEdgeKitTests: XCTestCase {
    func testInstallationIsANoOpOnOlderSystems() throws {
        if #available(iOS 27.0, *) {
            throw XCTSkip("Run on iOS 26 or earlier to check the availability guard.")
        }
        if #available(iOS 26.0, *) {
            let selector = #selector(setter: UIScrollEdgeEffect.style)
            let method = try XCTUnwrap(class_getInstanceMethod(UIScrollEdgeEffect.self, selector))
            let original = method_getImplementation(method)
            XCTAssertFalse(SoftEdgeKit.install())
            XCTAssertTrue(original == method_getImplementation(method))
            let scrollView = UIScrollView()
            scrollView.topEdgeEffect.style = .hard
            XCTAssertEqual(scrollView.topEdgeEffect.style, .hard)
        } else {
            XCTAssertFalse(SoftEdgeKit.install())
        }
    }

    func testInstallationIsIdempotent() throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("Requires iOS 27") }
        XCTAssertTrue(SoftEdgeKit.install())
        let selector = #selector(setter: UIScrollEdgeEffect.style)
        let method = try XCTUnwrap(class_getInstanceMethod(UIScrollEdgeEffect.self, selector))
        let installed = method_getImplementation(method)
        for _ in 0..<10 { XCTAssertTrue(SoftEdgeKit.install()) }
        XCTAssertTrue(installed == method_getImplementation(method))
    }

    func testAllEdgesAndLaterStyleChanges() throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("Requires iOS 27") }
        XCTAssertTrue(SoftEdgeKit.install())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        for scrollView in makeScrollViews() {
            window.addSubview(scrollView)
            for effect in effects(of: scrollView) {
                XCTAssertEqual(effect.style, ScrollEdgeOverride.blurStyle)
                for style in [UIScrollEdgeEffect.Style.automatic, .hard, .soft] {
                    effect.style = style
                    XCTAssertEqual(effect.style, ScrollEdgeOverride.blurStyle)
                }
            }
            scrollView.removeFromSuperview()
            window.addSubview(scrollView)
            for effect in effects(of: scrollView) {
                XCTAssertEqual(effect.style, ScrollEdgeOverride.blurStyle)
            }
            scrollView.removeFromSuperview()
        }
    }

    func testHiddenEdgesStayHidden() throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("Requires iOS 27") }
        XCTAssertTrue(SoftEdgeKit.install())
        let scrollView = UIScrollView()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        for effect in effects(of: scrollView) { effect.isHidden = true }
        window.addSubview(scrollView)
        for effect in effects(of: scrollView) {
            effect.style = .hard
            XCTAssertTrue(effect.isHidden)
        }
    }

    func testFactoryPreferenceAndFallbacks() throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("Requires iOS 27") }
        var calls: [Selector] = []
        let first = ScrollEdgeOverride.resolveStyle { selector in
            calls.append(selector)
            return .hard
        }
        XCTAssertEqual(first, .hard)
        XCTAssertEqual(calls.count, 1)
        let preferredSelector = calls.first
        calls.removeAll()
        let second = ScrollEdgeOverride.resolveStyle { selector in
            calls.append(selector)
            return calls.count == 2 ? .automatic : nil
        }
        XCTAssertEqual(second, .automatic)
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls.first, preferredSelector)
        XCTAssertNotEqual(calls.first, calls.last)
        XCTAssertEqual(ScrollEdgeOverride.resolveStyle { _ in nil }, .soft)
    }

    func testCustomStyleIsPreserved() throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("Requires iOS 27") }
        XCTAssertTrue(SoftEdgeKit.install())
        var styles: [UIScrollEdgeEffect.Style] = []
        _ = ScrollEdgeOverride.resolveStyle { selector in
            if let method = class_getClassMethod(UIScrollEdgeEffect.Style.self, selector) {
                typealias Factory = @convention(c) (AnyObject, Selector) -> UIScrollEdgeEffect.Style?
                let factory = unsafeBitCast(method_getImplementation(method), to: Factory.self)
                if let style = factory(UIScrollEdgeEffect.Style.self, selector) { styles.append(style) }
            }
            return nil // Inspect both factories.
        }
        guard let custom = styles.first(where: {
            $0 != .automatic && $0 != .hard && $0 != .soft && $0 != ScrollEdgeOverride.blurStyle
        }) else {
            throw XCTSkip("This runtime has no distinct custom style to exercise.")
        }
        let scrollView = UIScrollView()
        scrollView.topEdgeEffect.style = custom
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.addSubview(scrollView)
        XCTAssertEqual(scrollView.topEdgeEffect.style, custom)
        XCTAssertEqual(ScrollEdgeOverride.preferredStyle(for: custom), custom)
    }

    private func makeScrollViews() -> [UIScrollView] {
        [UIScrollView(), UITableView(), UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())]
    }

    @available(iOS 26.0, *)
    private func effects(of scrollView: UIScrollView) -> [UIScrollEdgeEffect] {
        [scrollView.topEdgeEffect, scrollView.bottomEdgeEffect, scrollView.leftEdgeEffect, scrollView.rightEdgeEffect]
    }
}
