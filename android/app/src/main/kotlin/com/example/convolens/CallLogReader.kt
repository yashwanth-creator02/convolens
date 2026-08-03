package com.example.convolens

import android.content.Context
import android.provider.CallLog

class CallLogReader(private  val context: Context){

    fun readCallLogs(): List<Map<String, Any?>>{
        val calls=mutableListOf<Map<String, Any?>>()
        val cursor =context.contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            null,
            null,
            null,
            CallLog.Calls.DATE+" DESC"
        )
        cursor?.use{
            val numberIndex=it.getColumnIndex(CallLog.Calls.NUMBER)
            val nameIndex=it.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val typeIndex=it.getColumnIndex(CallLog.Calls.TYPE)
            val durationIndex=it.getColumnIndex(CallLog.Calls.DURATION)
            val dateIndex=it.getColumnIndex(CallLog.Calls.DATE)

            while (it.moveToNext()){
                val call = mapOf(
                    "number" to it.getString(numberIndex),
                    "name" to it.getString(nameIndex),
                    "type" to it.getInt(typeIndex),
                    "duration" to it.getLong(durationIndex),
                    "timestamp" to it.getLong(dateIndex)
                )
                calls.add(call)
            }
        }
        return calls
    }

}