//
//  NotificationViewController.swift
//  PitStopNotification
//
//  Created by Liren Zhang on 7/10/2026.
//

import UIKit
import SwiftUI
import UserNotifications
import UserNotificationsUI

/// Custom UI for PitStop maintenance notifications.
///
/// When a scheduled inspection comes up, the notification shows the
/// component name, its reading standard, and a short recommendation.
/// This view replaces the default iOS notification appearance for the
/// `PITSTOP_MAINTENANCE_DUE` category.
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private var hostingController: UIHostingController<NotificationContentView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content

        let componentName = content.userInfo["component_name"] as? String ?? "Component"
        let standard = content.userInfo["standard"] as? String ?? ""
        let recommendation = content.userInfo["recommendation"] as? String ?? ""
        let serviceLevelRaw = content.userInfo["service_level"] as? String
        let serviceLevel = serviceLevelRaw.flatMap(ServiceLevel.init(rawValue:))

        let model = NotificationContentModel(
            componentName: componentName,
            standard: standard,
            recommendation: recommendation,
            serviceLevel: serviceLevel
        )

        let host = UIHostingController(
            rootView: NotificationContentView(model: model)
        )
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)

        preferredContentSize = CGSize(width: 0, height: 180)
    }
}
