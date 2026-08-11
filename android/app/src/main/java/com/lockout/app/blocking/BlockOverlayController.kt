package com.lockout.app.blocking

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.lockout.app.R

/**
 * Full-screen blocking view drawn over shielded apps via SYSTEM_ALERT_WINDOW.
 * Plain views (not Compose): this runs inside the AccessibilityService process
 * with no activity context.
 */
class BlockOverlayController(private val context: Context) {

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var view: LinearLayout? = null

    fun show(remainingMinutes: Int) {
        if (view != null) {
            subtitle?.text = context.getString(R.string.shield_subtitle, remainingMinutes)
            return
        }
        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.BLACK)
            setPadding(64, 64, 64, 64)
        }
        layout.addView(TextView(context).apply {
            text = context.getString(R.string.shield_title)
            setTextColor(Color.WHITE)
            textSize = 32f
            gravity = Gravity.CENTER
        })
        layout.addView(TextView(context).apply {
            id = SUBTITLE_ID
            text = context.getString(R.string.shield_subtitle, remainingMinutes)
            setTextColor(Color.LTGRAY)
            textSize = 18f
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 48)
        })
        layout.addView(Button(context).apply {
            text = "I'm on it"
            setOnClickListener {
                hide()
                // Send the user home instead of back into the blocked app.
                context.startActivity(
                    android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
                        addCategory(android.content.Intent.CATEGORY_HOME)
                        flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                    })
            }
        })

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.OPAQUE
        )
        windowManager.addView(layout, params)
        view = layout
    }

    fun hide() {
        view?.let { windowManager.removeView(it) }
        view = null
    }

    private val subtitle: TextView?
        get() = view?.findViewById(SUBTITLE_ID)

    private companion object {
        const val SUBTITLE_ID = 0x10CC0
    }
}
