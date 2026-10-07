import Foundation
import UserNotifications

/// Gentle, optional daily reminder. No guilt copy — just an invitation.
enum Reminders {
    static let dailyID = "safeplace.daily.checkin"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleDaily(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])

        let content = UNMutableNotificationContent()
        content.title = "A quiet moment"
        content.body = "What helped you today? Add it to your SafePlace."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyID])
    }

    static func isScheduled() async -> Bool {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.contains { $0.identifier == dailyID }
    }
}
