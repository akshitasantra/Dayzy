// DatabaseManager.swift
import Foundation
import AVFoundation
import SQLite3
import Photos
import UIKit

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTableIfNeeded()
        ensureVideoClipsColumns()
        createAssetIdIndexIfNeeded()
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

        // Create video_clips table with metadata columns included (for new installs).
        // For upgrades we'll add missing columns later.
        let createClipsTable = """
        CREATE TABLE IF NOT EXISTS video_clips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activity_id INTEGER NOT NULL,
            asset_id TEXT NOT NULL,
            created_at REAL NOT NULL,
            clip_order INTEGER,
            suggested_text TEXT,
            font_name TEXT,
            font_scale REAL,
            position_x REAL,
            position_y REAL,
            color_hex TEXT,
            trimmed_start REAL,
            trimmed_duration REAL,
            FOREIGN KEY(activity_id) REFERENCES activities(id)
        );
        """
        execute(sql: createClipsTable)
    }

    // Ensure index on asset_id for easier lookup / updates
    private func createAssetIdIndexIfNeeded() {
        let sql = "CREATE UNIQUE INDEX IF NOT EXISTS idx_video_clips_asset_id ON video_clips(asset_id);"
        _ = execute(sql: sql)
    }

    // Check PRAGMA table_info and add columns that might be missing for older installs
    private func ensureVideoClipsColumns() {
        let requiredColumns: [(String, String)] = [
            ("suggested_text", "TEXT"),
            ("font_name", "TEXT"),
            ("font_scale", "REAL"),
            ("position_x", "REAL"),
            ("position_y", "REAL"),
            ("color_hex", "TEXT"),
            ("trimmed_start", "REAL"),
            ("trimmed_duration", "REAL")
        ]

        let existing = query(sql: "PRAGMA table_info(video_clips);")
        var existingNames = Set<String>()
        for row in existing {
            if let name = row["name"] as? String {
                existingNames.insert(name)
            }
        }

        for (name, type) in requiredColumns {
            if !existingNames.contains(name) {
                let alter = "ALTER TABLE video_clips ADD COLUMN \(name) \(type);"
                _ = execute(sql: alter)
            }
        }
    }

    // MARK: Raw SQL Execution Helpers

    @discardableResult
    func execute(sql: String) -> Bool {
        var errMsg: UnsafeMutablePointer<Int8>? = nil
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let error = errMsg {
                print("SQL error: \(String(cString: error))")
                sqlite3_free(errMsg)
            }
            return false
        }
        return true
    }

    func query(sql: String) -> [[String: Any]] {
        var result: [[String: Any]] = []

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            print("Error preparing statement:", sql)
            return result
        }

        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(stmt)
            for i in 0..<columnCount {
                guard let cName = sqlite3_column_name(stmt, i) else { continue }
                let name = String(cString: cName)
                switch sqlite3_column_type(stmt, i) {
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int(stmt, i))
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    if let cText = sqlite3_column_text(stmt, i) {
                        row[name] = String(cString: cText)
                    } else {
                        row[name] = ""
                    }
                case SQLITE_NULL:
                    row[name] = nil
                default:
                    if let cText = sqlite3_column_text(stmt, i) {
                        row[name] = String(cString: cText)
                    }
                }
            }
            result.append(row)
        }

        sqlite3_finalize(stmt)
        return result
    }

    // Convenient prepared execute for updates/inserts with bindings
    @discardableResult
    private func executePrepared(sql: String, bind: (OpaquePointer?) -> Void) -> Bool {
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            if let err = sqlite3_errmsg(db) {
                print("prepare error: \(String(cString: err)) SQL: \(sql)")
            }
            sqlite3_finalize(stmt)
            return false
        }

        bind(stmt)

        if sqlite3_step(stmt) != SQLITE_DONE {
            if let err = sqlite3_errmsg(db) {
                print("step error: \(String(cString: err)) SQL: \(sql)")
            }
            sqlite3_finalize(stmt)
            return false
        }

        sqlite3_finalize(stmt)
        return true
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

            activities.append(Activity(
                id: id,
                title: title,
                startTime: sliceStart,
                endTime: sliceEnd,
                durationMinutes: max(duration, 0)
            ))
        }

        return activities
    }

    // MARK: - CRUD (activities)

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
    
    func endActivity(_ activity: Activity) {
        let endTime = Date()
        let durationMinutes = Int(endTime.timeIntervalSince(activity.startTime) / 60)

        let sql = """
        UPDATE activities
        SET end_time = \(endTime.timeIntervalSince1970),
            duration_minutes = \(durationMinutes)
        WHERE id = \(activity.id);
        """

        execute(sql: sql)
    }


    // MARK: Video Clips CRUD (with metadata)

    /// Insert a video clip (older API) — keeps compatibility
    func addVideoClip(activityId: Int, assetId: String) {
        addVideoClip(activityId: activityId, assetId: assetId, metadata: nil)
    }

    /// Insert a video clip and optionally persist metadata at creation
    func addVideoClip(activityId: Int, assetId: String, metadata: ClipMetadata?) {
        let timestamp = Date().timeIntervalSince1970

        let orderSql = """
        SELECT COUNT(*) as count
        FROM video_clips
        WHERE activity_id = \(activityId);
        """
        let orderRows = query(sql: orderSql)
        let order = (orderRows.first?["count"] as? Int ?? 0) + 1

        let sql = """
        INSERT INTO video_clips (
            activity_id, asset_id, created_at, clip_order,
            suggested_text, font_name, font_scale,
            position_x, position_y, color_hex,
            trimmed_start, trimmed_duration
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        _ = executePrepared(sql: sql) { stmt in
            // bind params
            sqlite3_bind_int(stmt, 1, Int32(activityId))
            sqlite3_bind_text(stmt, 2, (assetId as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, timestamp)
            sqlite3_bind_int(stmt, 4, Int32(order))

            if let m = metadata {
                sqlite3_bind_text(stmt, 5, (m.suggestedText as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 6, (m.fontName as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 7, Double(m.fontScale))
                sqlite3_bind_double(stmt, 8, Double(m.position.x))
                sqlite3_bind_double(stmt, 9, Double(m.position.y))
                sqlite3_bind_text(stmt, 10, (m.colorHex as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 11, CMTimeGetSeconds(m.trimmedStart))
                sqlite3_bind_double(stmt, 12, CMTimeGetSeconds(m.trimmedDuration))
            } else {
                // bind nulls for the rest
                for idx in 5...12 {
                    sqlite3_bind_null(stmt, Int32(idx))
                }
            }
        }
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

    // MARK: - ClipMetadata persistence

    /// Update an existing video_clips row identified by asset_id with ClipMetadata
    func saveClipMetadata(forAssetId assetId: String, metadata: ClipMetadata) {
        let sql = """
        UPDATE video_clips SET
            suggested_text = ?,
            font_name = ?,
            font_scale = ?,
            position_x = ?,
            position_y = ?,
            color_hex = ?,
            trimmed_start = ?,
            trimmed_duration = ?
        WHERE asset_id = ?;
        """

        _ = executePrepared(sql: sql) { stmt in
            sqlite3_bind_text(stmt, 1, (metadata.suggestedText as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (metadata.fontName as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, Double(metadata.fontScale))
            sqlite3_bind_double(stmt, 4, Double(metadata.position.x))
            sqlite3_bind_double(stmt, 5, Double(metadata.position.y))
            sqlite3_bind_text(stmt, 6, (metadata.colorHex as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 7, CMTimeGetSeconds(metadata.trimmedStart))
            sqlite3_bind_double(stmt, 8, CMTimeGetSeconds(metadata.trimmedDuration))
            sqlite3_bind_text(stmt, 9, (assetId as NSString).utf8String, -1, nil)
        }
    }

    /// Load ClipMetadata for a given asset_id if present
    func loadClipMetadata(forAssetId assetId: String) -> ClipMetadata? {
        let sql = """
        SELECT suggested_text, font_name, font_scale,
               position_x, position_y, color_hex,
               trimmed_start, trimmed_duration
        FROM video_clips
        WHERE asset_id = ?
        LIMIT 1;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            sqlite3_finalize(stmt)
            return nil
        }

        sqlite3_bind_text(stmt, 1, (assetId as NSString).utf8String, -1, nil)

        var result: ClipMetadata? = nil
        if sqlite3_step(stmt) == SQLITE_ROW {
            // read columns, handling NULLs
            func textOrEmpty(_ idx: Int32) -> String {
                if let c = sqlite3_column_text(stmt, idx) {
                    return String(cString: c)
                }
                return ""
            }

            let suggestedText = (sqlite3_column_type(stmt, 0) == SQLITE_NULL) ? "" : textOrEmpty(0)
            let fontName = (sqlite3_column_type(stmt, 1) == SQLITE_NULL) ? "HelveticaNeue-Bold" : textOrEmpty(1)
            let fontScale = sqlite3_column_type(stmt, 2) == SQLITE_NULL ? 1.0 : sqlite3_column_double(stmt, 2)
            let posX = sqlite3_column_type(stmt, 3) == SQLITE_NULL ? 0.5 : sqlite3_column_double(stmt, 3)
            let posY = sqlite3_column_type(stmt, 4) == SQLITE_NULL ? 0.5 : sqlite3_column_double(stmt, 4)
            let colorHex = (sqlite3_column_type(stmt, 5) == SQLITE_NULL) ? "#FFFFFF" : textOrEmpty(5)
            let trimmedStart = sqlite3_column_type(stmt, 6) == SQLITE_NULL ? 0.0 : sqlite3_column_double(stmt, 6)
            let trimmedDuration = sqlite3_column_type(stmt, 7) == SQLITE_NULL ? 0.0 : sqlite3_column_double(stmt, 7)

            result = ClipMetadata(
                assetId: assetId,
                suggestedText: suggestedText,
                fontName: fontName,
                fontScale: CGFloat(fontScale),
                position: CGPoint(x: CGFloat(posX), y: CGFloat(posY)),
                colorHex: colorHex,
                trimmedStart: CMTime(seconds: trimmedStart, preferredTimescale: 600),
                trimmedDuration: CMTime(seconds: trimmedDuration, preferredTimescale: 600)
            )
        }

        sqlite3_finalize(stmt)
        return result
    }

    // MARK: Example Queries (unchanged)
    func totalTimeToday() -> Int {
        let activities = fetchTodayActivities()
        return activities.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }

    func mostTimeConsumingActivitiesToday(limit: Int = 5) -> [(Activity, Int)] {
        let activities = fetchTodayActivities()

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
    
    func stats(for scope: WrappedScope, offset: Int) -> StatsResult {
        let calendar = Calendar.current
        let now = Date()

        let (start, end, title): (Date, Date, String)

        switch scope {
        case .week:
            let startOfWeek = calendar.date(from:
                calendar.dateComponents([.yearForWeekOfYear, .weekOfYear],
                                        from: calendar.date(byAdding: .weekOfYear, value: -offset, to: now)!)
            )!
            start = startOfWeek
            end = calendar.date(byAdding: .day, value: 7, to: start)!
            title = offset == 0 ? "This Week" : "\(offset) Weeks Ago"

        case .month:
            let base = calendar.date(byAdding: .month, value: -offset, to: now)!
            start = calendar.date(from: calendar.dateComponents([.year, .month], from: base))!
            end = calendar.date(byAdding: .month, value: 1, to: start)!
            title = offset == 0 ? "This Month" : "\(offset) Months Ago"

        case .year:
            let base = calendar.date(byAdding: .year, value: -offset, to: now)!
            start = calendar.date(from: calendar.dateComponents([.year], from: base))!
            end = calendar.date(byAdding: .year, value: 1, to: start)!
            title = offset == 0 ? "This Year" : "\(offset) Years Ago"
        }

        let sql = """
        SELECT id, title, start_time, end_time, duration_minutes
        FROM activities
        WHERE start_time < \(end.timeIntervalSince1970)
          AND (end_time IS NULL OR end_time > \(start.timeIntervalSince1970));
        """

        let rows = query(sql: sql)

        var totalsByTitle: [String: Int] = [:]
        var firstActivity: [String: Activity] = [:]
        var totalMinutes = 0

        for row in rows {
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let startRaw = row["start_time"] as? Double
            else { continue }

            let startTime = Date(timeIntervalSince1970: startRaw)
            let endTime = (row["end_time"] as? Double)
                .map { Date(timeIntervalSince1970: $0) } ?? end

            let clippedStart = max(startTime, start)
            let clippedEnd = min(endTime, end)

            let minutes = max(0, Int(clippedEnd.timeIntervalSince(clippedStart) / 60))
            guard minutes > 0 else { continue }

            totalMinutes += minutes
            totalsByTitle[title, default: 0] += minutes

            if firstActivity[title] == nil {
                firstActivity[title] = Activity(
                    id: id,
                    title: title,
                    startTime: clippedStart,
                    endTime: clippedEnd,
                    durationMinutes: minutes
                )
            }
        }

        let activities = totalsByTitle
            .sorted { $0.value > $1.value }
            .compactMap { title, minutes in
                firstActivity[title].map { ($0, minutes) }
            }

        return StatsResult(
            title: title,
            total: totalMinutes,
            activities: activities
        )
    }

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
    // Find activity by title + approx start time (within tolerance) or create it.
        func getOrCreateActivity(title: String, startApprox: Date, toleranceSeconds: TimeInterval = 120) -> Activity {
            let ts = startApprox.timeIntervalSince1970
            // Use ABS(start_time - ts) < toleranceSeconds
            let sql = """
            SELECT id, title, start_time, end_time, duration_minutes
            FROM activities
            WHERE title = '\(title.replacingOccurrences(of: "'", with: "''"))'
              AND ABS(start_time - \(ts)) < \(toleranceSeconds)
            LIMIT 1;
            """
            if let row = query(sql: sql).first,
               let id = row["id"] as? Int,
               let title = row["title"] as? String,
               let startRaw = row["start_time"] as? Double
            {
                let start = Date(timeIntervalSince1970: startRaw)
                let end = (row["end_time"] as? Double).map { Date(timeIntervalSince1970: $0) }
                let duration = row["duration_minutes"] as? Int
                return Activity(id: id, title: title, startTime: start, endTime: end, durationMinutes: duration)
            }

            // not found -> create
            let activity = startActivity(title: title)
            // override start time to the approximate exact one (so times align)
            updateActivity(id: activity.id, newStart: startApprox)
            return readActivity(id: activity.id) ?? activity
        }

        // Upsert (insert if missing) a video_clips row for this assetId and associate with activityId.
        func upsertVideoClip(assetId: String, activityId: Int, metadata: ClipMetadata) {
            // Check if row exists
            let checkSql = "SELECT id FROM video_clips WHERE asset_id = '\(assetId.replacingOccurrences(of: "'", with: "''"))' LIMIT 1;"
            if let row = query(sql: checkSql).first, let _ = row["id"] as? Int {
                // Update existing row (also ensure activity_id is set)
                let sql = """
                UPDATE video_clips SET
                    activity_id = ?,
                    suggested_text = ?,
                    font_name = ?,
                    font_scale = ?,
                    position_x = ?,
                    position_y = ?,
                    color_hex = ?,
                    trimmed_start = ?,
                    trimmed_duration = ?
                WHERE asset_id = ?;
                """
                _ = executePrepared(sql: sql) { stmt in
                    sqlite3_bind_int(stmt, 1, Int32(activityId))
                    sqlite3_bind_text(stmt, 2, (metadata.suggestedText as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(stmt, 3, (metadata.fontName as NSString).utf8String, -1, nil)
                    sqlite3_bind_double(stmt, 4, Double(metadata.fontScale))
                    sqlite3_bind_double(stmt, 5, Double(metadata.position.x))
                    sqlite3_bind_double(stmt, 6, Double(metadata.position.y))
                    sqlite3_bind_text(stmt, 7, (metadata.colorHex as NSString).utf8String, -1, nil)
                    sqlite3_bind_double(stmt, 8, CMTimeGetSeconds(metadata.trimmedStart))
                    sqlite3_bind_double(stmt, 9, CMTimeGetSeconds(metadata.trimmedDuration))
                    sqlite3_bind_text(stmt, 10, (assetId as NSString).utf8String, -1, nil)
                }
            } else {
                // Insert a new video_clips row (preserve clip_order logic inside addVideoClip)
                addVideoClip(activityId: activityId, assetId: assetId, metadata: metadata)
            }
        }

        // Convenience method to save metadata, associate it with an activity (create activity if needed)
        func saveClipMetadataAndAssociate(assetId: String, metadata: ClipMetadata, activityTitle: String, activityStartApprox: Date) {
            let activity = getOrCreateActivity(title: activityTitle, startApprox: activityStartApprox)
            upsertVideoClip(assetId: assetId, activityId: activity.id, metadata: metadata)
        }

        // Fetch ClipMetadata rows for *today* ordered by activity.start_time then clip_order
        func fetchClipsForToday() -> [ClipMetadata] {
            let (todayStart, todayEnd) = todayInterval()
            let sql = """
            SELECT vc.asset_id,
                   vc.suggested_text,
                   vc.font_name,
                   vc.font_scale,
                   vc.position_x,
                   vc.position_y,
                   vc.color_hex,
                   vc.trimmed_start,
                   vc.trimmed_duration
            FROM video_clips vc
            JOIN activities a ON a.id = vc.activity_id
            WHERE a.start_time < \(todayEnd.timeIntervalSince1970)
              AND (a.end_time IS NULL OR a.end_time > \(todayStart.timeIntervalSince1970))
            ORDER BY a.start_time ASC, vc.clip_order ASC;
            """

            let rows = query(sql: sql)
            return rows.compactMap { row -> ClipMetadata? in
                guard let assetId = row["asset_id"] as? String else { return nil }
                let suggestedText = row["suggested_text"] as? String ?? ""
                let fontName = row["font_name"] as? String ?? "HelveticaNeue-Bold"
                let fontScale = CGFloat((row["font_scale"] as? Double) ?? 1.0)
                let posX = CGFloat((row["position_x"] as? Double) ?? 0.5)
                let posY = CGFloat((row["position_y"] as? Double) ?? 0.5)
                let colorHex = row["color_hex"] as? String ?? "#FFFFFF"
                let trimmedStartSec = (row["trimmed_start"] as? Double) ?? 0.0
                let trimmedDurSec = (row["trimmed_duration"] as? Double) ?? 0.0

                return ClipMetadata(
                    assetId: assetId,
                    suggestedText: suggestedText,
                    fontName: fontName,
                    fontScale: fontScale,
                    position: CGPoint(x: posX, y: posY),
                    colorHex: colorHex,
                    trimmedStart: CMTime(seconds: trimmedStartSec, preferredTimescale: 600),
                    trimmedDuration: CMTime(seconds: trimmedDurSec, preferredTimescale: 600)
                )
            }
        }
    
    // MARK: - Fetch activities for an arbitrary day (past or present)
    func fetchActivities(for date: Date) -> [Activity] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let sql = """
        SELECT id, title, start_time, end_time
        FROM activities
        WHERE start_time < \(dayEnd.timeIntervalSince1970)
          AND (end_time IS NULL OR end_time > \(dayStart.timeIntervalSince1970))
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
            let activityEnd = (row["end_time"] as? Double)
                .map { Date(timeIntervalSince1970: $0) } ?? dayEnd

            // ✂️ Clip activity to this day
            let clippedStart = max(activityStart, dayStart)
            let clippedEnd = min(activityEnd, dayEnd)

            let durationMinutes = Int(clippedEnd.timeIntervalSince(clippedStart) / 60)
            guard durationMinutes > 0 else { continue }

            activities.append(
                Activity(
                    id: id,
                    title: title,
                    startTime: clippedStart,
                    endTime: clippedEnd,
                    durationMinutes: durationMinutes
                )
            )
        }

        return activities
    }

}


