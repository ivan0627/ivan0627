package com.lockout.app.blocking

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import com.lockout.app.unlock.UnlockManager

/**
 * Detects when a blocked app comes to the foreground and covers it with the
 * blocking overlay. Deliberately minimal: window-state events only, no screen
 * content reading (see accessibility_service_config.xml + Play declaration).
 */
class AppBlockerService : AccessibilityService() {

    private lateinit var overlay: BlockOverlayController

    override fun onServiceConnected() {
        overlay = BlockOverlayController(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName) return

        if (UnlockManager.shouldBlock(this, pkg)) {
            overlay.show(remainingMinutes = UnlockManager.remainingMinutes(this))
        } else {
            overlay.hide()
        }
    }

    override fun onInterrupt() {
        if (::overlay.isInitialized) overlay.hide()
    }
}
