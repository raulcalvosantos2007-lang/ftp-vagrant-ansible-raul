param(
    [string]$Nombre = "captura"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$destino = Join-Path $PSScriptRoot "evidencias\capturas"
New-Item -ItemType Directory -Force -Path $destino | Out-Null

$nombreSeguro = $Nombre -replace '[^a-zA-Z0-9_-]', '_'
$fecha = Get-Date -Format "yyyyMMdd_HHmmss"
$archivo = Join-Path $destino "$fecha-$nombreSeguro.png"

$limites = [System.Windows.Forms.SystemInformation]::VirtualScreen
$imagen = New-Object System.Drawing.Bitmap(
    $limites.Width, $limites.Height
)

$grafico = [System.Drawing.Graphics]::FromImage($imagen)

try {
    $grafico.CopyFromScreen(
        $limites.Left,
        $limites.Top,
        0,
        0,
        $imagen.Size
    )

    $imagen.Save(
        $archivo,
        [System.Drawing.Imaging.ImageFormat]::Png
    )

    Write-Host "Captura guardada en: $archivo"
}
finally {
    $grafico.Dispose()
    $imagen.Dispose()
}