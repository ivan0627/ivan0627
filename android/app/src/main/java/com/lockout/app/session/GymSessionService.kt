package com.lockout.app.session

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.lockout.app.R
import com.lockout.app.unlock.UnlockManager

/**
 * Foreground service that runs only while a gym session is live.
 * Counts dwell minutes; exits shorter than GRACE_MS (bathroom, phone call,
 * GPS jitter) don't end the session.
 */
class GymSessionService : Service() {

    companion object {
        const val ACTION_ENTER = "com.lockout.app.GEOFENCE_ENTER"
        const val ACTION_EXIT = "com.lockout.app.GEOFENCE_EXIT"
        private const val GRACE_MS = 5 * 60_000L
        private const val TICK_MS = 60_000L
        private const val CHANNEL_ID = "gym_session"
        private const val NOTIFICATION_ID = 1
    }

    private val handler = Handler(Looper.getMainLooper())
    private var enteredAt = 0L
    private var bankedMs = 0L
    private var inside = false
    private var goalGrantedToday = false

    private val ticker = object : Runnable {
        override fun run() {
            updateProgress()
            handler.postDelayed(this, TICK_MS)
        }
    }
    private val graceStop = Runnable { stopSession() }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())
        when (intent?.action) {
            ACTION_ENTER -> {
                handler.removeCallbacks(graceStop)
                if (!inside) {
                    inside = true
                    enteredAt = System.currentTimeMillis()
                    handler.post(ticker)
                }
            }
            ACTION_EXIT -> {
                if (inside) {
                    inside = false
                    bankedMs += System.currentTimeMillis() - enteredAt
                    handler.postDelayed(graceStop, GRACE_MS)
                }
            }
        }
        return START_STICKY
    }

    private fun accumulatedMinutes(): Int {
        var ms = bankedMs
        if (inside) ms += System.currentTimeMillis() - enteredAt
        return (ms / 60_000L).toInt()
    }

    private fun updateProgress() {
        val minutes = accumulatedMinutes()
        UnlockManager.setProgressMinutes(this, minutes)
        val goal = UnlockManager.goalMinutes(this)
        if (!goalGrantedToday && minutes >= goal) {
            goalGrantedToday = true
            // TODO(anti-cheat v1): in "proof mode", cross-check Health Connect
            // heart rate / exercise session over this window before granting.
            UnlockManager.grantUnlock(this)
        }
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun stopSession() {
        handler.removeCallbacks(ticker)
        updateProgress()
        bankedMs = 0
        goalGrantedToday = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification(): Notification {
        notificationManager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, getString(R.string.session_notification_title),
                NotificationManager.IMPORTANCE_LOW))
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle(getString(R.string.session_notification_title))
            .setContentText(getString(R.string.session_notification_text,
                accumulatedMinutes(), UnlockManager.goalMinutes(this)))
            .setOngoing(true)
            .build()
    }

    private val notificationManager: NotificationManager
        get() = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    override fun onBind(intent: Intent?): IBinder? = null
}
