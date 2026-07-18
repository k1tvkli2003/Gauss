param(
  [Parameter(Mandatory = $true)]
  [string]$Url,

  [Parameter(Mandatory = $true)]
  [int]$Width,

  [Parameter(Mandatory = $true)]
  [int]$Height,

  [Parameter(Mandatory = $true)]
  [string]$Output,

  [int]$TimeoutSeconds = 55,
  [int]$SettleSeconds = 5,
  [int]$TapX = -1,
  [int]$TapY = -1,
  [int]$PostActionSettleSeconds = 4,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ChromePath)) {
  throw "Chrome was not found at $ChromePath"
}
if ($Width -lt 280 -or $Height -lt 400) {
  throw 'Viewport must be at least 280x400.'
}
if (($TapX -ge 0) -xor ($TapY -ge 0)) {
  throw 'TapX and TapY must be supplied together.'
}

$resolvedOutput = [System.IO.Path]::GetFullPath($Output)
$outputDirectory = Split-Path -Parent $resolvedOutput
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

$listener = [System.Net.Sockets.TcpListener]::new(
  [System.Net.IPAddress]::Loopback,
  0
)
$listener.Start()
$debugPort = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
$listener.Stop()

$profile = Join-Path $env:TEMP ("gauss-preview-{0}" -f [guid]::NewGuid())
$chromeArguments = @(
  '--headless=new'
  '--hide-scrollbars'
  '--no-first-run'
  '--no-default-browser-check'
  '--disable-background-networking'
  "--remote-debugging-port=$debugPort"
  "--user-data-dir=$profile"
  "--window-size=$Width,$Height"
  'about:blank'
)

$chromeStart = @{
  FilePath = $ChromePath
  ArgumentList = $chromeArguments
  WindowStyle = 'Hidden'
  PassThru = $true
}
$chrome = Start-Process @chromeStart

$socket = $null
$nextMessageId = 0

function Receive-CdpMessage {
  param([System.Net.WebSockets.ClientWebSocket]$Socket)

  $stream = [System.IO.MemoryStream]::new()
  try {
    do {
      $buffer = [byte[]]::new(65536)
      $segment = [System.ArraySegment[byte]]::new($buffer)
      $result = $Socket.ReceiveAsync(
        $segment,
        [System.Threading.CancellationToken]::None
      ).GetAwaiter().GetResult()
      if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        throw 'Chrome closed the DevTools connection before capture.'
      }
      $stream.Write($buffer, 0, $result.Count)
    } while (-not $result.EndOfMessage)

    return [System.Text.Encoding]::UTF8.GetString($stream.ToArray()) |
      ConvertFrom-Json
  } finally {
    $stream.Dispose()
  }
}

function Send-CdpCommand {
  param(
    [System.Net.WebSockets.ClientWebSocket]$Socket,
    [string]$Method,
    [hashtable]$Parameters = @{}
  )

  $script:nextMessageId++
  $messageId = $script:nextMessageId
  $payload = @{
    id = $messageId
    method = $Method
    params = $Parameters
  } | ConvertTo-Json -Compress -Depth 20
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
  $segment = [System.ArraySegment[byte]]::new($bytes)
  $null = $Socket.SendAsync(
    $segment,
    [System.Net.WebSockets.WebSocketMessageType]::Text,
    $true,
    [System.Threading.CancellationToken]::None
  ).GetAwaiter().GetResult()

  while ($true) {
    $message = Receive-CdpMessage -Socket $Socket
    if ($message.id -ne $messageId) {
      continue
    }
    if ($null -ne $message.error) {
      throw "CDP $Method failed: $($message.error.message)"
    }
    return $message.result
  }
}

try {
  $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
  $page = $null
  do {
    try {
      $pages = Invoke-RestMethod -Uri "http://127.0.0.1:$debugPort/json/list" -TimeoutSec 2
      $page = $pages | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
    } catch {
      Start-Sleep -Milliseconds 150
    }
  } while ($null -eq $page -and [DateTime]::UtcNow -lt $deadline)

  if ($null -eq $page) {
    throw 'Chrome DevTools did not become ready.'
  }

  $socket = [System.Net.WebSockets.ClientWebSocket]::new()
  $null = $socket.ConnectAsync(
    [uri]$page.webSocketDebuggerUrl,
    [System.Threading.CancellationToken]::None
  ).GetAwaiter().GetResult()

  Send-CdpCommand -Socket $socket -Method 'Page.enable' | Out-Null
  Send-CdpCommand -Socket $socket -Method 'Runtime.enable' | Out-Null
  Send-CdpCommand -Socket $socket -Method 'Emulation.setDeviceMetricsOverride' -Parameters @{
    width = $Width
    height = $Height
    deviceScaleFactor = 1
    mobile = $false
  } | Out-Null
  Send-CdpCommand -Socket $socket -Method 'Page.navigate' -Parameters @{
    url = $Url
  } | Out-Null

  $flutterReady = $false
  do {
    Start-Sleep -Milliseconds 250
    $evaluation = Send-CdpCommand -Socket $socket -Method 'Runtime.evaluate' -Parameters @{
        expression = @'
document.readyState === 'complete' &&
Boolean(document.querySelector('flutter-view, flt-glass-pane'))
'@
        returnByValue = $true
      }
    $flutterReady = [bool]$evaluation.result.value
  } while (-not $flutterReady -and [DateTime]::UtcNow -lt $deadline)

  if (-not $flutterReady) {
    throw 'Flutter did not attach a render surface before the timeout.'
  }

  Start-Sleep -Seconds $SettleSeconds
  if ($TapX -ge 0 -and $TapY -ge 0) {
    Send-CdpCommand -Socket $socket -Method 'Input.dispatchMouseEvent' -Parameters @{
      type = 'mousePressed'
      x = $TapX
      y = $TapY
      button = 'left'
      clickCount = 1
    } | Out-Null
    Send-CdpCommand -Socket $socket -Method 'Input.dispatchMouseEvent' -Parameters @{
      type = 'mouseReleased'
      x = $TapX
      y = $TapY
      button = 'left'
      clickCount = 1
    } | Out-Null
    Start-Sleep -Seconds $PostActionSettleSeconds
  }
  $capture = Send-CdpCommand -Socket $socket -Method 'Page.captureScreenshot' -Parameters @{
    format = 'png'
    fromSurface = $true
    captureBeyondViewport = $false
  }
  [System.IO.File]::WriteAllBytes(
    $resolvedOutput,
    [Convert]::FromBase64String($capture.data)
  )

  $file = Get-Item -LiteralPath $resolvedOutput
  [pscustomobject]@{
    output = $file.FullName
    bytes = $file.Length
    width = $Width
    height = $Height
    url = $Url
    tap = if ($TapX -ge 0) { "$TapX,$TapY" } else { $null }
  }
} finally {
  if ($null -ne $socket) {
    $socket.Dispose()
  }
  if ($null -ne $chrome -and -not $chrome.HasExited) {
    Stop-Process -Id $chrome.Id -Force -ErrorAction SilentlyContinue
  }
}
