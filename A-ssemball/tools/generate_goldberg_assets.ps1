param(
	[string]$AntiprismDir = "",
	[string]$OutputDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-DefaultPath([string]$Candidate) {
	return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $Candidate))
}

function Find-AntiprismDir() {
	$workspaceRoot = Resolve-DefaultPath "..\.."
	$match = Get-ChildItem -Path $workspaceRoot -Directory | Where-Object {
		Test-Path (Join-Path $_.FullName "geodesic.exe")
	} | Select-Object -First 1

	if ($null -eq $match) {
		throw "Could not locate an Antiprism directory under $workspaceRoot"
	}

	return $match.FullName
}

if ([string]::IsNullOrWhiteSpace($AntiprismDir)) {
	$AntiprismDir = Find-AntiprismDir
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
	$OutputDir = Resolve-DefaultPath "..\assets\generated\goldberg"
}

$geoExe = Join-Path $AntiprismDir "geodesic.exe"
$dualExe = Join-Path $AntiprismDir "pol_recip.exe"
$objExe = Join-Path $AntiprismDir "off2obj.exe"
$reportExe = Join-Path $AntiprismDir "off_report.exe"

$requiredTools = @($geoExe, $dualExe, $objExe, $reportExe)
foreach ($tool in $requiredTools) {
	if (-not (Test-Path $tool)) {
		throw "Required Antiprism tool not found: $tool"
	}
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$tempDir = Join-Path $OutputDir "_tmp"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

$shapes = @(
	@{ m = 2; n = 1 },
	@{ m = 3; n = 0 },
	@{ m = 3; n = 3 },
	@{ m = 4; n = 4 },
	@{ m = 8; n = 8 },
	@{ m = 1; n = 4 }
)

try {
	foreach ($shape in $shapes) {
		$m = [int]$shape.m
		$n = [int]$shape.n
		$shapeName = "g_{0}_{1}" -f $m, $n
		$geoPath = Join-Path $tempDir ("geo_{0}_{1}.off" -f $m, $n)
		$offPath = Join-Path $OutputDir ("{0}.off" -f $shapeName)
		$objPath = Join-Path $OutputDir ("{0}.obj" -f $shapeName)

		Write-Host ("Generating {0}" -f $shapeName)
		& $geoExe -c ("{0},{1}" -f $m, $n) ico -o $geoPath
		if ($LASTEXITCODE -ne 0) {
			throw "geodesic failed for $shapeName"
		}

		& $dualExe $geoPath -o $offPath
		if ($LASTEXITCODE -ne 0) {
			throw "pol_recip failed for $shapeName"
		}

		& $objExe $offPath -o $objPath
		if ($LASTEXITCODE -ne 0) {
			throw "off2obj failed for $shapeName"
		}

		$faceReport = & $reportExe -C s $offPath
		if ($LASTEXITCODE -ne 0) {
			throw "off_report failed for $shapeName"
		}

		Write-Host ($faceReport | Out-String).TrimEnd()
	}
}
finally {
	if (Test-Path $tempDir) {
		Remove-Item -Path $tempDir -Recurse -Force
	}
}
