package com.lockout.app

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.google.android.gms.location.LocationServices
import com.lockout.app.location.GeofenceManager
import com.lockout.app.location.Gym
import com.lockout.app.unlock.UnlockManager
import java.util.UUID

/**
 * Spike UI: permission checklist → pick blocked apps → register gym → goal.
 * Production onboarding replaces this, but every core interaction is here.
 */
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MaterialTheme { SpikeScreen() } }
    }

    @OptIn(ExperimentalMaterial3Api::class)
    @Composable
    fun SpikeScreen() {
        var blocked by remember { mutableStateOf(UnlockManager.blockedPackages(this)) }
        var goal by remember { mutableStateOf(UnlockManager.goalMinutes(this).toFloat()) }
        var gyms by remember { mutableStateOf(GeofenceManager.gyms(this)) }

        val locationPermissions = rememberLauncherForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()) { }

        Scaffold(topBar = { TopAppBar(title = { Text("Lockout") }) }) { padding ->
            LazyColumn(
                modifier = Modifier.padding(padding).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Text("Setup", style = MaterialTheme.typography.titleMedium)
                    Button(onClick = {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    }) { Text("1. Enable Lockout blocker (Accessibility)") }
                    Button(onClick = {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")))
                    }) { Text("2. Allow display over other apps") }
                    Button(onClick = {
                        locationPermissions.launch(arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.POST_NOTIFICATIONS))
                    }) { Text("3. Grant location + notifications") }
                    Button(onClick = {
                        locationPermissions.launch(
                            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION))
                    }) { Text("4. Allow location \"all the time\"") }
                }

                item {
                    Divider()
                    Text("Status", style = MaterialTheme.typography.titleMedium)
                    val unlocked = UnlockManager.isUnlocked(this@MainActivity)
                    Text(if (unlocked) "🔓 Unlocked — enjoy, you earned it"
                         else "🔒 ${UnlockManager.remainingMinutes(this@MainActivity)} min of gym to go")
                }

                item {
                    Divider()
                    Text("Daily goal: ${goal.toInt()} min",
                        style = MaterialTheme.typography.titleMedium)
                    Slider(value = goal, valueRange = 15f..120f, steps = 20,
                        onValueChange = { goal = it },
                        onValueChangeFinished = {
                            UnlockManager.setGoalMinutes(this@MainActivity, goal.toInt())
                        })
                }

                item {
                    Divider()
                    Text("My gyms (${gyms.size})", style = MaterialTheme.typography.titleMedium)
                    gyms.forEach { Text("📍 ${it.name}") }
                    Button(onClick = {
                        addCurrentLocationAsGym { gyms = GeofenceManager.gyms(this@MainActivity) }
                    }) { Text("Add current location as my gym") }
                }

                item {
                    Divider()
                    Text("Blocked apps (${blocked.size})",
                        style = MaterialTheme.typography.titleMedium)
                }
                items(installedApps()) { app ->
                    Row(modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(app.second, modifier = Modifier.weight(1f))
                        Switch(checked = app.first in blocked, onCheckedChange = { on ->
                            blocked = if (on) blocked + app.first else blocked - app.first
                            UnlockManager.setBlockedPackages(this@MainActivity, blocked)
                        })
                    }
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun addCurrentLocationAsGym(onDone: () -> Unit) {
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED) return
        LocationServices.getFusedLocationProviderClient(this)
            .lastLocation.addOnSuccessListener { location ->
                location ?: return@addOnSuccessListener
                GeofenceManager.addGym(this, Gym(
                    id = UUID.randomUUID().toString(),
                    name = "My gym #${GeofenceManager.gyms(this).size + 1}",
                    lat = location.latitude, lng = location.longitude))
                onDone()
            }
    }

    /** Launchable apps only, alphabetical — good enough for the spike. */
    private fun installedApps(): List<Pair<String, String>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return packageManager.queryIntentActivities(intent, 0)
            .map { it.activityInfo.packageName to
                   it.loadLabel(packageManager).toString() }
            .distinctBy { it.first }
            .filterNot { it.first == packageName }
            .sortedBy { it.second.lowercase() }
    }
}
