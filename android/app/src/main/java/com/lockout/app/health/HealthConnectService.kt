package com.lockout.app.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.temporal.ChronoUnit

/**
 * Health Connect integration: verifies workouts (tennis, hiking, basketball…)
 * recorded by any connected watch/band. External activities ALWAYS require this
 * — location alone never validates them (PLAN.md §3.5).
 */
class HealthConnectService(private val context: Context) {

    val permissions = setOf(
        HealthPermission.getReadPermission(ExerciseSessionRecord::class),
        HealthPermission.getReadPermission(HeartRateRecord::class),
    )

    fun isAvailable(): Boolean =
        HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE

    private val client: HealthConnectClient
        get() = HealthConnectClient.getOrCreate(context)

    /**
     * Sessions that qualify for an unlock today: minimum duration and ended
     * recently (< 3 h — no recycling this morning's workout at midnight).
     */
    suspend fun todaysQualifyingSessions(minMinutes: Int): List<ExerciseSessionRecord> {
        val startOfDay = Instant.now().truncatedTo(ChronoUnit.DAYS)
        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = ExerciseSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(startOfDay, Instant.now())))
        return response.records.filter { session ->
            val minutes = ChronoUnit.MINUTES.between(session.startTime, session.endTime)
            minutes >= minMinutes &&
                ChronoUnit.HOURS.between(session.endTime, Instant.now()) < 3
        }
    }

    /** Proof-mode check: sustained effort during a gym session window. */
    suspend fun hadElevatedHeartRate(from: Instant, to: Instant,
                                     minAvgBpm: Long = 95): Boolean {
        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = HeartRateRecord::class,
                timeRangeFilter = TimeRangeFilter.between(from, to)))
        val samples = response.records.flatMap { it.samples }
        if (samples.isEmpty()) return false
        return samples.map { it.beatsPerMinute }.average() >= minAvgBpm
    }
}
