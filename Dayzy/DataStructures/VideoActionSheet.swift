enum VideoActionSheet: Identifiable {
    case record
    case upload

    var id: Int { hashValue }
}
