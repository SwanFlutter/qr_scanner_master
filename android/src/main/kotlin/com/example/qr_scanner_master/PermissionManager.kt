package com.example.qr_scanner_master

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class PermissionManager {
    
    companion object {
        const val CAMERA_PERMISSION_REQUEST_CODE = 1001
        const val STORAGE_PERMISSION_REQUEST_CODE = 1002
        const val VIBRATE_PERMISSION_REQUEST_CODE = 1003
        
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.CAMERA
        )
        
        private val STORAGE_PERMISSIONS = arrayOf(
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        )
        
        private val VIBRATE_PERMISSIONS = arrayOf(
            Manifest.permission.VIBRATE
        )
    }
    
    fun hasCameraPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    fun hasStoragePermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    fun hasVibratePermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.VIBRATE
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    fun hasAllRequiredPermissions(context: Context): Boolean {
        return REQUIRED_PERMISSIONS.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    fun requestCameraPermission(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST_CODE
        )
    }
    
    fun requestStoragePermission(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            STORAGE_PERMISSIONS,
            STORAGE_PERMISSION_REQUEST_CODE
        )
    }
    
    fun requestVibratePermission(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            VIBRATE_PERMISSIONS,
            VIBRATE_PERMISSION_REQUEST_CODE
        )
    }
    
    fun requestAllPermissions(activity: Activity) {
        val permissionsToRequest = mutableListOf<String>()
        
        // Check camera permission
        if (!hasCameraPermission(activity)) {
            permissionsToRequest.add(Manifest.permission.CAMERA)
        }
        
        // Check storage permissions
        if (!hasStoragePermission(activity)) {
            permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            if (android.os.Build.VERSION.SDK_INT <= android.os.Build.VERSION_CODES.P) {
                permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        }
        
        // Check vibrate permission
        if (!hasVibratePermission(activity)) {
            permissionsToRequest.add(Manifest.permission.VIBRATE)
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                activity,
                permissionsToRequest.toTypedArray(),
                CAMERA_PERMISSION_REQUEST_CODE
            )
        }
    }
    
    fun shouldShowRequestPermissionRationale(activity: Activity, permission: String): Boolean {
        return ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
    }
    
    fun handlePermissionResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): PermissionResult {
        return when (requestCode) {
            CAMERA_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() && 
                             grantResults[0] == PackageManager.PERMISSION_GRANTED
                PermissionResult(PermissionType.CAMERA, granted)
            }
            STORAGE_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() && 
                             grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                PermissionResult(PermissionType.STORAGE, granted)
            }
            VIBRATE_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() && 
                             grantResults[0] == PackageManager.PERMISSION_GRANTED
                PermissionResult(PermissionType.VIBRATE, granted)
            }
            else -> PermissionResult(PermissionType.UNKNOWN, false)
        }
    }
    
    fun getPermissionStatus(context: Context): PermissionStatus {
        return PermissionStatus(
            camera = hasCameraPermission(context),
            storage = hasStoragePermission(context),
            vibrate = hasVibratePermission(context)
        )
    }
    
    fun getMissingPermissions(context: Context): List<String> {
        val missing = mutableListOf<String>()
        
        if (!hasCameraPermission(context)) {
            missing.add(Manifest.permission.CAMERA)
        }
        
        if (!hasStoragePermission(context)) {
            missing.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            if (android.os.Build.VERSION.SDK_INT <= android.os.Build.VERSION_CODES.P) {
                missing.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        }
        
        if (!hasVibratePermission(context)) {
            missing.add(Manifest.permission.VIBRATE)
        }
        
        return missing
    }
    
    fun getPermissionExplanation(permission: String): String {
        return when (permission) {
            Manifest.permission.CAMERA -> 
                "Camera permission is required to scan QR codes and barcodes using the device camera."
            Manifest.permission.READ_EXTERNAL_STORAGE -> 
                "Storage permission is required to scan QR codes from image files."
            Manifest.permission.WRITE_EXTERNAL_STORAGE -> 
                "Storage permission is required to save generated QR codes to device storage."
            Manifest.permission.VIBRATE -> 
                "Vibration permission is required to provide haptic feedback when scanning codes."
            else -> "This permission is required for the app to function properly."
        }
    }
}

enum class PermissionType {
    CAMERA,
    STORAGE,
    VIBRATE,
    UNKNOWN
}

data class PermissionResult(
    val type: PermissionType,
    val granted: Boolean
)

data class PermissionStatus(
    val camera: Boolean,
    val storage: Boolean,
    val vibrate: Boolean
) {
    val allGranted: Boolean
        get() = camera && storage && vibrate
    
    val hasRequiredPermissions: Boolean
        get() = camera // Camera is the minimum required permission
    
    fun toMap(): Map<String, Any> {
        return mapOf(
            "camera" to camera,
            "storage" to storage,
            "vibrate" to vibrate,
            "allGranted" to allGranted,
            "hasRequiredPermissions" to hasRequiredPermissions
        )
    }
}
