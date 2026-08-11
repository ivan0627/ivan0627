package com.lockout.app.unlock

import android.content.Context
import android.content.SharedPreferences
import java.util.Calendar

/**
 * Single source of truth for blocking state, shared by the UI, the
 * AccessibilityService and the gym session service.
 */
object UnlockManager {
    private const val PREFS = "lockout_state"
    private const val KEY_UNLOCK_UNTIL = "unlockUntil"
    private const val KEY_GOAL_MINUTES = "goalMinutes"
    private const val KEY_PROGRESS_MINUTES = "progressMinutes"
    private const val KEY_REWARD_HOURS = "rewardHours" // 0 = rest of day
    private const val KEY_BLOCKED_PACKAGES = "blockedPackages"
    private const val MIN_GOAL = 15

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // --- Blocked apps -----------------------------------------------------

    fun blockedPackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()

    fun setBlockedPackages(context: Context, packages: Set<String>) =
        prefs(context).edit().putStringSet(KEY_BLOCKED_PACKAGES, packages).apply()

    // --- Goal & progress --------------------------------------------------

    fun goalMinutes(context: Context): Int =
        maxOf(MIN_GOAL, prefs(context).getInt(KEY_GOAL_MINUTES, 45))

    fun setGoalMinutes(context: Context, minutes: Int) =
        prefs(context).edit().putInt(KEY_GOAL_MINUTES, maxOf(MIN_GOAL, minutes)).apply()

    fun progressMinutes(context: Context): Int =
        prefs(context).getInt(KEY_PROGRESS_MINUTES, 0)

    fun setProgressMinutes(context: Context, minutes: Int) =
        prefs(context).edit().putInt(KEY_PROGRESS_MINUTES, minutes).apply()

    fun remainingMinutes(context: Context): Int =
        maxOf(0, goalMinutes(context) - progressMinutes(context))

    // --- Unlock window ----------------------------------------------------

    fun isUnlocked(context: Context): Boolean =
        prefs(context).getLong(KEY_UNLOCK_UNTIL, 0L) > System.currentTimeMillis()

    fun shouldBlock(context: Context, packageName: String): Boolean =
        !isUnlocked(context) && packageName in blockedPackages(context)

    fun grantUnlock(context: Context) {
        val rewardHours = prefs(context).getInt(KEY_REWARD_HOURS, 0)
        val until = if (rewardHours > 0) {
            System.currentTimeMillis() + rewardHours * 3_600_000L
        } else {
            Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 23); set(Calendar.MINUTE, 59)
            }.timeInMillis
        }
        prefs(context).edit().putLong(KEY_UNLOCK_UNTIL, until).apply()
    }

    /** Called at the daily reset (e.g. from WorkManager in Fase 2). */
    fun resetDay(context: Context) =
        prefs(context).edit()
            .remove(KEY_UNLOCK_UNTIL)
            .putInt(KEY_PROGRESS_MINUTES, 0)
            .apply()
}
