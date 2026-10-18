import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // There is no Main.storyboard and no scene list in Info.plist,
    // so we tell UIKit in code which class manages each window.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
