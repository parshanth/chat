package com.example.church_attendance

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.church_attendance/dialer",
        ).setMethodCallHandler { call, result ->
            if (call.method != "openDialer") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val phone = call.argument<String>("phone")
            if (phone == null || !Regex("\\+?[0-9]{3,15}").matches(phone)) {
                result.error("INVALID_PHONE", "A valid phone number is required.", null)
                return@setMethodCallHandler
            }

            val intent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.fromParts("tel", phone, null)
            }

            try {
                startActivity(intent)
                result.success(true)
            } catch (_: ActivityNotFoundException) {
                result.success(false)
            } catch (error: Exception) {
                result.error("DIALER_LAUNCH_FAILED", error.message, null)
            }
        }
    }
}
