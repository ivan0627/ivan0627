package com.lockout.app.location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import com.lockout.app.session.GymSessionService

/** Geofence transitions → start/notify the dwell-tracking foreground service. */
class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) return

        val action = when (event.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> GymSessionService.ACTION_ENTER
            Geofence.GEOFENCE_TRANSITION_EXIT -> GymSessionService.ACTION_EXIT
            else -> return
        }
        ContextCompat.startForegroundService(
            context,
            Intent(context, GymSessionService::class.java).setAction(action))
    }
}
