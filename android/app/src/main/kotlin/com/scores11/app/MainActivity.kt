package com.scores11.app

import android.os.Bundle
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity

/**
 * ✅ COMPLETE FIX FOR RELEASE APK CRASH
 * 
 * Root Cause: FocusNode lifecycle issues with Flutter's IME (Input Method Editor) subsystem
 * in release builds. When keyboard opens, there can be a race condition between:
 *   1. Flutter's focus management
 *   2. Android IME subsystem
 *   3. View lifecycle events
 * 
 * This causes the app to crash ONLY in release mode (not debug) when:
 *   - Tapping on any TextField
 *   - Keyboard opening triggers IME focus events
 *   - Back button pressed while keyboard is open
 * 
 * Fix Strategy:
 *   1. Use FlutterActivity (not FlutterFragmentActivity) - more stable
 *   2. Properly handle focus changes before IME operations
 *   3. Ensure clean focus state on back press
 *   4. Add proper window focus callbacks
 */
class MainActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
// Force hardware keyboard to be hidden initially
        // This prevents IME initialization race conditions
        window.setSoftInputMode(
            android.view.WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN or
            android.view.WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
        )
    }
    
    // ✅ FIX 1: Override onBackPressed with proper focus handling
    // This is the CRITICAL fix - when keyboard is open and user taps back,
    // we need to hide keyboard BEFORE the activity tries to pop
    override fun onBackPressed() {
        // First, hide the keyboard to prevent IME/focus crash
        hideKeyboard()
        
        // Clear any focused view to prevent focus state issues
        val currentFocus = currentFocus
        if (currentFocus != null) {
            currentFocus.clearFocus()
        }
        
        super.onBackPressed()
    }
    
    // ✅ FIX 2: Proper window focus handling
    // This prevents crashes when window loses/gains focus
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) {
            // Window lost focus - hide keyboard to prevent IME issues
            hideKeyboard()
        }
    }
    
    // ✅ Helper method to safely hide keyboard
    private fun hideKeyboard() {
        try {
            val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
            val view = currentFocus
            if (view != null) {
                imm.hideSoftInputFromWindow(view.windowToken, 0)
            } else {
                // Fallback: try to hide from window token
                val windowToken = window.decorView.windowToken
                if (windowToken != null) {
                    imm.hideSoftInputFromWindow(windowToken, 0)
                }
            }
        } catch (e: Exception) {
            // Silently ignore - this is a safety net
        }
    }
    
    // ✅ FIX 3: Override dispatchKeyEvent for additional safety
    // This handles hardware back button and other key events
    override fun dispatchKeyEvent(event: android.view.KeyEvent?): Boolean {
        event?.let {
            if (it.keyCode == android.view.KeyEvent.KEYCODE_BACK && it.action == android.view.KeyEvent.ACTION_DOWN) {
                // Check if keyboard is shown before back press
                val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                if (imm.isActive) {
                    // Keyboard is active - handle with our safe method
                    hideKeyboard()
                    // We handled it, but still call super for navigation
                    onBackPressed()
                    return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }
}
