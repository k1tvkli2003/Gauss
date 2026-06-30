package com.gauss.app.ui.components

import android.graphics.BitmapFactory
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.gauss.app.data.ContentBlock
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.LinkedHashMap

private object AssetBitmapCache {
    private const val MAX_ENTRIES = 48
    private val items = object : LinkedHashMap<String, ImageBitmap>(MAX_ENTRIES, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, ImageBitmap>?): Boolean =
            size > MAX_ENTRIES
    }

    @Synchronized fun get(asset: String): ImageBitmap? = items[asset]
    @Synchronized fun put(asset: String, bitmap: ImageBitmap) {
        items[asset] = bitmap
    }
}

@Composable
fun RichContent(
    blocks: List<ContentBlock>,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 16.sp,
) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        blocks.forEach { block ->
            when (block) {
                is ContentBlock.Text -> MathText(block.text, fontSize = fontSize)
                is ContentBlock.Image -> AssetMedia(block)
            }
        }
    }
}

@Composable
private fun AssetMedia(block: ContentBlock.Image) {
    val context = LocalContext.current
    var bitmap by remember(block.asset) { mutableStateOf<ImageBitmap?>(null) }
    LaunchedEffect(block.asset) {
        bitmap = null
        AssetBitmapCache.get(block.asset)?.let {
            bitmap = it
            return@LaunchedEffect
        }
        bitmap = withContext(Dispatchers.IO) {
            runCatching {
                context.assets.open(block.asset).use { stream ->
                    BitmapFactory.decodeStream(stream).asImageBitmap().also { decoded ->
                        AssetBitmapCache.put(block.asset, decoded)
                    }
                }
            }.getOrNull()
        }
    }
    var expanded by remember { mutableStateOf(false) }
    val image = bitmap
    if (image == null) {
        Box(
            Modifier
                .fillMaxWidth()
                .then(if (block.aspectRatio != null) Modifier.aspectRatio(block.aspectRatio) else Modifier.height(156.dp))
                .clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(12.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(block.alt.ifBlank { "Preparing image..." }, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
        }
        return
    }
    androidx.compose.foundation.Image(
        bitmap = image,
        contentDescription = block.alt,
        contentScale = ContentScale.Fit,
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(block.aspectRatio ?: (image.width.toFloat() / image.height.toFloat()).coerceIn(0.35f, 2.8f))
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .clickableNoRipple { expanded = true },
    )
    if (expanded) MediaViewer(image, block.alt) { expanded = false }
}

@Composable
private fun MediaViewer(bitmap: ImageBitmap, alt: String, onDismiss: () -> Unit) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        var scale by remember { mutableFloatStateOf(1f) }
        var offset by remember { mutableStateOf(Offset.Zero) }
        Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.scrim.copy(alpha = 0.94f))) {
            androidx.compose.foundation.Image(
                bitmap = bitmap,
                contentDescription = alt,
                contentScale = ContentScale.Fit,
                modifier = Modifier.fillMaxSize().padding(20.dp)
                    .pointerInput(Unit) {
                        detectTransformGestures { _, pan, zoom, _ ->
                            scale = (scale * zoom).coerceIn(1f, 5f)
                            offset = if (scale == 1f) Offset.Zero else offset + pan
                        }
                    }
                    .graphicsLayer(scaleX = scale, scaleY = scale, translationX = offset.x, translationY = offset.y),
            )
            IconButton(onClick = onDismiss, modifier = Modifier.align(Alignment.TopEnd).padding(16.dp).size(48.dp)) {
                Icon(Icons.Rounded.Close, contentDescription = "Close", tint = MaterialTheme.colorScheme.onPrimary)
            }
        }
    }
}
