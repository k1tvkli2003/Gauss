import React, { useMemo, useState } from "react";
import { Platform, Text, View } from "react-native";
import { WebView } from "react-native-webview";
import { colors } from "@/theme/colors";

interface Props {
  content: string;
  fontSize?: number;
  color?: string;
}

/**
 * Renders markdown-lite + LaTeX (KaTeX) with RTL Persian support.
 * Inline math: $...$   Block math: $$...$$
 * Self-sizing via a postMessage height handshake.
 */
function buildHtml(content: string, fontSize: number, color: string): string {
  // Escape for safe embedding inside a JS template string in the page.
  const safe = content
    .replace(/\\/g, "\\\\")
    .replace(/`/g, "\\`")
    .replace(/\$\{/g, "\\${");

  return `<!DOCTYPE html><html><head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css" />
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
<style>
  @font-face{
    font-family:'Vazirmatn';
    font-weight:400;
    font-display:swap;
    src:url('https://cdn.jsdelivr.net/npm/vazirmatn@33.0.3/fonts/webfonts/Vazirmatn-Regular.woff2') format('woff2');
  }
  @font-face{
    font-family:'Vazirmatn';
    font-weight:700;
    font-display:swap;
    src:url('https://cdn.jsdelivr.net/npm/vazirmatn@33.0.3/fonts/webfonts/Vazirmatn-Bold.woff2') format('woff2');
  }
  html,body{margin:0;padding:0;background:transparent;}
  #root{
    color:${color};
    font-size:${fontSize}px;
    line-height:1.85;
    font-family:'Vazirmatn',-apple-system,Roboto,'Segoe UI',sans-serif;
    direction:rtl;
    text-align:right;
    padding:2px 4px;
    word-wrap:break-word;
  }
  .katex{font-size:1.05em;}
  code{background:${colors.raised};padding:2px 6px;border-radius:6px;direction:ltr;display:inline-block;}
  pre{background:${colors.raised};padding:10px;border-radius:10px;direction:ltr;overflow-x:auto;}
  strong{color:${colors.neonBlue};}
  hr{border:none;border-top:1px solid ${colors.border};margin:12px 0;}
  ul,ol{padding-right:20px;}
</style>
</head><body>
<div id="root"></div>
<script>
  function mdToHtml(src){
    var lines = src.split('\\n');
    var out = '', inList = false;
    for (var i=0;i<lines.length;i++){
      var l = lines[i];
      var t = l.trim();
      if (/^[-*]\\s+/.test(t)) {
        if(!inList){out+='<ul>';inList=true;}
        out += '<li>'+inline(t.replace(/^[-*]\\s+/,''))+'</li>';
        continue;
      }
      if(inList){out+='</ul>';inList=false;}
      if(t==='') { out+='<br/>'; continue; }
      if(/^---+$/.test(t)){ out+='<hr/>'; continue; }
      out += '<div>'+inline(l)+'</div>';
    }
    if(inList) out+='</ul>';
    return out;
  }
  function inline(s){
    return s
      .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
      .replace(/\\*\\*(.+?)\\*\\*/g,'<strong>$1</strong>')
      .replace(/\`(.+?)\`/g,'<code>$1</code>');
  }
  function postHeight(){
    var h = document.getElementById('root').scrollHeight;
    if(window.ReactNativeWebView) window.ReactNativeWebView.postMessage(String(h));
  }
  function go(){
    var raw = \`${safe}\`;
    document.getElementById('root').innerHTML = mdToHtml(raw);
    if(window.renderMathInElement){
      window.renderMathInElement(document.getElementById('root'), {
        delimiters:[
          {left:'$$',right:'$$',display:true},
          {left:'$',right:'$',display:false}
        ],
        throwOnError:false
      });
    }
    setTimeout(postHeight, 50);
    setTimeout(postHeight, 350);
  }
  window.addEventListener('load', go);
  document.addEventListener('DOMContentLoaded', function(){ setTimeout(go, 30); });
</script>
</body></html>`;
}

export function MathText({ content, fontSize = 17, color = colors.text }: Props) {
  const [height, setHeight] = useState(40);
  const html = useMemo(
    () => buildHtml(content, fontSize, color),
    [content, fontSize, color],
  );

  if (Platform.OS === "web") {
    // RN-web: WebView is unreliable; render a plain-text fallback (no KaTeX).
    return (
      <View>
        <Text style={{ color, fontSize, writingDirection: "rtl", textAlign: "right" }}>
          {content}
        </Text>
      </View>
    );
  }

  return (
    <View style={{ height }}>
      <WebView
        originWhitelist={["*"]}
        source={{ html }}
        style={{ backgroundColor: "transparent" }}
        scrollEnabled={false}
        showsVerticalScrollIndicator={false}
        onMessage={(e) => {
          const h = Number(e.nativeEvent.data);
          if (!Number.isNaN(h) && h > 0) setHeight(Math.ceil(h) + 6);
        }}
        androidLayerType="hardware"
      />
    </View>
  );
}
