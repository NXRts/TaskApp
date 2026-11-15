package com.taskapp.taskapp

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.taskapp.taskapp/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openNotificationSettings") {
                try {
                    val intent = Intent()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                        intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        intent.putExtra("app_package", packageName)
                        intent.putExtra("app_uid", applicationInfo.uid)
                    } else {
                        intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        intent.data = Uri.fromParts("package", packageName, null)
                    }
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    try {
                        val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        fallbackIntent.data = Uri.fromParts("package", packageName, null)
                        fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(fallbackIntent)
                        result.success(true)
                    } catch (e2: Exception) {
                        result.error("ERROR", e2.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
