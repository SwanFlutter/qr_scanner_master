package com.example.qr_scanner_master

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Point
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.io.File

class BarcodeScanner(private val context: Context) {
    
    private val scanner = BarcodeScanning.getClient()
    
    fun scanFromImagePath(imagePath: String, options: ScanOptions, callback: (List<ScanResult>) -> Unit) {
        try {
            val file = File(imagePath)
            if (!file.exists()) {
                callback(emptyList())
                return
            }
            
            val bitmap = BitmapFactory.decodeFile(imagePath)
            if (bitmap == null) {
                callback(emptyList())
                return
            }
            
            scanFromBitmap(bitmap, options, callback)
        } catch (e: Exception) {
            callback(emptyList())
        }
    }
    
    fun scanFromBytes(imageBytes: ByteArray, options: ScanOptions, callback: (List<ScanResult>) -> Unit) {
        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap == null) {
                callback(emptyList())
                return
            }
            
            scanFromBitmap(bitmap, options, callback)
        } catch (e: Exception) {
            callback(emptyList())
        }
    }
    
    private fun scanFromBitmap(bitmap: Bitmap, options: ScanOptions, callback: (List<ScanResult>) -> Unit) {
        val image = InputImage.fromBitmap(bitmap, 0)
        
        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                val results = barcodes.mapNotNull { barcode ->
                    if (shouldIncludeBarcode(barcode, options)) {
                        convertToScanResult(barcode)
                    } else {
                        null
                    }
                }
                callback(results)
            }
            .addOnFailureListener {
                callback(emptyList())
            }
    }
    
    private fun shouldIncludeBarcode(barcode: Barcode, options: ScanOptions): Boolean {
        if (options.formats.isEmpty()) {
            return true // Include all formats if none specified
        }
        
        val formatName = getBarcodeFormatName(barcode.format)
        return options.formats.contains(formatName)
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
            metadata = createMetadata(barcode)
        )
    }
    
    private fun createMetadata(barcode: Barcode): Map<String, Any> {
        val metadata = mutableMapOf<String, Any>()
        
        // Add barcode-specific data
        barcode.boundingBox?.let { rect ->
            metadata["boundingBox"] = mapOf(
                "left" to rect.left,
                "top" to rect.top,
                "right" to rect.right,
                "bottom" to rect.bottom
            )
        }
        
        // Add format-specific data
        when (barcode.valueType) {
            Barcode.TYPE_URL -> {
                barcode.url?.let { url ->
                    metadata["url"] = mapOf(
                        "title" to (url.title ?: ""),
                        "url" to (url.url ?: "")
                    )
                }
            }
            Barcode.TYPE_EMAIL -> {
                barcode.email?.let { email ->
                    metadata["email"] = mapOf(
                        "address" to (email.address ?: ""),
                        "subject" to (email.subject ?: ""),
                        "body" to (email.body ?: "")
                    )
                }
            }
            Barcode.TYPE_PHONE -> {
                barcode.phone?.let { phone ->
                    metadata["phone"] = mapOf(
                        "number" to (phone.number ?: ""),
                        "type" to phone.type
                    )
                }
            }
            Barcode.TYPE_SMS -> {
                barcode.sms?.let { sms ->
                    metadata["sms"] = mapOf(
                        "phoneNumber" to (sms.phoneNumber ?: ""),
                        "message" to (sms.message ?: "")
                    )
                }
            }
            Barcode.TYPE_WIFI -> {
                barcode.wifi?.let { wifi ->
                    metadata["wifi"] = mapOf(
                        "ssid" to (wifi.ssid ?: ""),
                        "password" to (wifi.password ?: ""),
                        "encryptionType" to wifi.encryptionType
                    )
                }
            }
            Barcode.TYPE_GEO -> {
                barcode.geoPoint?.let { geo ->
                    metadata["geoPoint"] = mapOf(
                        "latitude" to geo.lat,
                        "longitude" to geo.lng
                    )
                }
            }
            Barcode.TYPE_CONTACT_INFO -> {
                barcode.contactInfo?.let { contact ->
                    metadata["contactInfo"] = mapOf(
                        "name" to mapOf(
                            "first" to (contact.name?.first ?: ""),
                            "last" to (contact.name?.last ?: ""),
                            "middle" to (contact.name?.middle ?: ""),
                            "prefix" to (contact.name?.prefix ?: ""),
                            "suffix" to (contact.name?.suffix ?: ""),
                            "formattedName" to (contact.name?.formattedName ?: "")
                        ),
                        "organization" to (contact.organization ?: ""),
                        "title" to (contact.title ?: ""),
                        "phones" to (contact.phones?.map { phone ->
                            mapOf(
                                "number" to (phone.number ?: ""),
                                "type" to phone.type
                            )
                        } ?: emptyList()),
                        "emails" to (contact.emails?.map { email ->
                            mapOf(
                                "address" to (email.address ?: ""),
                                "type" to email.type
                            )
                        } ?: emptyList()),
                        "urls" to (contact.urls ?: emptyList()),
                        "addresses" to (contact.addresses?.map { address ->
                            mapOf(
                                "addressLines" to (address.addressLines?.toList() ?: emptyList()),
                                "type" to address.type
                            )
                        } ?: emptyList())
                    )
                }
            }
            Barcode.TYPE_CALENDAR_EVENT -> {
                barcode.calendarEvent?.let { event ->
                    metadata["calendarEvent"] = mapOf(
                        "summary" to (event.summary ?: ""),
                        "description" to (event.description ?: ""),
                        "location" to (event.location ?: ""),
                        "organizer" to (event.organizer ?: ""),
                        "status" to (event.status ?: ""),
                        "start" to (event.start?.rawValue ?: ""),
                        "end" to (event.end?.rawValue ?: "")
                    )
                }
            }
            Barcode.TYPE_DRIVER_LICENSE -> {
                barcode.driverLicense?.let { license ->
                    metadata["driverLicense"] = mapOf(
                        "documentType" to (license.documentType ?: ""),
                        "firstName" to (license.firstName ?: ""),
                        "middleName" to (license.middleName ?: ""),
                        "lastName" to (license.lastName ?: ""),
                        "gender" to (license.gender ?: ""),
                        "addressStreet" to (license.addressStreet ?: ""),
                        "addressCity" to (license.addressCity ?: ""),
                        "addressState" to (license.addressState ?: ""),
                        "addressZip" to (license.addressZip ?: ""),
                        "licenseNumber" to (license.licenseNumber ?: ""),
                        "issueDate" to (license.issueDate ?: ""),
                        "expiryDate" to (license.expiryDate ?: ""),
                        "birthDate" to (license.birthDate ?: ""),
                        "issuingCountry" to (license.issuingCountry ?: "")
                    )
                }
            }
        }
        
        return metadata
    }
}

