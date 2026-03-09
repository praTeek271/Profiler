# scripts/deploy-lambdas.ps1
# Builds TypeScript Lambda functions with esbuild and deploys them via SAM.
#
# Sources of truth:
#   .env          — APP_NAME, AWS_REGION, PATIENT_TABLE, RECORDS_TABLE, REDIS_URL
#   lambdaMap.json — lambda names and entry point paths
#
# Lambda function names deployed to AWS: {APP_NAME}-{lambdaName}-{Stage}
#
# Usage:
#   .\scripts\deploy-lambdas.ps1
#   .\scripts\deploy-lambdas.ps1 -Stage dev
#   .\scripts\deploy-lambdas.ps1 -Guided   # first-time interactive SAM run

param(
    [string]$Stage = "prod",
    [switch]$Guided
)

$ErrorActionPreference = "Stop"
$BackendRoot = Join-Path $PSScriptRoot ".."

# -----------------------------------------------------------------------
# 1. Load .env with ${VAR} interpolation support
# -----------------------------------------------------------------------
$EnvPath = Join-Path $BackendRoot ".env"
if (-not (Test-Path $EnvPath)) {
    Write-Error ".env not found at $EnvPath. Copy .env.example to .env and fill in values."
    exit 1
}

$EnvVars = @{}

# First pass: load raw values
Get-Content $EnvPath | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.*)\s*$") {
        $EnvVars[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

# Second pass: resolve ${VAR_NAME} references within values
$resolved = @{}
foreach ($key in $EnvVars.Keys) {
    $val = $EnvVars[$key]
    $val = [regex]::Replace($val, '\$\{([^}]+)\}', {
        param($m)
        $ref = $m.Groups[1].Value
        if ($EnvVars.ContainsKey($ref)) { $EnvVars[$ref] } else { $m.Value }
    })
    $resolved[$key] = $val
    [System.Environment]::SetEnvironmentVariable($key, $val)
}

# -----------------------------------------------------------------------
# 2. Validate required vars
# -----------------------------------------------------------------------
$AppName      = $resolved["APP_NAME"]
$Region       = if ($resolved["AWS_REGION"]) { $resolved["AWS_REGION"] } else { "us-east-1" }
$PatientTable = $resolved["PATIENT_TABLE"]
$RecordsTable = $resolved["RECORDS_TABLE"]
$RedisUrl     = $resolved["REDIS_URL"]

if (-not $AppName) { Write-Error "APP_NAME is not set in .env."; exit 1 }
if (-not $RedisUrl) { Write-Error "REDIS_URL is not set in .env. Get it from your Redis Cloud dashboard."; exit 1 }
if (-not $PatientTable) { Write-Error "PATIENT_TABLE is not set in .env."; exit 1 }
if (-not $RecordsTable) { Write-Error "RECORDS_TABLE is not set in .env."; exit 1 }

# -----------------------------------------------------------------------
# 3. Load and validate lambdaMap.json
# -----------------------------------------------------------------------
$LambdaMapPath = Join-Path $BackendRoot "lambdaMap.json"
if (-not (Test-Path $LambdaMapPath)) {
    Write-Error "lambdaMap.json not found at $LambdaMapPath."
    exit 1
}

# Strip JS-style line comments before parsing (// ...) since the file uses them
$LambdaMapRaw = (Get-Content $LambdaMapPath -Raw) -replace '(?m)^\s*//.*$', ''
# Strip trailing commas before ] (JSON doesn't allow them)
$LambdaMapRaw = $LambdaMapRaw -replace ',\s*\]', ']'

$LambdaMap = $LambdaMapRaw | ConvertFrom-Json

Write-Host ""
Write-Host "Lambda functions from lambdaMap.json:" -ForegroundColor DarkCyan
$LambdaMap | ForEach-Object {
    $lambdaName = $_[2]
    $entryPoint = $_[1]
    $deployedName = "$AppName-$lambdaName-$Stage"
    $fullPath = Join-Path $BackendRoot $entryPoint

    if (-not (Test-Path $fullPath)) {
        Write-Error "Lambda entry point not found: $fullPath (from lambdaMap.json)"
        exit 1
    }
    Write-Host "  $deployedName  <- $entryPoint" -ForegroundColor Gray
}

$StackName = "$AppName-lambdas-$Stage"
$Template  = Join-Path $BackendRoot "templates\lambda-stack.yaml"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Deploy: Lambda Stack" -ForegroundColor Cyan
Write-Host " App    : $AppName" -ForegroundColor Cyan
Write-Host " Stack  : $StackName" -ForegroundColor Cyan
Write-Host " Region : $Region" -ForegroundColor Cyan
Write-Host " Tables : $PatientTable / $RecordsTable" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------
# 4. SAM Build  (esbuild bundles TypeScript + all imported services)
# -----------------------------------------------------------------------
Write-Host "[1/2] Building Lambda functions..." -ForegroundColor Yellow

Push-Location $BackendRoot
sam build --template-file $Template
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error "sam build failed."; exit 1 }
Pop-Location

Write-Host "Build successful." -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------
# 5. SAM Deploy
# -----------------------------------------------------------------------
Write-Host "[2/2] Deploying to AWS ($Region)..." -ForegroundColor Yellow

$Params = @(
    "--stack-name", $StackName,
    "--region", $Region,
    "--parameter-overrides",
        "Stage=$Stage",
        "AppName=$AppName",
        "RedisUrl=$RedisUrl",
        "PatientTable=$PatientTable",
        "RecordsTable=$RecordsTable",
    "--capabilities", "CAPABILITY_IAM",
    "--no-confirm-changeset"
)

if ($Guided) {
    sam deploy --guided @Params
} else {
    sam deploy @Params
}

if ($LASTEXITCODE -ne 0) { Write-Error "sam deploy failed."; exit 1 }

Write-Host ""
Write-Host "Lambda stack deployed successfully." -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------
# 6. Print Lambda ARNs
# -----------------------------------------------------------------------
Write-Host "Lambda ARNs (use these to wire to API Gateway):" -ForegroundColor Cyan
aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].Outputs[*].{Output:OutputKey,ARN:OutputValue}" `
    --output table
