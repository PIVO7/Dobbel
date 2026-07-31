import SwiftUI
import UIKit

/// Aan of uit voor schudden-om-te-gooien, onthouden over sessies heen;
/// instelbaar in het instellingenscherm.
enum ShakeToRoll {
    private static let key = "schudden-aan"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    /// De klassieke schudbeweging van UIKit: betrouwbaar, zonder
    /// bewegingssensor-gedoe. Elk venster meldt hem als notificatie.
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

extension View {
    /// Voert de actie uit wanneer het toestel geschud wordt.
    func onShake(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            action()
        }
    }
}
