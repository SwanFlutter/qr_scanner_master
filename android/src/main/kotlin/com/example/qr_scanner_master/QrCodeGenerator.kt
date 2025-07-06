package com.example.qr_scanner_master

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.Shader
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import java.util.EnumMap

class QrCodeGenerator {
    
    fun generateQrCode(data: String, options: GenerationOptions): Bitmap? {
        return try {
            val writer = QRCodeWriter()
            val hints = EnumMap<EncodeHintType, Any>(EncodeHintType::class.java)
            
            // Set error correction level
            hints[EncodeHintType.ERROR_CORRECTION] = when (options.errorCorrectionLevel) {
                "LOW" -> ErrorCorrectionLevel.L
                "MEDIUM" -> ErrorCorrectionLevel.M
                "QUARTILE" -> ErrorCorrectionLevel.Q
                "HIGH" -> ErrorCorrectionLevel.H
                else -> ErrorCorrectionLevel.M
            }
            
            hints[EncodeHintType.MARGIN] = options.margin
            
            val bitMatrix = writer.encode(data, BarcodeFormat.QR_CODE, options.size, options.size, hints)
            val width = bitMatrix.width
            val height = bitMatrix.height
            
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            
            // Apply basic colors first
            for (x in 0 until width) {
                for (y in 0 until height) {
                    bitmap.setPixel(
                        x, y, 
                        if (bitMatrix[x, y]) options.foregroundColor else options.backgroundColor
                    )
                }
            }
            
            // Apply advanced styling
            var styledBitmap = bitmap
            
            if (options.gradientColors.isNotEmpty()) {
                styledBitmap = applyGradient(styledBitmap, options)
            }
            
            if (options.roundedCorners) {
                styledBitmap = applyRoundedCorners(styledBitmap, options.cornerRadius)
            }
            
            if (options.logoData != null) {
                styledBitmap = embedLogo(styledBitmap, options.logoData, options.logoSizeRatio)
            }
            
            if (options.addBorder) {
                styledBitmap = addBorder(styledBitmap, options.borderWidth, options.borderColor)
            }
            
            styledBitmap
        } catch (e: Exception) {
            null
        }
    }
    
    private fun applyGradient(bitmap: Bitmap, options: GenerationOptions): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val gradientBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(gradientBitmap)
        
        // Create gradient
        val colors = options.gradientColors.toIntArray()
        val gradient = when {
            options.gradientDirection <= 0.25f -> {
                // Horizontal
                LinearGradient(0f, 0f, width.toFloat(), 0f, colors, null, Shader.TileMode.CLAMP)
            }
            options.gradientDirection <= 0.75f -> {
                // Diagonal
                LinearGradient(0f, 0f, width.toFloat(), height.toFloat(), colors, null, Shader.TileMode.CLAMP)
            }
            else -> {
                // Vertical
                LinearGradient(0f, 0f, 0f, height.toFloat(), colors, null, Shader.TileMode.CLAMP)
            }
        }
        
        val paint = Paint().apply {
            shader = gradient
        }
        
        // Draw original bitmap as mask
        canvas.drawBitmap(bitmap, 0f, 0f, null)
        
        // Apply gradient only to foreground pixels
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        
        return gradientBitmap
    }
    
    private fun applyRoundedCorners(bitmap: Bitmap, cornerRadius: Float): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val roundedBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(roundedBitmap)
        
        val paint = Paint().apply {
            isAntiAlias = true
        }
        
        val rect = RectF(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(rect, cornerRadius, cornerRadius, paint)
        
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        return roundedBitmap
    }
    
    private fun embedLogo(bitmap: Bitmap, logoData: ByteArray, logoSizeRatio: Float): Bitmap {
        return try {
            val logoBitmap = android.graphics.BitmapFactory.decodeByteArray(logoData, 0, logoData.size)
            val width = bitmap.width
            val height = bitmap.height
            val logoSize = (width * logoSizeRatio).toInt()
            
            val scaledLogo = Bitmap.createScaledBitmap(logoBitmap, logoSize, logoSize, true)
            val resultBitmap = bitmap.copy(bitmap.config ?: Bitmap.Config.ARGB_8888, true)
            val canvas = Canvas(resultBitmap)
            
            val logoX = (width - logoSize) / 2f
            val logoY = (height - logoSize) / 2f
            
            // Draw white background for logo
            val backgroundPaint = Paint().apply {
                color = Color.WHITE
                isAntiAlias = true
            }
            val backgroundRadius = logoSize / 2f + 10f
            canvas.drawCircle(
                logoX + logoSize / 2f,
                logoY + logoSize / 2f,
                backgroundRadius,
                backgroundPaint
            )
            
            // Draw logo
            canvas.drawBitmap(scaledLogo, logoX, logoY, null)
            
            resultBitmap
        } catch (e: Exception) {
            bitmap
        }
    }
    
    private fun addBorder(bitmap: Bitmap, borderWidth: Int, borderColor: Int): Bitmap {
        val width = bitmap.width + (borderWidth * 2)
        val height = bitmap.height + (borderWidth * 2)
        val borderedBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(borderedBitmap)
        
        // Fill with border color
        canvas.drawColor(borderColor)
        
        // Draw original bitmap in center
        canvas.drawBitmap(bitmap, borderWidth.toFloat(), borderWidth.toFloat(), null)
        
        return borderedBitmap
    }
}

data class GenerationOptions(
    val size: Int = 512,
    val errorCorrectionLevel: String = "MEDIUM",
    val foregroundColor: Int = Color.BLACK,
    val backgroundColor: Int = Color.WHITE,
    val margin: Int = 20,
    val logoData: ByteArray? = null,
    val logoSizeRatio: Float = 0.2f,
    val roundedCorners: Boolean = false,
    val cornerRadius: Float = 4f,
    val gradientColors: List<Int> = emptyList(),
    val gradientDirection: Float = 0f,
    val addBorder: Boolean = false,
    val borderWidth: Int = 2,
    val borderColor: Int = Color.BLACK
) {
    companion object {
        fun fromMap(map: Map<String, Any>): GenerationOptions {
            return GenerationOptions(
                size = (map["size"] as? Number)?.toInt() ?: 512,
                errorCorrectionLevel = map["errorCorrectionLevel"] as? String ?: "MEDIUM",
                foregroundColor = (map["foregroundColor"] as? Number)?.toInt() ?: Color.BLACK,
                backgroundColor = (map["backgroundColor"] as? Number)?.toInt() ?: Color.WHITE,
                margin = (map["margin"] as? Number)?.toInt() ?: 20,
                logoData = map["logoData"] as? ByteArray,
                logoSizeRatio = (map["logoSizeRatio"] as? Number)?.toFloat() ?: 0.2f,
                roundedCorners = map["roundedCorners"] as? Boolean ?: false,
                cornerRadius = (map["cornerRadius"] as? Number)?.toFloat() ?: 4f,
                gradientColors = (map["gradientColors"] as? List<*>)?.mapNotNull { 
                    (it as? Number)?.toInt() 
                } ?: emptyList(),
                gradientDirection = (map["gradientDirection"] as? Number)?.toFloat() ?: 0f,
                addBorder = map["addBorder"] as? Boolean ?: false,
                borderWidth = (map["borderWidth"] as? Number)?.toInt() ?: 2,
                borderColor = (map["borderColor"] as? Number)?.toInt() ?: Color.BLACK
            )
        }
    }
}
