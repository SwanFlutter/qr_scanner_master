package com.example.qr_scanner_master

import android.app.Activity
import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager as AndroidCameraManager
import android.media.MediaPlayer
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraManager(private val activity: Activity) {
    
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var camera: Camera? = null
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var isScanning = false
    private var isPaused = false
    private var currentOptions: ScanOptions? = null
    private var scanCallback: ((ScanResult?) -> Unit)? = null
    private var scannedCodes = mutableSetOf<String>()
    private var scanCount = 0
    
    private val barcodeScanner = BarcodeScanning.getClient()
    private val vibrator = getVibrator()
    private var mediaPlayer: MediaPlayer? = null
    
    fun startScanning(options: ScanOptions, callback: (ScanResult?) -> Unit) {
        currentOptions = options
        scanCallback = callback
        isScanning = true
        isPaused = false
        scannedCodes.clear()
        scanCount = 0
        
        setupCamera(options)
    }
    
    fun pauseScanning() {
        isPaused = true
    }
    
    fun resumeScanning() {
        isPaused = false
    }
    
    fun stopScanning() {
        isScanning = false
        isPaused = false
        scanCallback = null
        currentOptions = null
        scannedCodes.clear()
        scanCount = 0
        
        cameraProvider?.unbindAll()
        mediaPlayer?.release()
        mediaPlayer = null
    }
    
    fun toggleFlash(enable: Boolean) {
        camera?.cameraControl?.enableTorch(enable)
    }
    
    fun getAvailableCameras(): List<String> {
        return try {
            val cameraManager = activity.getSystemService(Context.CAMERA_SERVICE) as AndroidCameraManager
            cameraManager.cameraIdList.toList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    private fun setupCamera(options: ScanOptions) {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(activity)
        
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraUseCases(options)
            } catch (e: Exception) {
                scanCallback?.invoke(null)
            }
        }, ContextCompat.getMainExecutor(activity))
    }
    
    private fun bindCameraUseCases(options: ScanOptions) {
        val cameraProvider = this.cameraProvider ?: return
        
        // Select camera
        val cameraSelector = if (options.cameraFacing == "FRONT") {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }
        
        // Setup image analysis
        imageAnalysis = ImageAnalysis.Builder()
            .setTargetResolution(getResolutionSize(options.cameraResolution))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
        
        imageAnalysis?.setAnalyzer(cameraExecutor) { imageProxy ->
            processImage(imageProxy, options)
        }
        
        try {
            // Unbind use cases before rebinding
            cameraProvider.unbindAll()
            
            // Bind use cases to camera
            camera = cameraProvider.bindToLifecycle(
                activity as LifecycleOwner,
                cameraSelector,
                imageAnalysis
            )
            
            // Setup camera controls
            if (options.autoFocus) {
                camera?.cameraControl?.setLinearZoom(0.0f)
            }
            
            if (options.enableFlash) {
                camera?.cameraControl?.enableTorch(true)
            }
            
        } catch (e: Exception) {
            scanCallback?.invoke(null)
        }
    }
    
    private fun processImage(imageProxy: ImageProxy, options: ScanOptions) {
        if (!isScanning || isPaused) {
            imageProxy.close()
            return
        }
        
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            
            barcodeScanner.process(image)
                .addOnSuccessListener { barcodes ->
                    processBarcodes(barcodes, options)
                }
                .addOnFailureListener {
                    // Handle failure silently and continue scanning
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }
    
    private fun processBarcodes(barcodes: List<Barcode>, options: ScanOptions) {
        if (!isScanning || isPaused) return
        
        for (barcode in barcodes) {
            val formatName = getBarcodeFormatName(barcode.format)
            
            // Check if format is allowed
            if (options.formats.isNotEmpty() && !options.formats.contains(formatName)) {
                continue
            }
            
            val data = barcode.rawValue ?: continue
            
            // Check for duplicates in multi-scan mode
            if (options.multiScan && scannedCodes.contains(data)) {
                continue
            }
            
            // Convert to scan result
            val scanResult = convertToScanResult(barcode)
            
            // Handle scan feedback
            if (options.beepOnScan) {
                playBeepSound()
            }
            
            if (options.vibrateOnScan) {
                vibrate()
            }
            
            if (options.multiScan) {
                scannedCodes.add(data)
                scanCount++
                
                // Check if we've reached max scans
                if (options.maxScans > 0 && scanCount >= options.maxScans) {
                    isScanning = false
                    scanCallback?.invoke(scanResult)
                    return
                }
            } else {
                // Single scan mode - stop after first result
                isScanning = false
                scanCallback?.invoke(scanResult)
                return
            }
        }
    }
    
    private fun getBarcodeFormatName(format: Int): String {
        return when (format) {
            Barcode.FORMAT_QR_CODE -> "QR_CODE"
            Barcode.FORMAT_EAN_8 -> "EAN_8"
            Barcode.FORMAT_EAN_13 -> "EAN_13"
            Barcode.FORMAT_CODE_39 -> "CODE_39"
            Barcode.FORMAT_CODE_93 -> "CODE_93"
            Barcode.FORMAT_CODE_128 -> "CODE_128"
            Barcode.FORMAT_CODABAR -> "CODABAR"
            Barcode.FORMAT_ITF -> "ITF"
            Barcode.FORMAT_UPC_A -> "UPC_A"
            Barcode.FORMAT_UPC_E -> "UPC_E"
            Barcode.FORMAT_DATA_MATRIX -> "DATA_MATRIX"
            Barcode.FORMAT_AZTEC -> "AZTEC"
            Barcode.FORMAT_PDF417 -> "PDF_417"
            else -> "UNKNOWN"
        }
    }
    
    private fun convertToScanResult(barcode: Barcode): ScanResult {
        val cornerPoints = barcode.cornerPoints?.map { point ->
            ScanPoint(point.x.toDouble(), point.y.toDouble())
        } ?: emptyList()
        
        return ScanResult(
            data = barcode.rawValue ?: "",
            format = getBarcodeFormatName(barcode.format),
            timestamp = System.currentTimeMillis(),
            cornerPoints = cornerPoints,
            metadata = emptyMap() // Metadata creation can be added here if needed
        )
    }
    
    private fun getResolutionSize(resolution: String): android.util.Size {
        return when (resolution) {
            "LOW" -> android.util.Size(640, 480)
            "MEDIUM" -> android.util.Size(1280, 720)
            "HIGH" -> android.util.Size(1920, 1080)
            "VERY_HIGH" -> android.util.Size(3840, 2160)
            else -> android.util.Size(1280, 720)
        }
    }
    
    private fun playBeepSound() {
        try {
            if (mediaPlayer == null) {
                mediaPlayer = MediaPlayer.create(activity, android.provider.Settings.System.DEFAULT_NOTIFICATION_URI)
            }
            mediaPlayer?.start()
        } catch (e: Exception) {
            // Ignore sound errors
        }
    }
    
    private fun vibrate() {
        try {
            vibrator?.let { vib ->
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    vib.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    vib.vibrate(100)
                }
            }
        } catch (e: Exception) {
            // Ignore vibration errors
        }
    }
    
    private fun getVibrator(): Vibrator? {
        return try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                val vibratorManager = activity.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                activity.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
        } catch (e: Exception) {
            null
        }
    }
    
    fun cleanup() {
        stopScanning()
        cameraExecutor.shutdown()
        barcodeScanner.close()
    }
}
