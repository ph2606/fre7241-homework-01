param([switch]$SkipAnalysis)

$ErrorActionPreference = 'Stop'
$taskRoot = $PSScriptRoot
Push-Location -LiteralPath $taskRoot
try {
    if (-not $SkipAnalysis) {
        & Rscript --vanilla hw1_results/verify_hw1.R
        if ($LASTEXITCODE -ne 0) { throw 'Homework verification failed.' }
        & Rscript --vanilla report/export_results.R
        if ($LASTEXITCODE -ne 0) { throw 'Report results export failed.' }
        & Rscript --vanilla reproducibility/record_environment.R
        if ($LASTEXITCODE -ne 0) { throw 'Environment recording failed.' }
    }

    Push-Location -LiteralPath (Join-Path $taskRoot 'report')
    try {
        for ($pass = 1; $pass -le 2; $pass++) {
            & pdflatex -interaction=nonstopmode -halt-on-error Panagiotis_Housos_HW1_Report.tex
            if ($LASTEXITCODE -ne 0) { throw "LaTeX compilation failed on pass $pass." }
        }
    } finally {
        Pop-Location
    }
    Write-Output 'Built report/Panagiotis_Housos_HW1_Report.pdf'
} finally {
    Pop-Location
}
