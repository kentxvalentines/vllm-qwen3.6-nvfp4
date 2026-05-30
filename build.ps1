# Local model-baked image builder for vllm-qwen3.6-nvfp4
$ErrorActionPreference = 'Stop'

$ModelFolder = 'D:\Gits\text-generation-webui\user_data\models\Huihui-Qwen3.6-35B-A3B-Claude-4.7-Opus-abliterated-NVFP4'
$ConfigsToStage = @()

if (-not (Test-Path $ModelFolder)) {
    Write-Host 'ERROR: Model folder not found at '$ModelFolder'!' -ForegroundColor Red
    exit 1
}

# Stage config files temporarily in the build context (the model folder)
$StagedFiles = @()
foreach ($Cfg in $ConfigsToStage) {
    $Src = Join-Path $PSScriptRoot $Cfg
    $Dest = Join-Path $ModelFolder $Cfg
    if (Test-Path $Src) {
        Copy-Item -Path $Src -Destination $Dest -Force
        $StagedFiles += $Dest
    }
}

Write-Host 'Building Docker image using standard build context...' -ForegroundColor Cyan
$BuildCommand = "docker build -f Dockerfile -t vllm-qwen3.6-nvfp4:latest \"$ModelFolder\""
Write-Host 'Command: '$BuildCommand -ForegroundColor DarkGray
Write-Host

try {
    Invoke-Expression $BuildCommand
    Write-Host '
SUCCESS: vllm-qwen3.6-nvfp4 built successfully!' -ForegroundColor Green
} catch {
    Write-Host '
FAILURE: Failed to build vllm-qwen3.6-nvfp4.' -ForegroundColor Red
    Write-Host $.Exception.Message -ForegroundColor Red
} finally {
    # Clean up
    if ($StagedFiles.Count -gt 0) {
        Write-Host 'Cleaning up staged configurations...' -ForegroundColor Gray
        foreach ($StagedFile in $StagedFiles) {
            if (Test-Path $StagedFile) {
                Remove-Item -Path $StagedFile -Force
            }
        }
    }
}
