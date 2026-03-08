package com.example.payparse

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.payparse/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SMS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSms" -> {
                    val limit = call.argument<Int>("limit") ?: 200
                    try {
                        val smsList = readSms(limit)
                        result.success(smsList)
                    } catch (e: Exception) {
                        result.error("SMS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readSms(limit: Int): List<Map<String, Any>> {
        val smsList = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            Uri.parse("content://sms/inbox"),
            arrayOf("_id", "address", "body", "date"),
            null,
            null,
            "date DESC LIMIT $limit"
        )

        cursor?.use {
            val idIdx = it.getColumnIndexOrThrow("_id")
            val addressIdx = it.getColumnIndexOrThrow("address")
            val bodyIdx = it.getColumnIndexOrThrow("body")
            val dateIdx = it.getColumnIndexOrThrow("date")

            while (it.moveToNext()) {
                smsList.add(
                    mapOf(
                        "id" to it.getInt(idIdx),
                        "address" to (it.getString(addressIdx) ?: "Unknown"),
                        "body" to (it.getString(bodyIdx) ?: ""),
                        "date" to it.getLong(dateIdx)
                    )
                )
            }
        }

        return smsList
    }
}
