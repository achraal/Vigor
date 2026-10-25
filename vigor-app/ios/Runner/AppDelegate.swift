import Flutter
import UIKit
import GoogleMaps
import flutter_dotenv

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Récupération sécurisée de la clé depuis le .env si chargé,
    // ou fallback sur une configuration sécurisée
    if let apiKey = DotEnv.env["GOOGLE_MAPS_API_KEY"] {
        GMSServices.provideAPIKey(apiKey)
    } else {
        // Fallback de sécurité si le fichier .env n'est pas lu au démarrage natif
        print("⚠️ Attention: Clé Google Maps introuvable dans l'environnement natif iOS")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}