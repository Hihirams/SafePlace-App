# Genera los assets de marca desde el PNG original del icono.
#
#   powershell -File design/make-assets.ps1
#
# Entrada: el icono con transparencia (por defecto, el que dejó el usuario en Descargas).
# Salida:  SafePlace/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
#          SafePlace/Assets.xcassets/SplashMark.imageset/SplashMark[@2x|@3x].png
#
# El recorte usa el bounding box real de los píxeles opacos, así que si el PNG
# cambia de tamaño sigue funcionando sin tocar números a mano.

param(
    [string]$Source = "$env:USERPROFILE\Downloads\87fe7290-691a-4db7-acd6-e2bdf2326671.png",
    [string]$Catalog = (Join-Path $PSScriptRoot "..\SafePlace\Assets.xcassets")
)

Add-Type -AssemblyName System.Drawing

$CREAM = [System.Drawing.Color]::FromArgb(255, 250, 248, 244) # #FAF8F4 SafeDesign.canvas
$DARK = [System.Drawing.Color]::FromArgb(255, 10, 10, 10)     # #0A0A0A, casi negro
$SPLASH_PT = 128        # tamaño del mark en el splash, en puntos
$ICON_FILL = 0.88       # fracción del tile 1024 que ocupa el mark

if (-not (Test-Path $Source)) { throw "No encuentro el PNG de origen: $Source" }
$src = [System.Drawing.Bitmap]::new([System.Drawing.Image]::FromFile($Source))
Write-Output "origen: $($src.Width)x$($src.Height)  $([System.IO.Path]::GetFileName($Source))"

# ── bounding box de lo opaco
$minX = $src.Width; $minY = $src.Height; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
        if ($src.GetPixel($x, $y).A -gt 8) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
if ($maxX -lt 0) { throw "El PNG no tiene píxeles opacos." }
$markW = $maxX - $minX + 1
$markH = $maxY - $minY + 1
Write-Output "marca: ${markW}x${markH} en ($minX,$minY)"

$mark = [System.Drawing.Bitmap]::new($markW, $markH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($mark)
$g.DrawImage($src, [System.Drawing.Rectangle]::new(0, 0, $markW, $markH),
             [System.Drawing.Rectangle]::new($minX, $minY, $markW, $markH), 'Pixel')
$g.Dispose()
$src.Dispose()

function Resize-Mark {
    param([System.Drawing.Bitmap]$Image, [int]$Width, [System.Drawing.Imaging.PixelFormat]$Format)
    $h = [int][Math]::Round($Image.Height * ($Width / $Image.Width))
    $bmp = [System.Drawing.Bitmap]::new($Width, $h, $Format)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CompositingMode = 'SourceOver'
    $g.CompositingQuality = 'HighQuality'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.SmoothingMode = 'HighQuality'
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($Image, [System.Drawing.Rectangle]::new(0, 0, $Width, $h))
    $g.Dispose()
    return $bmp
}

# ── SplashMark @1x @2x @3x
$set = Join-Path $Catalog "SplashMark.imageset"
New-Item -ItemType Directory -Force -Path $set | Out-Null
foreach ($scale in 1, 2, 3) {
    $w = $SPLASH_PT * $scale
    $bmp = Resize-Mark -Image $mark -Width $w -Format ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $name = if ($scale -eq 1) { "SplashMark.png" } else { "SplashMark@${scale}x.png" }
    $bmp.Save((Join-Path $set $name), [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "  $name  $($bmp.Width)x$($bmp.Height)"
    $bmp.Dispose()
}

$imagesJson = @'
{
  "images" : [
    { "filename" : "SplashMark.png",   "idiom" : "universal", "scale" : "1x" },
    { "filename" : "SplashMark@2x.png","idiom" : "universal", "scale" : "2x" },
    { "filename" : "SplashMark@3x.png","idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
'@
[System.IO.File]::WriteAllText((Join-Path $set "Contents.json"), $imagesJson, [System.Text.UTF8Encoding]::new($false))

# ── AppIcon 1024 opaco (iOS no admite alfa en el icono)
$iconSet = Join-Path $Catalog "AppIcon.appiconset"

function New-Icon {
    param([string]$Name, [System.Drawing.Color]$Background)
    $tile = [System.Drawing.Bitmap]::new(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($tile)
    $g.Clear($Background)
    $g.CompositingQuality = 'HighQuality'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $w = [int](1024 * $ICON_FILL)
    $h = [int][Math]::Round($mark.Height * ($w / $mark.Width))
    $x = [int]((1024 - $w) / 2)
    $y = [int]((1024 - $h) / 2)
    $g.DrawImage($mark, [System.Drawing.Rectangle]::new($x, $y, $w, $h))
    $g.Dispose()
    $tile.Save((Join-Path $iconSet $Name), [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "  $Name  marca ${w}x${h} en $x,$y"
    $tile.Dispose()
}

New-Icon -Name "AppIcon-1024.png"      -Background $CREAM
New-Icon -Name "AppIcon-1024-Dark.png" -Background $DARK

$iconJson = @'
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        { "appearance" : "luminosity", "value" : "dark" }
      ],
      "filename" : "AppIcon-1024-Dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
'@
[System.IO.File]::WriteAllText((Join-Path $iconSet "Contents.json"), $iconJson, [System.Text.UTF8Encoding]::new($false))

$mark.Dispose()

Write-Output "listo."
