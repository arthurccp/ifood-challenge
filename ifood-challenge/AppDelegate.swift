//
//  AppDelegate.swift
//  ifood-challenge
//
//  Created by Arthur Silva on 14/10/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    // Conclui a inicialização do app sem configuração adicional.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    // Fornece a configuração padrão para a nova sessão de cena.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: AppStrings.Identifier.sceneConfiguration, sessionRole: connectingSceneSession.role)
    }

    // Recebe o descarte de sessões; atualmente não executa ações adicionais.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

