<#
.SYNOPSIS
    Instala las reglas de Claude Code de este repositorio en la PC actual y, opcionalmente, en un proyecto.

.DESCRIPTION
    - Reglas globales: %USERPROFILE%\.claude\CLAUDE.md queda con una linea @import que apunta a
      global\CLAUDE.md de este repo, asi un "git pull" actualiza las reglas sin reinstalar.
    - Configuracion global: combina global\settings.json con %USERPROFILE%\.claude\settings.json
      (atribucion vacia + reglas "ask" que falten). No borra nada de lo que ya tengas.
    - Proyecto (opcional): crea CLAUDE.md o CLAUDE.local.md en el repo indicado.
    Antes de modificar un archivo existente, guarda una copia con sufijo .bak-<fecha>.

.PARAMETER Proyecto
    Ruta de un repositorio al que aplicar las reglas de proyecto.

.PARAMETER Tipo
    net10 o net48. Obligatorio junto con -Proyecto.

.PARAMETER Local
    Con -Proyecto: crea CLAUDE.local.md (solo para vos, no se commitea) que importa las reglas
    desde este repo. Sin -Local se crea CLAUDE.md con una copia de las reglas, para commitear.

.PARAMETER SoloProyecto
    Aplica solo las reglas de proyecto, sin tocar la configuracion global.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\instalar.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\instalar.ps1 -SoloProyecto -Proyecto C:\Repos\MiApp -Tipo net48

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\instalar.ps1 -SoloProyecto -Proyecto C:\Repos\MiApi -Tipo net10 -Local
#>
[CmdletBinding()]
param(
    [string]$Proyecto,
    [ValidateSet('net10', 'net48')]
    [string]$Tipo,
    [switch]$Local,
    [switch]$SoloProyecto
)

$ErrorActionPreference = 'Stop'

# En Windows PowerShell 5.1, ConvertTo-Json puede serializar arreglos como {"value":[...],"Count":n}.
# Quitar este type data (solo para esta sesion) evita ese error conocido. En PowerShell 7 no hace nada.
Remove-TypeData System.Array -ErrorAction SilentlyContinue

if (-not $env:USERPROFILE) { throw 'No se encontro la variable USERPROFILE.' }

