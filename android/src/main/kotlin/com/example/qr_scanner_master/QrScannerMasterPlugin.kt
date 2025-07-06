package com.example.qr_scanner_master

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream

/** QrScannerMasterPlugin */
class QrScannerMasterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

  private lateinit var channel: MethodChannel
  private var context: Context? = null
  private var activity: Activity? = null
  private var qrCodeGenerator: QrCodeGenerator? = null
  private var barcodeScanner: BarcodeScanner? = null
  private var cameraManager: CameraManager? = null
  private var permissionManager: PermissionManager? = null

  private var pendingResult: Result? = null
  private val CAMERA_PERMISSION_REQUEST_CODE = 1001

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "qr_scanner_master")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext

    // Initialize components
    qrCodeGenerator = QrCodeGenerator()
    barcodeScanner = BarcodeScanner(context!!)
    permissionManager = PermissionManager()
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${Build.VERSION.RELEASE}")
      }
      "scanWithCamera" -> {
        handleScanWithCamera(call, result)
      }
      "scanFromImage" -> {
        handleScanFromImage(call, result)
      }
      "scanFromBytes" -> {
        handleScanFromBytes(call, result)
      }
      "generateQrCode" -> {
        handleGenerateQrCode(call, result)
      }
      "hasCameraPermission" -> {
        result.success(hasCameraPermission())
      }
      "requestCameraPermission" -> {
        handleRequestCameraPermission(result)
      }
      "getAvailableCameras" -> {
        handleGetAvailableCameras(result)
      }
      "hasFlash" -> {
        result.success(hasFlash())
      }
      "toggleFlash" -> {
        handleToggleFlash(call, result)
      }
      "getSupportedFormats" -> {
        result.success(getSupportedFormats())
      }
      "pauseScanner" -> {
        handlePauseScanner(result)
      }
      "resumeScanner" -> {
        handleResumeScanner(result)
      }
      "stopScanner" -> {
        handleStopScanner(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun handleScanWithCamera(call: MethodCall, result: Result) {
    if (!hasCameraPermission()) {
      result.error("PERMISSION_DENIED", "Camera permission is required", null)
      return
    }

    try {
      val options = parseScanOptions(call.arguments as? Map<String, Any>)
      cameraManager?.startScanning(options) { scanResult ->
        if (scanResult != null) {
          result.success(scanResult.toMap())
        } else {
          result.success(null)
        }
      }
    } catch (e: Exception) {
      result.error("CAMERA_ERROR", "Failed to start camera scanning: ${e.message}", null)
    }
  }

  private fun handleScanFromImage(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val imagePath = arguments["imagePath"] as String
      val options = parseScanOptions(arguments)

      barcodeScanner?.scanFromImagePath(imagePath, options) { results ->
        result.success(results.map { it.toMap() })
      }
    } catch (e: Exception) {
      result.error("SCAN_ERROR", "Failed to scan from image: ${e.message}", null)
    }
  }

  private fun handleScanFromBytes(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val imageBytes = arguments["imageBytes"] as ByteArray
      val options = parseScanOptions(arguments)

      barcodeScanner?.scanFromBytes(imageBytes, options) { results ->
        result.success(results.map { it.toMap() })
      }
    } catch (e: Exception) {
      result.error("SCAN_ERROR", "Failed to scan from bytes: ${e.message}", null)
    }
  }

  private fun handleGenerateQrCode(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val data = arguments["data"] as String
      val options = parseGenerationOptions(arguments)

      val qrBitmap = qrCodeGenerator?.generateQrCode(data, options)
      if (qrBitmap != null) {
        val outputStream = ByteArrayOutputStream()
        qrBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        result.success(outputStream.toByteArray())
      } else {
        result.error("GENERATION_FAILED", "Failed to generate QR code", null)
      }
    } catch (e: Exception) {
      result.error("GENERATION_FAILED", "QR code generation failed: ${e.message}", null)
    }
  }

  private fun handleRequestCameraPermission(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    if (hasCameraPermission()) {
      result.success(true)
      return
    }

    pendingResult = result
    ActivityCompat.requestPermissions(
      activity!!,
      arrayOf(Manifest.permission.CAMERA),
      CAMERA_PERMISSION_REQUEST_CODE
    )
  }

  private fun handleGetAvailableCameras(result: Result) {
    try {
      val cameras = cameraManager?.getAvailableCameras() ?: emptyList()
      result.success(cameras)
    } catch (e: Exception) {
      result.error("CAMERA_ERROR", "Failed to get available cameras: ${e.message}", null)
    }
  }

  private fun handleToggleFlash(call: MethodCall, result: Result) {
    try {
      val enable = call.argument<Boolean>("enable") ?: false
      cameraManager?.toggleFlash(enable)
      result.success(null)
    } catch (e: Exception) {
      result.error("FLASH_ERROR", "Failed to toggle flash: ${e.message}", null)
    }
  }

  private fun handlePauseScanner(result: Result) {
    try {
      cameraManager?.pauseScanning()
      result.success(null)
    } catch (e: Exception) {
      result.error("SCANNER_ERROR", "Failed to pause scanner: ${e.message}", null)
    }
  }

  private fun handleResumeScanner(result: Result) {
    try {
      cameraManager?.resumeScanning()
      result.success(null)
    } catch (e: Exception) {
      result.error("SCANNER_ERROR", "Failed to resume scanner: ${e.message}", null)
    }
  }

  private fun handleStopScanner(result: Result) {
    try {
      cameraManager?.stopScanning()
      result.success(null)
    } catch (e: Exception) {
      result.error("SCANNER_ERROR", "Failed to stop scanner: ${e.message}", null)
    }
  }

  private fun hasCameraPermission(): Boolean {
    return context?.let {
      ContextCompat.checkSelfPermission(it, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    } ?: false
  }

  private fun hasFlash(): Boolean {
    return context?.packageManager?.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH) ?: false
  }

  private fun getSupportedFormats(): List<String> {
    return listOf(
      "QR_CODE", "EAN_8", "EAN_13", "CODE_39", "CODE_93", "CODE_128",
      "CODABAR", "ITF", "RSS_14", "RSS_EXPANDED", "UPC_A", "UPC_E",
      "DATA_MATRIX", "AZTEC", "PDF_417"
    )
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
      val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
      pendingResult?.success(granted)
      pendingResult = null
      return true
    }
    return false
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    cameraManager = CameraManager(activity!!)
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
    cameraManager = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    cameraManager = CameraManager(activity!!)
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
    cameraManager = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
    qrCodeGenerator = null
    barcodeScanner = null
    cameraManager = null
    permissionManager = null
  }

  // Helper methods will be implemented in separate files
  private fun parseScanOptions(arguments: Map<String, Any>?): ScanOptions {
    return ScanOptions.fromMap(arguments ?: emptyMap())
  }

  private fun parseGenerationOptions(arguments: Map<String, Any>): GenerationOptions {
    return GenerationOptions.fromMap(arguments)
  }
}
