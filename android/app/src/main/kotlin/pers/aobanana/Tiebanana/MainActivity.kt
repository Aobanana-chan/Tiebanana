package pers.aobanana.Tiebanana

import android.content.Context
import android.content.Intent
import android.content.ActivityNotFoundException
import android.net.Uri
import android.media.AudioManager
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channels for features not provided by any plugin:
 * - tiebanana/webview_cookies: raw cookie strings from the system WebView
 *   cookie store (used to save BDUSS/STOKEN credentials after web login).
 * - tiebanana/player_utils: system volume and screen brightness, both
 *   normalized to 0..1 (replicates discontinued fijkplayer features).
 */
class MainActivity : FlutterActivity() {
    private val audioManager by lazy {
        getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tiebanana/official_tieba")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val uri = call.argument<String>("url")?.let(Uri::parse)
                if (uri == null || uri.scheme != "com.baidu.tieba" ||
                    uri.host != "unidispatch" || uri.path !in listOf("/pb", "/frs")) {
                    result.error("badargs", "invalid official Tieba URL", null)
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, uri).apply {
                        setPackage("com.baidu.tieba")
                        addCategory(Intent.CATEGORY_BROWSABLE)
                    })
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.success(false)
                } catch (_: SecurityException) {
                    result.success(false)
                }
            }
        //读取系统WebView cookie库的原始cookie串(与webview_flutter的WebView共享同一个cookie库,
        //能读到HttpOnly的凭证如BDUSS/STOKEN),供网页登录完成后保存登录凭证使用。
        //不走webview_flutter的WebViewCookieManager.getCookies(),因为它的cookie值解析会把
        //值中含"="的cookie截断(cookieValue = cookie.split('=');取first/last), 导致Cookie被毁(baidu的cookie中会包含'=')
        //见webview_flutter_android-4.14.1/lib/src/android_webview_cookie_manager.dart getCookies()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tiebanana/webview_cookies")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCookies" -> {
                        val url = call.argument<String>("url") ?: run {
                            result.error("badargs", "missing url", null)
                            return@setMethodCallHandler
                        }
                        result.success(android.webkit.CookieManager.getInstance().getCookie(url))
                    }
                    "clearCookies" -> {
                        //添加账号前清空 cookie，避免 passport 直接把当前账号当成已登录。
                        val manager = android.webkit.CookieManager.getInstance()
                        manager.removeAllCookies {
                            manager.flush()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tiebanana/player_utils")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSystemVolume" -> {
                        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val cur = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                        result.success(if (max == 0) 0.0 else cur.toDouble() / max.toDouble())
                    }
                    "setSystemVolume" -> {
                        val value = call.argument<Double>("value") ?: run {
                            result.error("badargs", "missing value", null)
                            return@setMethodCallHandler
                        }
                        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val vol = (value * max).toInt().coerceIn(0, max)
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, vol, 0)
                        result.success(null)
                    }
                    "getBrightness" -> {
                        @Suppress("DEPRECATION")
                        result.success(window.attributes.screenBrightness.toDouble())
                    }
                    "setBrightness" -> {
                        val value = call.argument<Double>("value") ?: run {
                            result.error("badargs", "missing value", null)
                            return@setMethodCallHandler
                        }
                        val params = window.attributes
                        params.screenBrightness = value.toFloat().coerceIn(0f, 1f)
                        window.attributes = params
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
