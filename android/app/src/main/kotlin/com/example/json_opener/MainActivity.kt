package com.example.json_opener

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel.shared.data"
    private var sharedData: String? = null
    private var flutterEngine: FlutterEngine? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine
        Log.d("MainActivity", "Configuring method channel")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedData" -> {
                    Log.d("MainActivity", "Returning shared data: $sharedData")
                    result.success(sharedData)
                    sharedData = null
                }
                else -> {
                    Log.d("MainActivity", "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("MainActivity", "Received new intent")
        handleIntent(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "Activity created")
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type
        val uri = intent.data
    
        Log.d("MainActivity", "Handling intent. Action: $action, Type: $type, URI: $uri")
    
        if (Intent.ACTION_VIEW == action && uri != null) {
            if (type == "application/json" || type == "text/plain" || 
                uri.toString().endsWith(".json")) {
                try {
                    val inputStream = contentResolver.openInputStream(uri)
                    val jsonContent = inputStream?.bufferedReader().use { it?.readText() }
                    inputStream?.close()
                    
                    val tempFile = File.createTempFile("temp_json", ".json", cacheDir)
                    tempFile.writeText(jsonContent ?: "")
                    
                    sharedData = tempFile.absolutePath
                    Log.d("MainActivity", "Set shared data to: $sharedData")
                    
                    flutterEngine?.let { engine ->
                        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                            .invokeMethod("onFileOpened", sharedData)
                    }
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error handling file: $e")
                }
            }
        }
    }
}