data class ScanOptions(
    val formats: List<String> = emptyList(),
    val enableFlash: Boolean = false,
    val autoFocus: Boolean = true,
    val multiScan: Boolean = false,
    val maxScans: Int = 1,
    val beepOnScan: Boolean = true,
    val vibrateOnScan: Boolean = true,
    val showOverlay: Boolean = true,
    val overlayColor: Int = 0xFF00FF00.toInt(),
    val restrictScanArea: Boolean = false,
    val scanAreaRatio: Float = 0.7f,
    val timeoutSeconds: Int = 0,
    val returnImage: Boolean = false,
    val imageQuality: Float = 0.8f,
    val detectInverted: Boolean = false,
    val cameraResolution: String = "MEDIUM",
    val cameraFacing: String = "BACK"
) {
    companion object {
        fun fromMap(map: Map<String, Any>): ScanOptions {
            val formatsList = map["formats"] as? List<*>
            return ScanOptions(
                formats = formatsList?.filterIsInstance<String>() ?: emptyList(),
                enableFlash = map["enableFlash"] as? Boolean ?: false,
                autoFocus = map["autoFocus"] as? Boolean ?: true,
                multiScan = map["multiScan"] as? Boolean ?: false,
                maxScans = (map["maxScans"] as? Number)?.toInt() ?: 1,
                beepOnScan = map["beepOnScan"] as? Boolean ?: true,
                vibrateOnScan = map["vibrateOnScan"] as? Boolean ?: true,
                showOverlay = map["showOverlay"] as? Boolean ?: true,
                overlayColor = (map["overlayColor"] as? Number)?.toInt() ?: 0xFF00FF00.toInt(),
                restrictScanArea = map["restrictScanArea"] as? Boolean ?: false,
                scanAreaRatio = (map["scanAreaRatio"] as? Number)?.toFloat() ?: 0.7f,
                timeoutSeconds = (map["timeoutSeconds"] as? Number)?.toInt() ?: 0,
                returnImage = map["returnImage"] as? Boolean ?: false,
                imageQuality = (map["imageQuality"] as? Number)?.toFloat() ?: 0.8f,
                detectInverted = map["detectInverted"] as? Boolean ?: false,
                cameraResolution = map["cameraResolution"] as? String ?: "MEDIUM",
                cameraFacing = map["cameraFacing"] as? String ?: "BACK"
            )
        }
    }
}

data class ScanResult(
    val data: String,
    val format: String,
    val timestamp: Long,
    val cornerPoints: List<ScanPoint>,
    val metadata: Map<String, Any>
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "data" to data,
            "format" to format,
            "timestamp" to timestamp,
            "cornerPoints" to cornerPoints.map { it.toMap() },
            "metadata" to metadata
        )
    }
}

data class ScanPoint(
    val x: Double,
    val y: Double
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "x" to x,
            "y" to y
        )
    }
}
