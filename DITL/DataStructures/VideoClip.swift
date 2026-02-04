import Foundation

struct VideoClip: Identifiable {
    let id: Int
    let activityId: Int
    let assetId: String   // Photos localIdentifier
    let createdAt: Date
    let order: Int
}
