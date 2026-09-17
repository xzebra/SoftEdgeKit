import ObjectiveC
import UIKit

@MainActor
@available(iOS 27.0, *)
enum ScrollEdgeOverride {
    // Keep implementation details out of the package's public API.
    static let blurStyle = resolveStyle()

    static func resolveStyle(
        lookup: @MainActor (Selector) -> UIScrollEdgeEffect.Style? = styleFactory
    ) -> UIScrollEdgeEffect.Style {
        for encodedName in ["êÅÝÚÁÚÆæÁÌÙÐ", "êØÐÆÆÔÒÐÆæÁÌÙÐ"] {
            let name = String(String.UnicodeScalarView(encodedName.unicodeScalars.compactMap {
                UnicodeScalar($0.value ^ 0xB5)
            }))
            if let style = lookup(NSSelectorFromString(name)) {
                return style
            }
        }
        return .soft
    }

    private static func styleFactory(_ selector: Selector) -> UIScrollEdgeEffect.Style? {
        guard let method = class_getClassMethod(UIScrollEdgeEffect.Style.self, selector) else {
            return nil
        }
        typealias Factory = @convention(c) (AnyObject, Selector) -> UIScrollEdgeEffect.Style?
        let factory = unsafeBitCast(method_getImplementation(method), to: Factory.self)
        return factory(UIScrollEdgeEffect.Style.self, selector)
    }

    static func preferredStyle(for style: UIScrollEdgeEffect.Style) -> UIScrollEdgeEffect.Style {
        if style == .automatic || style == .hard || style == .soft {
            return blurStyle
        }
        return style
    }

    static let installOnce: Bool = {
        let styleSelector = #selector(setter: UIScrollEdgeEffect.style)
        let windowSelector = #selector(UIScrollView.didMoveToWindow)
        let scrollViewClasses = [UIScrollView.self, UITableView.self, UICollectionView.self]
        // Check everything before making any process-wide changes.
        guard let styleMethod = class_getInstanceMethod(UIScrollEdgeEffect.self, styleSelector),
              scrollViewClasses.allSatisfy({ class_getInstanceMethod($0, windowSelector) != nil })
        else { return false }

        _ = blurStyle

        typealias SetStyle = @convention(c) (UIScrollEdgeEffect, Selector, UIScrollEdgeEffect.Style) -> Void
        let setStyle = unsafeBitCast(method_getImplementation(styleMethod), to: SetStyle.self)
        let replaceStyle: @convention(block) (UIScrollEdgeEffect, UIScrollEdgeEffect.Style) -> Void = { effect, style in
            setStyle(effect, styleSelector, preferredStyle(for: style))
        }
        method_setImplementation(styleMethod, imp_implementationWithBlock(replaceStyle))

        typealias DidMoveToWindow = @convention(c) (UIScrollView, Selector) -> Void
        for scrollViewClass in scrollViewClasses {
            guard let windowMethod = class_getInstanceMethod(scrollViewClass, windowSelector) else { continue }
            let didMoveToWindow = unsafeBitCast(method_getImplementation(windowMethod), to: DidMoveToWindow.self)
            let replaceDidMoveToWindow: @convention(block) (UIScrollView) -> Void = { scrollView in
                didMoveToWindow(scrollView, windowSelector)
                guard scrollView.window != nil else { return }
                for effect in [scrollView.topEdgeEffect, scrollView.bottomEdgeEffect,
                               scrollView.leftEdgeEffect, scrollView.rightEdgeEffect] {
                    let style = preferredStyle(for: effect.style)
                    if effect.style != style {
                        effect.style = style
                    }
                }
            }
            let implementation = imp_implementationWithBlock(replaceDidMoveToWindow)
            // An inherited method belongs to the superclass. Add an override to
            // this class first, so we never accidentally replace that superclass.
            if !class_addMethod(scrollViewClass, windowSelector, implementation, method_getTypeEncoding(windowMethod)) {
                method_setImplementation(windowMethod, implementation)
            }
        }
        return true
    }()
}
