# Identifie le programme qui occupe le port 8188 (et la VRAM) avant un gros rendu.
# Usage : clic droit -> "Exécuter avec PowerShell"

param([int]$Port = 8188)

$conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $conn) {
  Write-Host "Le port $Port est libre." -ForegroundColor Green
} else {
  $p = Get-CimInstance Win32_Process -Filter "ProcessId = $($conn.OwningProcess)"
  Write-Host "Port $Port occupé par :" -ForegroundColor Yellow
  Write-Host "  PID          : $($p.ProcessId)"
  Write-Host "  Programme    : $($p.ExecutablePath)"
  Write-Host "  Commande     : $($p.CommandLine)"
  $parent = Get-CimInstance Win32_Process -Filter "ProcessId = $($p.ParentProcessId)" -ErrorAction SilentlyContinue
  if ($parent) { Write-Host "  Lancé par    : $($parent.Name) ($($parent.ExecutablePath))" }
  Write-Host ""
  Write-Host "La ligne 'Commande' indique quel script Python tourne (ex. un ancien ComfyUI)."
  Write-Host "Pour l'arrêter jusqu'au prochain redémarrage : Stop-Process -Id $($p.ProcessId)"
}

# Démarrage automatique : où est-il déclaré ?
Write-Host "`nProgrammes Python lancés au démarrage :"
Get-CimInstance Win32_StartupCommand | Where-Object { $_.Command -match "python" } |
  ForEach-Object { Write-Host "  $($_.Name) : $($_.Command)  [$($_.Location)]" }
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { ($_.Actions.Execute -join " ") -match "python" } |
  ForEach-Object { Write-Host "  Tâche planifiée : $($_.TaskPath)$($_.TaskName)" }

# Occupation de la VRAM
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
  Write-Host "`nVRAM :"
  nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
  Write-Host "`nProcessus sur le GPU :"
  nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader
}
Read-Host "`nEntrée pour fermer"
