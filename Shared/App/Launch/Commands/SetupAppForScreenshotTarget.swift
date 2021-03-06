//
//  SetupAppForScreenshotTarget.swift
//  Remind (iOS)
//
//  Created by Titouan Van Belle on 26.01.21.
//

import Foundation
import Combine

final class SetupAppForScreenshotTarget: LaunchCommand {

    private let database: CoreDatabaseProtocol = CoreDatabase()
    private var cancellables = Set<AnyCancellable>()

    var shouldExecuteOnlyOnce: Bool {
        true
    }

    let reminders = [
        ReminderData(
            title: "seed.1.title".localized,
            date: .today,
            time: Date(hour: 09, minute: 00)
        ),
        ReminderData(
            title: "seed.2.title".localized,
            date: .today,
            time: Date(hour: 10, minute: 00)
        ),
        ReminderData(
            title: "seed.3.title".localized,
            date: .today,
            time: Date(hour: 17, minute: 00)
        ),
        ReminderData(
            title: "seed.4.title".localized,
            date: .today,
            time: Date(hour: 18, minute: 30)
        )
    ]

    override func execute() {
        super.execute()
        
        prepareDatabase()
        resetOnboarding()
    }
}

fileprivate extension SetupAppForScreenshotTarget {
    func resetOnboarding() {
        UserDefaults.standard.setValue(true, forKey: "needsOnboarding")
    }

    func prepareDatabase() {
        deleteAllReminder()
            .flatMap { _ in
                self.seedData()
            }
            .flatMap { _ in
                self.database.save()
            }
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result, ((error as? CoreDatabase) != nil) {
                        print("❗️Error: \(error.localizedDescription)")
                    } else {
                        print("🛠 Seeded \(self.reminders.count) reminders into database")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    func deleteAllReminder() -> AnyPublisher<Void, Error> {
        database.deleteAllReminder()
            .eraseToAnyPublisher()
    }

    func seedData() -> AnyPublisher<[Reminder], Error> {
        reminders.publisher
            .flatMap {
                self.database.createReminder(data: $0, savesAutomatically: false)
            }
            .collect()
            .eraseToAnyPublisher()
    }
}
