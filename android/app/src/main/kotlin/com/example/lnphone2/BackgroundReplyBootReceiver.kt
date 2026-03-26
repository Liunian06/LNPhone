package com.example.lnphone2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BackgroundReplyBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        BackgroundReplyNativeHelper.restoreWakeupFromPersistence(context)
    }
}