$repoDir    = $PSScriptRoot
$perfilDir  = [System.IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd('\', '/')
$claudeDir  = Join-Path $perfilDir '.claude'
$utf8SinBom = New-Object System.Text.UTF8Encoding $false
$marca      = Get-Date -Format 'yyyyMMdd-HHmmss'

function Write-Ok([string]$texto)    { Write-Host "  [OK]    $texto" -ForegroundColor Green }
function Write-Aviso([string]$texto) { Write-Host "  [AVISO] $texto" -ForegroundColor Yellow }
function Write-Paso([string]$texto)  { Write-Host "`n$texto" -ForegroundColor Cyan }

function Get-RutaImport([string]$ruta) {
    # Devuelve la linea @import para un archivo: @~/... si esta dentro del perfil, absoluta si no.
    $completa = [System.IO.Path]::GetFullPath($ruta)
    $prefijo  = $perfilDir + [System.IO.Path]::DirectorySeparatorChar
    if ($completa.StartsWith($prefijo, [System.StringComparison]::OrdinalIgnoreCase)) {
        return '@~/' + ($completa.Substring($prefijo.Length) -replace '\\', '/')
    }
    return '@' + ($completa -replace '\\', '/')
}

function Write-Texto([string]$ruta, [string]$contenido) {
    [System.IO.File]::WriteAllText($ruta, $contenido, $utf8SinBom)
}

function Backup-Archivo([string]$ruta) {
    $copia = "$ruta.bak-$marca"
    Copy-Item -LiteralPath $ruta -Destination $copia
    Write-Aviso "Copia de seguridad: $copia"
}

function Set-Propiedad($objeto, [string]$nombre, $valor) {
    if ($objeto.PSObject.Properties[$nombre]) { $objeto.$nombre = $valor }
    else { $objeto | Add-Member -NotePropertyName $nombre -NotePropertyValue $valor }
}

function New-ContenidoMemoria([string]$archivoReglas, [string]$titulo) {
    # Contenido para un CLAUDE.md que importa las reglas del repo.
    # Si la ruta tiene espacios, el import no es confiable: se copia el contenido.
    $import = Get-RutaImport $archivoReglas
    if ($import -match '\s') {
        Write-Aviso "La ruta del repo tiene espacios; se copia el contenido en lugar de importarlo."
        Write-Aviso "Despues de cada 'git pull' volve a correr este script. Para evitarlo, clona el repo en una ruta sin espacios dentro de tu perfil."
        return [System.IO.File]::ReadAllText($archivoReglas, [System.Text.Encoding]::UTF8)
    }
    return "# $titulo`n`nLas reglas viven en el repo claude-config. Editalas en el repo, no en este archivo.`n`n$import`n"
}

# ---------------------------------------------------------------------------
# Configuracion global
# ---------------------------------------------------------------------------
if (-not $SoloProyecto) {
    if (-not (Test-Path -LiteralPath $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir | Out-Null
        Write-Ok "Carpeta creada: $claudeDir"
    }

    # --- CLAUDE.md global -------------------------------------------------
    Write-Paso 'Reglas globales (CLAUDE.md)'
    $reglasGlobales = Join-Path (Join-Path $repoDir 'global') 'CLAUDE.md'
    $destinoMemoria = Join-Path $claudeDir 'CLAUDE.md'
    $contenido      = New-ContenidoMemoria $reglasGlobales 'Reglas globales de Claude Code'

    if (Test-Path -LiteralPath $destinoMemoria) {
        $actual = [System.IO.File]::ReadAllText($destinoMemoria, [System.Text.Encoding]::UTF8)
        if ($actual -eq $contenido) {
            Write-Ok 'Ya estaba configurado.'
        } else {
            Backup-Archivo $destinoMemoria
            Write-Texto $destinoMemoria $contenido
            Write-Ok "Actualizado: $destinoMemoria"
            Write-Aviso 'Si la copia de seguridad tenia reglas propias que no estan en global\CLAUDE.md, pasalas al repo.'
        }
    } else {
        Write-Texto $destinoMemoria $contenido
        Write-Ok "Creado: $destinoMemoria"
    }

    # --- settings.json global ---------------------------------------------
    Write-Paso 'Configuracion global (settings.json)'
    $settingsRepo    = Join-Path (Join-Path $repoDir 'global') 'settings.json'
    $destinoSettings = Join-Path $claudeDir 'settings.json'
    $repoJson        = [System.IO.File]::ReadAllText($settingsRepo, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

    $textoActual = $null
    if (Test-Path -LiteralPath $destinoSettings) {
        $textoActual = [System.IO.File]::ReadAllText($destinoSettings, [System.Text.Encoding]::UTF8)
    }

    if ([string]::IsNullOrWhiteSpace($textoActual)) {
        if ($null -ne $textoActual) { Backup-Archivo $destinoSettings }
        Copy-Item -LiteralPath $settingsRepo -Destination $destinoSettings -Force
        Write-Ok "Creado: $destinoSettings"
    } else {
        try {
            $actualJson = $textoActual | ConvertFrom-Json
        } catch {
            throw "Tu settings.json actual no es JSON valido ($destinoSettings). Corregilo y volve a correr el script. Detalle: $($_.Exception.Message)"
        }
        $antes = $actualJson | ConvertTo-Json -Depth 50

        # Atribucion: se toma la del repo.
        Set-Propiedad $actualJson 'attribution' $repoJson.attribution

        # Permisos: se agregan las reglas "ask" que falten, sin quitar ninguna.
        if (-not $actualJson.PSObject.Properties['permissions'] -or $null -eq $actualJson.permissions) {
            Set-Propiedad $actualJson 'permissions' ([pscustomobject]@{})
        }
        $askActual = @()
        if ($actualJson.permissions.PSObject.Properties['ask'] -and $null -ne $actualJson.permissions.ask) {
            $askActual = @($actualJson.permissions.ask)
        }
        $nuevas = @($repoJson.permissions.ask | Where-Object { $askActual -notcontains $_ })
        Set-Propiedad $actualJson.permissions 'ask' ([object[]]($askActual + $nuevas))

        $despues = $actualJson | ConvertTo-Json -Depth 50
        if ($antes -eq $despues) {
            Write-Ok 'Ya estaba al dia.'
        } else {
            Backup-Archivo $destinoSettings
            Write-Texto $destinoSettings ($despues + "`n")
            Write-Ok "Actualizado: $destinoSettings ($($nuevas.Count) reglas 'ask' agregadas)"
        }
    }
}

# ---------------------------------------------------------------------------
# Reglas de proyecto (opcional)
# ---------------------------------------------------------------------------
if ($Proyecto) {
    if (-not $Tipo) { throw 'Indica -Tipo net10 o net48 junto con -Proyecto.' }
    if (-not (Test-Path -LiteralPath $Proyecto -PathType Container)) { throw "No existe la carpeta: $Proyecto" }

    $proyectoDir = (Resolve-Path -LiteralPath $Proyecto).Path
    $plantilla   = Join-Path (Join-Path $repoDir 'proyectos') "$Tipo.md"

    if ($Local) {
        Write-Paso "Reglas de proyecto ($Tipo, solo para vos)"
        $destino   = Join-Path $proyectoDir 'CLAUDE.local.md'
        $contenido = New-ContenidoMemoria $plantilla "Reglas de proyecto $Tipo"

        if (Test-Path -LiteralPath $destino) {
            $actual = [System.IO.File]::ReadAllText($destino, [System.Text.Encoding]::UTF8)
            if ($actual -eq $contenido) { Write-Ok 'Ya estaba configurado.' }
            else { Write-Aviso "Ya existe $destino y no se modifico. Combinalo a mano con proyectos\$Tipo.md." }
        } else {
            Write-Texto $destino $contenido
            Write-Ok "Creado: $destino"
        }

        # Excluir CLAUDE.local.md de Git solo en esta PC (no modifica .gitignore).
        $gitInfo = Join-Path (Join-Path $proyectoDir '.git') 'info'
        if (Test-Path -LiteralPath $gitInfo -PathType Container) {
            $exclude = Join-Path $gitInfo 'exclude'
            $lineas  = @()
            if (Test-Path -LiteralPath $exclude) { $lineas = @(Get-Content -LiteralPath $exclude) }
            if ($lineas -notcontains 'CLAUDE.local.md') {
                [System.IO.File]::AppendAllText($exclude, "`nCLAUDE.local.md`n", $utf8SinBom)
                Write-Ok 'CLAUDE.local.md excluido de Git en esta PC (.git\info\exclude).'
            }
        } else {
            Write-Aviso 'No se encontro .git\info en el proyecto: asegurate de no commitear CLAUDE.local.md.'
        }
    } else {
        Write-Paso "Reglas de proyecto ($Tipo, para el equipo)"
        $destino = Join-Path $proyectoDir 'CLAUDE.md'
        if (Test-Path -LiteralPath $destino) {
            Write-Aviso "Ya existe $destino y no se modifico. Combinalo a mano con proyectos\$Tipo.md."
        } else {
            Copy-Item -LiteralPath $plantilla -Destination $destino
            Write-Ok "Creado: $destino"
            Write-Aviso 'Revisalo y commitealo cuando quieras compartirlo con el equipo.'
        }
    }
}

Write-Paso 'Listo.'
Write-Host '  Abri una conversacion nueva de Claude Code en VS Code y pregunta:'
Write-Host '  "Que reglas tenes cargadas desde CLAUDE.md?"'
Write-Host '  Si te pide aprobar la importacion de archivos externos, aceptala.'
