package com.example.lnphone2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
    // 强制使用 TextureView 渲染模式，这比 Manifest 配置更可靠
    // TextureView 能有效解决 Android 低版本小窗模式下的白屏/黑屏问题
    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }
}
