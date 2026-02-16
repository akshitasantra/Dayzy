import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTableIfNeeded()
    }

    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask,
                 appropriateFor: nil, create: true)
            .appendingPathComponent("activities.sqlite3")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Unable to open database")
        }
    }

    private func createTableIfNeeded() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            start_time REAL NOT NULL,
            end_time REAL,
            duration_minutes INTEGER
        );
        """
        execute(sql: createTableString)
        
        let createClipsTable = """
        CREATE TABLE IF NOT EXISTS video_clips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activity_id INTEGER NOT NULL,
            asset_id TEXT NOT NULL,
            created_at REAL NOT NULL,
            clip_order INTEGER,
            FOREIGN KEY(activity_id) REFERENCES activities(id)
        );
        """
        execute(sql: createClipsTable)
    }

    // MARK: Raw SQL Execution Helpers

    @discardableResult
    func execute(sql: String) -> Bool {
        var errMsg: UnsafeMutablePointer<Int8>? = nil
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let error = errMsg {
                print("SQL error: \(String(cString: error))")
            }
            return false
        }
        return true
    }

    func query(sql: String) -> [[String: Any]] {
        var result: [[String: Any]] = []

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            print("Error preparing statement")
            return result
        }

        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(stmt)
            for i in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(stmt, i))
                switch sqlite3_column_type(stmt, i) {
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int(stmt, i))
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(stmt, i))
                case SQLITE_NULL:
                    row[name] = nil
                default:
                    row[name] = String(cString: sqlite3_column_text(stmt, i))
                }
            }
            result.append(row)
        }

        sqlite3_finalize(stmt)
        return result
    }
    
    // MARK: - Helper to get today's start and end
    private func todayInterval() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    // MARK: - Fetch today's activities with split logic
    func fetchTodayActivities() -> [Activity] {
        let (todayStart, todayEnd) = todayInterval()

        let sql = """
        SELECT id, title, start_time, end_time
        FROM activities
        WHERE (start_time < \(todayEnd.timeIntervalSince1970) AND
               (end_time IS NULL OR end_time > \(todayStart.timeIntervalSince1970)))
        ORDER BY start_time;
        """

        let rows = query(sql: sql)
        var activities: [Activity] = []

        for row in rows {
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let startRaw = row["start_time"] as? Double
            else { continue }

            let activityStart = Date(timeIntervalSince1970: startRaw)
            let activityEnd = (row["end_time"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()

            let sliceStart = max(activityStart, todayStart)
            let sliceEnd = min(activityEnd, todayEnd)
            let duration = Int(sliceEnd.timeIntervalSince(sliceStart) / 60)

            if duration > 0 {
                activities.append(Activity(
                    id: id,
                    title: title,
                    startTime: sliceStart,
                    endTime: sliceEnd,
                    durationMinutes: duration
                ))
            }
        }

        return activities
    }

    // MARK: - CRUD

    func createActivity(title: String, start: Date, end: Date?, duration: Int?) {
        let startTime = start.timeIntervalSince1970
        let endTimeString: String
        if let endTime = end?.timeIntervalSince1970 {
            endTimeString = "\(endTime)"
        } else {
            endTimeString = "NULL"
        }
        let durationString = duration != nil ? "\(duration!)" : "NULL"
        // Escape single quotes in title to avoid SQL errors
        let escapedTitle = title.replacingOccurrences(of: "'", with: "''")

        let sql = """
        INSERT INTO activities (title, start_time, end_time, duration_minutes)
        VALUES ('\(escapedTitle)', \(startTime), \(endTimeString), \(durationString));
        """
        execute(sql: sql)
    }
    
    func readActivity(id: Int) -> Activity? {
        let sql = """
        SELECT id, title, start_time, end_time, duration_minutes
        FROM activities
        WHERE id = \(id)
        LIMIT 1;
        """
        let rows = query(sql: sql)
        guard let row = rows.first,
              let id = row["id"] as? Int,
              let title = row["title"] as? String,
              let startRaw = row["start_time"] as? Double
        else { return nil }

        let start = Date(timeIntervalSince1970: startRaw)
        let end = (row["end_time"] as? Double).map { Date(timeIntervalSince1970: $0) }
        let duration = row["duration_minutes"] as? Int

        return Activity(
            id: id,
            title: title,
            startTime: start,
            endTime: end,
            durationMinutes: duration
        )
    }

    func updateActivity(
        id: Int,
        newTitle: String? = nil,
        newStart: Date? = nil,
        newEnd: Date? = nil,
        newDuration: Int? = nil
    )
    {
        var updates: [String] = []
        if let newTitle {
            let escapedTitle = newTitle.replacingOccurrences(of: "'", with: "''")
            updates.append("title = '\(escapedTitle)'")
        }
        if let newStart {
            updates.append("start_time = \(newStart.timeIntervalSince1970)")
        }
        if let newEnd {
            updates.append("end_time = \(newEnd.timeIntervalSince1970)")
        }
        if let newDuration {
            updates.append("duration_minutes = \(newDuration)")
        }
        guard !updates.isEmpty else { return }
        let updateString = updates.joined(separator: ", ")
        let sql = "UPDATE activities SET \(updateString) WHERE id = \(id);"
        execute(sql: sql)
    }
    
    func deleteActivity(id: Int) {
        let sql = "DELETE FROM activities WHERE id = \(id);"
        execute(sql: sql)
    }
    
    // MARK: Video Clips CRUD
    func addVideoClip(activityId: Int, assetId: String) {
        let timestamp = Date().timeIntervalSince1970

        let orderSql = """
        SELECT COUNT(*) as count
        FROM video_clips
        WHERE activity_id = \(activityId);
        """
        let orderRows = query(sql: orderSql)
        let order = (orderRows.first?["count"] as? Int ?? 0) + 1

        let sql = """
        INSERT INTO video_clips (activity_id, asset_id, created_at, clip_order)
        VALUES (\(activityId), '\(assetId)', \(timestamp), \(order));
        """
        execute(sql: sql)
    }

    func fetchClips(for activityId: Int) -> [VideoClip] {
        let sql = """
        SELECT * FROM video_clips
        WHERE activity_id = \(activityId)
        ORDER BY clip_order ASC;
        """
        let rows = query(sql: sql)

        return rows.compactMap { row in
            guard
                let id = row["id"] as? Int,
                let assetId = row["asset_id"] as? String,
                let createdAt = row["created_at"] as? Double,
                let order = row["clip_order"] as? Int
            else { return nil }

            return VideoClip(
                id: id,
                activityId: activityId,
                assetId: assetId,
                createdAt: Date(timeIntervalSince1970: createdAt),
                order: order
            )
        }
    }


    // MARK: Example Queries

    // MARK: - Total time today
    func totalTimeToday() -> Int {
        let activities = fetchTodayActivities()
        return activities.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }

    // MARK: - Most time consuming activities today
    func mostTimeConsumingActivitiesToday(limit: Int = 5) -> [(Activity, Int)] {
        let activities = fetchTodayActivities()
        
        // Sum durations per title
        var totals: [String: Int] = [:]
        var firstIds: [String: Int] = [:]

        for activity in activities {
            totals[activity.title, default: 0] += activity.durationMinutes ?? 0
            if firstIds[activity.title] == nil {
                firstIds[activity.title] = activity.id
            }
        }

        let sorted = totals.sorted { $0.value > $1.value }
            .prefix(limit)

        return sorted.compactMap { title, total in
            guard let id = firstIds[title], let activity = readActivity(id: id) else { return nil }
            return (activity, total)
        }
    }

    func topQuickStartActivities(limit: Int = 4) -> [String] {
        let sql = """
        SELECT
            title,
            COUNT(*) AS usage_count,
            MAX(start_time) AS last_used
        FROM activities
        GROUP BY title
        ORDER BY usage_count DESC, last_used DESC
        LIMIT \(limit);
        """
        
        let rows = query(sql: sql)
        
        return rows.compactMap { $0["title"] as? String }
    }

}

extension DatabaseManager {
    // Fetch the currently running activity (end_time = NULL)
    func fetchCurrentActivity() -> Activity? {
        let sql = """
        SELECT id, title, start_time, end_time, duration_minutes
        FROM activities
        WHERE end_time IS NULL
        LIMIT 1;
        """
        guard let row = query(sql: sql).first,
              let id = row["id"] as? Int,
              let title = row["title"] as? String,
              let startRaw = row["start_time"] as? Double
        else { return nil }

        let start = Date(timeIntervalSince1970: startRaw)
        return Activity(id: id, title: title, startTime: start, endTime: nil, durationMinutes: nil)
    }

    // Start a new activity and persist it immediately
    func startActivity(title: String) -> Activity {
        let start = Date()
        let sql = """
        INSERT INTO activities (title, start_time, end_time, duration_minutes)
        VALUES ('\(title.replacingOccurrences(of: "'", with: "''"))', \(start.timeIntervalSince1970), NULL, NULL);
        """
        execute(sql: sql)

        // Fetch the inserted activity
        let id = Int(sqlite3_last_insert_rowid(db))
        return Activity(id: id, title: title, startTime: start, endTime: nil, durationMinutes: nil)
    }

    // End an ongoing activity
    func endActivity(_ activity: Activity) {
        let end = Date()
        let duration = Int(end.timeIntervalSince(activity.startTime) / 60)
        updateActivity(id: activity.id, newEnd: end, newDuration: duration)
    }
    
    func stats(for scope: WrappedScope, offset: Int) -> (total: Int, activities: [(Activity, Int)], title: String) {
            let calendar = Calendar.current
            let now = Date()

            let interval: DateInterval
            let title: String

            switch scope {
            case .week:
                let start = calendar.date(byAdding: .weekOfYear, value: offset, to: calendar.startOfDay(for: now))!
                interval = calendar.dateInterval(of: .weekOfYear, for: start)!
                title = "Week of \(formatted(interval.start))"

            case .month:
                let start = calendar.date(byAdding: .month, value: offset, to: now)!
                interval = calendar.dateInterval(of: .month, for: start)!
                title = monthFormatter.string(from: interval.start)

            case .year:
                let start = calendar.date(byAdding: .year, value: offset, to: now)!
                interval = calendar.dateInterval(of: .year, for: start)!
                title = yearFormatter.string(from: interval.start)
            }

            let activities = fetchActivities(from: interval.start, to: interval.end)
            let total = activities.reduce(0) { $0 + ($1.durationMinutes ?? 0) }

            var totals: [String: Int] = [:]
            var first: [String: Activity] = [:]

            for a in activities {
                totals[a.title, default: 0] += a.durationMinutes ?? 0
                if first[a.title] == nil { first[a.title] = a }
            }

            let ranked: [(Activity, Int)] = totals.sorted { $0.value > $1.value }
                .compactMap { (title, total) -> (Activity, Int)? in
                    guard let activity = first[title] else { return nil }
                    return (activity, total)
                }


            return (total, ranked, title)
        }

        private func fetchActivities(from start: Date, to end: Date) -> [Activity] {
            let sql = """
            SELECT id, title, start_time, end_time
            FROM activities
            WHERE start_time < \(end.timeIntervalSince1970)
              AND (end_time IS NULL OR end_time > \(start.timeIntervalSince1970));
            """

            return query(sql: sql).compactMap { row in
                guard
                    let id = row["id"] as? Int,
                    let title = row["title"] as? String,
                    let startRaw = row["start_time"] as? Double
                else { return nil }

                let s = max(Date(timeIntervalSince1970: startRaw), start)
                let e = min(
                    (row["end_time"] as? Double).map(Date.init(timeIntervalSince1970:)) ?? Date(),
                    end
                )

                let duration = Int(e.timeIntervalSince(s) / 60)
                guard duration > 0 else { return nil }

                return Activity(id: id, title: title, startTime: s, endTime: e, durationMinutes: duration)
            }
        }

        private func formatted(_ date: Date) -> String {
            let f = DateFormatter()
            f.dateStyle = .medium
            return f.string(from: date)
        }

        private var monthFormatter: DateFormatter {
            let f = DateFormatter()
            f.dateFormat = "LLLL yyyy"
            return f
        }

        private var yearFormatter: DateFormatter {
            let f = DateFormatter()
            f.dateFormat = "yyyy"
            return f
        }
}


extension Date {
    func formattedDateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}

