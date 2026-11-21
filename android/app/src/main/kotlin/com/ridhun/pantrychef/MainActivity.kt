package com.ridhun.pantrychef

import android.content.Intent
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * The native half of the updater (lib/services/updater.dart): tells Dart which version is
 * installed, and opens Android's install screen for a downloaded update once it has checked
 * that the file really is this app at the expected version (a cut-short or mixed-up download
 * would only fail to install).
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pantry_chef/update")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "info" -> {
                            val info = packageManager.getPackageInfo(packageName, 0)
                            result.success(mapOf(
                                "versionCode" to versionCode(info),
                                "versionName" to (info.versionName ?: ""),
                                "cacheDir" to cacheDir.path,
                            ))
                        }
                        "install" -> {
                            val apk = File(call.argument<String>("path")!!)
                            val expected = call.argument<Number>("versionCode")!!.toLong()
                            val archive = packageManager.getPackageArchiveInfo(apk.path, 0)
                            if (archive == null || archive.packageName != packageName || versionCode(archive) != expected) {
                                apk.delete()
                                result.error("bad_apk", "The downloaded update was incomplete. Please try again.", null)
                                return@setMethodCallHandler
                            }
                            val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
                            startActivity(Intent(Intent.ACTION_VIEW)
                                .setDataAndType(uri, "application/vnd.android.package-archive")
                                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("update_failed", e.message ?: e.toString(), null)
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun versionCode(info: android.content.pm.PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
}
