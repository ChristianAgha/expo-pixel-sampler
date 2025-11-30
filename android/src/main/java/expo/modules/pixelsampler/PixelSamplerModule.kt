package expo.modules.pixelsampler

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File
import java.net.URL

class PixelSamplerModule : Module() {
    // Cache for loaded bitmaps to avoid reloading on every sample
    private val bitmapCache = mutableMapOf<String, Bitmap>()
    private val maxCacheSize = 5

    override fun definition() = ModuleDefinition {
        Name("PixelSampler")

        // Synchronous function for instant pixel sampling
        Function("getPixelColor") { imageUri: String, x: Double, y: Double, displayWidth: Double, displayHeight: Double ->
            getPixelColorSync(imageUri, x, y, displayWidth, displayHeight)
        }

        // Async version for compatibility
        AsyncFunction("getPixelColorAsync") { imageUri: String, x: Double, y: Double, displayWidth: Double, displayHeight: Double ->
            getPixelColorSync(imageUri, x, y, displayWidth, displayHeight)
        }
    }

    private fun getPixelColorSync(
        imageUri: String,
        x: Double,
        y: Double,
        displayWidth: Double,
        displayHeight: Double
    ): String {
        try {
            // Try to get cached bitmap first
            var bitmap = bitmapCache[imageUri]

            // Load bitmap if not cached
            if (bitmap == null) {
                bitmap = loadBitmap(imageUri)
                if (bitmap != null) {
                    // Limit cache size
                    if (bitmapCache.size >= maxCacheSize) {
                        // Remove oldest entry
                        bitmapCache.keys.firstOrNull()?.let { bitmapCache.remove(it) }
                    }
                    bitmapCache[imageUri] = bitmap
                }
            }

            if (bitmap == null) {
                return "#808080" // Gray fallback
            }

            // Convert display coordinates to image coordinates
            val imageWidth = bitmap.width.toDouble()
            val imageHeight = bitmap.height.toDouble()

            val scaleX = imageWidth / displayWidth
            val scaleY = imageHeight / displayHeight

            val imageX = (x * scaleX).toInt().coerceIn(0, bitmap.width - 1)
            val imageY = (y * scaleY).toInt().coerceIn(0, bitmap.height - 1)

            // Get pixel color
            val pixel = bitmap.getPixel(imageX, imageY)

            // Convert to hex string
            val red = Color.red(pixel)
            val green = Color.green(pixel)
            val blue = Color.blue(pixel)

            return String.format("#%02X%02X%02X", red, green, blue)
        } catch (e: Exception) {
            e.printStackTrace()
            return "#808080" // Gray fallback
        }
    }

    private fun loadBitmap(uri: String): Bitmap? {
        return try {
            when {
                // Handle file:// URIs
                uri.startsWith("file://") -> {
                    val path = uri.removePrefix("file://")
                    BitmapFactory.decodeFile(path)
                }
                // Handle content:// URIs
                uri.startsWith("content://") -> {
                    val context = appContext.reactContext ?: return null
                    val inputStream = context.contentResolver.openInputStream(Uri.parse(uri))
                    BitmapFactory.decodeStream(inputStream)
                }
                // Handle http/https URLs
                uri.startsWith("http://") || uri.startsWith("https://") -> {
                    val connection = URL(uri).openConnection()
                    connection.connect()
                    BitmapFactory.decodeStream(connection.getInputStream())
                }
                // Try as direct file path
                else -> {
                    val file = File(uri)
                    if (file.exists()) {
                        BitmapFactory.decodeFile(uri)
                    } else {
                        null
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

