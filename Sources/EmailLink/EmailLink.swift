import SwiftUI

typealias ActionSheetButton = ActionSheet.Button

public struct EmailLink<Content: View>: View {
    @State private var showAlert = false
    @State private var availableClients = [EmailClient]()

    private let label: Content
    private let clients: [EmailClient]

    public init(to: String, subject: String = "", body: String = "", color: UIColor = .systemBlue, @ViewBuilder label: () -> Content) {
        // Set properties
        self.label = label()
        self.clients =  EmailClient.allClients(to: to, subject: subject, body: body)

        // Force color for ActionSheet
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = color
    }

    public var body: some View {
        Button(action: {
            availableClients = getAvailableClients()

            if availableClients.count > 2 {
                showAlert = true
            } else {
                if let url = availableClients.first?.url {
                    UIApplication.shared.open(url)
                }
            }
        }) {
            label
        }
        .actionSheet(isPresented: $showAlert) {
            ActionSheet(
                title: Text("Multiple Apps Found"),
                message: Text("Which app do you want to use to send this email?"),
                buttons: actionSheetButtons()
            )
        }.onAppear() {
            // Ensure Info.plist includes required keys before loading view.
            self.checkInfoDictionary()
        }
    }

    private func actionSheetButtons() -> [ActionSheetButton] {
        var buttons = [ActionSheetButton]()

        for client in availableClients {
            buttons.append(.default(Text(client.name), action: { UIApplication.shared.open(client.url) }))
        }

        buttons.append(.cancel())

        return buttons
    }

    private func getAvailableClients() -> [EmailClient] {
        var availableClients = [EmailClient]()

        for client in clients {
            if UIApplication.shared.canOpenURL(client.url) {
                availableClients.append(client)
            }
        }

        return availableClients
    }

    private func checkInfoDictionary() {
        if let schemes = Bundle.main.infoDictionary?["LSApplicationQueriesSchemes"] as? Array<String> {
            // Bundle exists, check values
            for requiredScheme in URLSchemes.requiredSchemes() {
                if !schemes.contains(requiredScheme) {
                    fatalError("Your Info.plist is missing \"\(requiredScheme)\" for \"LSApplicationQueriesSchemes\".")
                }
            }
        } else {
            // Check individual schemes
            fatalError("Your Info.plist is missing \"LSApplicationQueriesSchemes\".")
        }
    }
}
