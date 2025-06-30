import Foundation

enum CoreWoundID: String, Codable, CaseIterable, Hashable {
    case IM_NOT_GOOD_ENOUGH        = "IM_NOT_GOOD_ENOUGH"
    case SOMETHING_IS_WRONG_WITH_ME = "SOMETHING_IS_WRONG_WITH_ME"
    case PEOPLE_ALWAYS_LEAVE_ME    = "PEOPLE_ALWAYS_LEAVE_ME"
    case I_CANT_TRUST_ANYONE       = "I_CANT_TRUST_ANYONE"
    case I_HAVE_NO_CONTROL         = "I_HAVE_NO_CONTROL"
}