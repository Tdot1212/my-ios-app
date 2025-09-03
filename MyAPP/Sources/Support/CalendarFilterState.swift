import SwiftUI

struct CalendarFilterState {
    @AppStorage("show_holidayUS") var showHolidayUS = true
    @AppStorage("show_holidayCN") var showHolidayCN = true
    @AppStorage("show_social")    var showSocial    = true
    @AppStorage("show_ecommerce") var showEcomm     = true
    @AppStorage("show_offline")   var showOffline   = true
    @AppStorage("show_task")      var showTask      = true
    @AppStorage("show_reminder")  var showReminder  = true
    @AppStorage("show_personal")  var showPersonal  = true

    mutating func showAll()  { showHolidayUS = true; showHolidayCN = true; showSocial = true; showEcomm = true; showOffline = true; showTask = true; showReminder = true; showPersonal = true }
    mutating func showNone() { showHolidayUS = false; showHolidayCN = false; showSocial = false; showEcomm = false; showOffline = false; showTask = false; showReminder = false; showPersonal = false }

    func includes(_ type: EventType) -> Bool {
        switch type {
        case .holidayUS: return showHolidayUS
        case .holidayCN: return showHolidayCN
        case .social:    return showSocial
        case .ecommerce: return showEcomm
        case .offline:   return showOffline
        case .task:      return showTask
        case .reminder:  return showReminder
        case .personal:  return showPersonal
        }
    }
}
