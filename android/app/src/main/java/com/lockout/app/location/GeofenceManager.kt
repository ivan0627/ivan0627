package com.lockout.app.location

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import org.json.JSONArray
import org.json.JSONObject

data class Gym(val id: String, val name: String, val lat: Double, val lng: Double,
               val radiusMeters: Float = 100f)

/** Registers the user's gyms as geofences and persists them. */
object GeofenceManager {
    private const val PREFS = "lockout_gyms"
    private const val KEY_GYMS = "gyms"

    fun gyms(context: Context): List<Gym> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_GYMS, "[]") ?: "[]"
        val array = JSONArray(raw)
        return (0 until array.length()).map { i ->
            val o = array.getJSONObject(i)
            Gym(o.getString("id"), o.getString("name"), o.getDouble("lat"),
                o.getDouble("lng"), o.getDouble("radius").toFloat())
        }
    }

    fun addGym(context: Context, gym: Gym) {
        val all = gyms(context) + gym
        val array = JSONArray()
        all.forEach {
            array.put(JSONObject()
                .put("id", it.id).put("name", it.name)
                .put("lat", it.lat).put("lng", it.lng)
                .put("radius", it.radiusMeters.toDouble()))
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_GYMS, array.toString()).apply()
        registerAll(context)
    }

    @SuppressLint("MissingPermission") // caller ensures fine + background location
    fun registerAll(context: Context) {
        val gyms = gyms(context)
        if (gyms.isEmpty()) return
        val geofences = gyms.map {
            Geofence.Builder()
                .setRequestId(it.id)
                .setCircularRegion(it.lat, it.lng, it.radiusMeters)
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(
                    Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
                .build()
        }
        val request = GeofencingRequest.Builder()
            // INITIAL_TRIGGER_ENTER covers "already at the gym when registering".
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofences(geofences)
            .build()
        LocationServices.getGeofencingClient(context)
            .addGeofences(request, pendingIntent(context))
    }

    private fun pendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context, 0,
            Intent(context, GeofenceBroadcastReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
}
