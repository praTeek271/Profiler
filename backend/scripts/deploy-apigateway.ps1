# scripts/deploy-apigateway.ps1
# Deploys the API Gateway stack, wiring it to the Lambda functions
# from the lambda stack outputs.
# Run AFTER deploy-lambdas.ps1.
#
# Usage:
#   .\scripts\deploy-apigateway.ps1
#   .\scripts\deploy-apigateway.ps1 -Stage dev

param(
    [string]$Stage = "prod"
)

$ErrorActionPreference = "Stop"
$env:PYTHONIOENCODING = "utf-8"   # Force AWS CLI stdout/stderr to UTF-8
$env:PYTHONUTF8       = "1"        # Force UTF-8 for all Python file I/O (fixes charmap on Windows)
$BackendRoot = Join-Path $PSScriptRoot ".."

# -----------------------------------------------------------------------
# Load .env with ${VAR} interpolation support
# -----------------------------------------------------------------------
$EnvPath = Join-Path $BackendRoot ".env"
if (-not (Test-Path $EnvPath)) {
    Write-Error ".env not found at $EnvPath."
    exit 1
}

$EnvVars = @{}
Get-Content $EnvPath | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.*)\s*$") {
        $EnvVars[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}
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

$AppName     = $resolved["APP_NAME"]
$Region      = if ($resolved["AWS_REGION"]) { $resolved["AWS_REGION"] } else { "us-east-1" }
$AwsProfile  = $resolved["AWS_PROFILE"]
$LambdaStack = "$AppName-lambdas-$Stage"
$StackName   = "$AppName-apigateway-$Stage"
$Template    = Join-Path $BackendRoot "templates\apigateway-stack.yaml"

if (-not $AppName) { Write-Error "APP_NAME is not set in .env."; exit 1 }
if (-not $AwsProfile) { Write-Error "AWS_PROFILE is not set in .env."; exit 1 }

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Deploy: API Gateway Stack" -ForegroundColor Cyan
Write-Host " App    : $AppName" -ForegroundColor Cyan
Write-Host " Stack  : $StackName" -ForegroundColor Cyan
Write-Host " Region : $Region" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Read Lambda ARNs from lambda-stack outputs
Write-Host "Reading Lambda ARNs from stack: $LambdaStack ..." -ForegroundColor Yellow

function Get-StackOutput([string]$stack, [string]$key) {
    $val = aws cloudformation describe-stacks `
        --stack-name $stack `
        --region $Region `
        --profile $AwsProfile `
        --query "Stacks[0].Outputs[?OutputKey=='$key'].OutputValue" `
        --output text
    if (-not $val) {
        Write-Error "Could not read $key from $stack. Has deploy-lambdas.ps1 been run?"
        exit 1
    }
    return $val
}

$CreatePatientArn = Get-StackOutput $LambdaStack "CreatePatientFunctionArn"
$GetPatientArn    = Get-StackOutput $LambdaStack "GetPatientFunctionArn"
$GetRecordArn     = Get-StackOutput $LambdaStack "GetRecordFunctionArn"
$CreateRecordArn  = Get-StackOutput $LambdaStack "CreateRecordFunctionArn"

Write-Host "ARNs resolved." -ForegroundColor Green
Write-Host ""
Write-Host "Deploying API Gateway stack..." -ForegroundColor Yellow

aws cloudformation deploy `
    --template-file $Template `
    --stack-name $StackName `
    --region $Region `
    --profile $AwsProfile `
    --parameter-overrides `
        Stage=$Stage `
        AppName=$AppName `
        CreatePatientFunctionArn=$CreatePatientArn `
        GetPatientFunctionArn=$GetPatientArn `
        GetRecordFunctionArn=$GetRecordArn `
        CreateRecordFunctionArn=$CreateRecordArn `
    --capabilities CAPABILITY_IAM `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) { Write-Error "API Gateway stack deployment failed."; exit 1 }

Write-Host ""
Write-Host "API Gateway stack deployed successfully." -ForegroundColor Green
Write-Host ""

aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --profile $AwsProfile `
    --query "Stacks[0].Outputs[*].{Output:OutputKey,Value:OutputValue}" `
    --output table

# Print the actual API key value
$ApiKeyId = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --profile $AwsProfile `
    --query "Stacks[0].Outputs[?OutputKey=='ApiKeyId'].OutputValue" `
    --output text

if ($ApiKeyId) {
    Write-Host ""
    Write-Host "Your x-api-key value:" -ForegroundColor Cyan
    aws apigateway get-api-key --api-key $ApiKeyId --include-value --region $Region --profile $AwsProfile --query "value" --output text
}
