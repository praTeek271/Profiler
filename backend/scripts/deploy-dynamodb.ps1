# scripts/deploy-dynamodb.ps1
# Deploys the DynamoDB tables stack (patientDB + medicalrecordDB)
# Run this FIRST before any other stack.
#
# Usage:
#   .\scripts\deploy-dynamodb.ps1
#   .\scripts\deploy-dynamodb.ps1 -Stage dev

param(
    [string]$Stage = "prod"
)

$ErrorActionPreference = "Stop"
$BackendRoot = Join-Path $PSScriptRoot ".."

# -----------------------------------------------------------------------
# Load .env with ${VAR} interpolation support
# -----------------------------------------------------------------------
$EnvPath = Join-Path $BackendRoot ".env"
if (-not (Test-Path $EnvPath)) {
    Write-Error ".env not found at $EnvPath. Copy .env.example to .env and fill in values."
    exit 1
}

$EnvVars = @{}
Get-Content $EnvPath | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.*)\s*$") {
        $EnvVars[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}
# Resolve ${VAR} references
$resolved = @{}
foreach ($key in $EnvVars.Keys) {
    $val = $EnvVars[$key]
    $val = [regex]::Replace($val, '\$\{([^}]+)\}', {
        param($m)
        $ref = $m.Groups[1].Value
        if ($EnvVars.ContainsKey($ref)) { $EnvVars[$ref] } else { $m.Value }
    })
    $resolved[$key] = $val
}

$AppName    = $resolved["APP_NAME"]
$Region     = if ($resolved["AWS_REGION"]) { $resolved["AWS_REGION"] } else { "us-east-1" }
$AwsProfile = $resolved["AWS_PROFILE"]
$StackName  = "$AppName-dynamodb-$Stage"
$Template   = Join-Path $BackendRoot "templates\dynamodb-stack.yaml"

if (-not $AppName) { Write-Error "APP_NAME is not set in .env."; exit 1 }
if (-not $AwsProfile) { Write-Error "AWS_PROFILE is not set in .env."; exit 1 }

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Deploy: DynamoDB Stack" -ForegroundColor Cyan
Write-Host " App    : $AppName" -ForegroundColor Cyan
Write-Host " Stack  : $StackName" -ForegroundColor Cyan
Write-Host " Region : $Region" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

aws cloudformation deploy `
    --template-file $Template `
    --stack-name $StackName `
    --region $Region `
    --profile $AwsProfile `
    --parameter-overrides Stage=$Stage AppName=$AppName `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Error "DynamoDB stack deployment failed."
    exit 1
}

Write-Host ""
Write-Host "DynamoDB stack deployed successfully." -ForegroundColor Green

aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --profile $AwsProfile `
    --query "Stacks[0].Outputs[*].{Output:OutputKey,Value:OutputValue}" `
    --output table
