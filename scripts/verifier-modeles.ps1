# Range les modèles du workflow SCAIL-2 (s'ils sont dans Téléchargements)
# puis vérifie qu'ils sont tous présents, complets et au bon endroit.
# Usage : double-clic sur verifier-modeles.bat

param(
  [string]$ComfyRoot = "C:\ComfyUI\ComfyUI_windows_portable",
  [string]$Downloads = "$env:USERPROFILE\Downloads"
)

$models = Join-Path $ComfyRoot "ComfyUI\models"

# Motif, sous-dossier, taille attendue approximative (en Mo)
$list = @(
  @{ Pattern = "sam3.1_multiplex_fp16*.safetensors";           Dir = "checkpoints";      SizeMB = 1630  }
  @{ Pattern = "lightx2v_I2V_14B_480p*.safetensors";           Dir = "loras";            SizeMB = 704   }
  @{ Pattern = "wan2.1_SCAIL_2_DPO_lora*.safetensors";         Dir = "loras";            SizeMB = 1140  }
  @{ Pattern = "Wan2_1_VAE_bf16*.safetensors";                 Dir = "vae";              SizeMB = 242   }
  @{ Pattern = "umt5_xxl_fp8_e4m3fn_scaled*.safetensors";      Dir = "text_encoders";    SizeMB = 6270  }
  @{ Pattern = "wan2.1_14B_SCAIL_2_int8_convrot*.safetensors"; Dir = "diffusion_models"; SizeMB = 15510 }
  @{ Pattern = "clip_vision_h*.safetensors";                   Dir = "clip_vision";      SizeMB = 1180  }
)

if (-not (Test-Path $models)) {
  Write-Host "Dossier introuvable : $models" -ForegroundColor Red
  Write-Host "Vérifie le chemin d'installation de ComfyUI." -ForegroundColor Red
  exit 1
}

# 1. Téléchargements encore en cours ?
$partial = Get-ChildItem -Path $Downloads, $models -Recurse -File -Include *.crdownload, *.part, *.tmp -ErrorAction SilentlyContinue
if ($partial) {
  Write-Host "`nTéléchargements pas encore terminés :" -ForegroundColor Yellow
  $partial | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Yellow }
  Write-Host "Attends la fin avant de lancer un rendu.`n" -ForegroundColor Yellow
}

# 2. Rangement + vérification
$ok = 0
Write-Host "`nModèles du workflow SCAIL-2 int8 :`n"
foreach ($m in $list) {
  $dir = Join-Path $models $m.Dir
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  $f = Get-ChildItem -Path $dir -Filter $m.Pattern -File -ErrorAction SilentlyContinue | Select-Object -First 1
  $moved = $false
  if (-not $f) {
    $dl = Get-ChildItem -Path $Downloads -Filter $m.Pattern -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dl) {
      Move-Item $dl.FullName (Join-Path $dir $dl.Name) -Force
      $f = Get-Item (Join-Path $dir $dl.Name)
      $moved = $true
    }
  }

  if (-not $f) {
    Write-Host ("MANQUANT   {0,-48} -> {1}" -f $m.Pattern, $m.Dir) -ForegroundColor Red
    continue
  }

  $mb = [math]::Round($f.Length / 1MB)
  # Tolérance large : les tailles affichées par ComfyUI peuvent être en Go ou en Gio
  if ($mb -lt $m.SizeMB * 0.85) {
    Write-Host ("INCOMPLET  {0,-48} {1,6} Mo au lieu de ~{2} Mo" -f $f.Name, $mb, $m.SizeMB) -ForegroundColor Red
    continue
  }

  $tag = if ($moved) { "OK (rangé)" } else { "OK        " }
  Write-Host ("{0} {1,-48} {2,6} Mo  -> {3}" -f $tag, $f.Name, $mb, $m.Dir) -ForegroundColor Green
  $ok++
}

Write-Host ""
if ($ok -eq $list.Count) {
  Write-Host "Les $ok modèles sont prêts. Relance ComfyUI et rouvre le workflow SCAIL-2." -ForegroundColor Green
} else {
  Write-Host "$ok / $($list.Count) modèles prêts. Complète les lignes en rouge puis relance ce script." -ForegroundColor Yellow
}

# 3. Espace disque restant
$drive = (Get-Item $models).PSDrive
Write-Host ("Espace libre sur {0}: : {1:N0} Go" -f $drive.Name, ($drive.Free / 1GB))
