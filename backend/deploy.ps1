# deploy.ps1 — Master deploy script
# Runs all three stacks in the correct order:
#   1. dynamodb-stack   — creates DynamoDB tables
#   2. lambda-stack     — builds and deploys Lambda functions
#   3. apigateway-stack — creates API Gateway and links it to the Lambdas
#
# Usage:
#   .\deploy.ps1                     # deploy all stacks to prod
#   .\deploy.ps1 -Stage dev          # deploy all stacks to dev
#   .\deploy.ps1 -Stack dynamodb     # deploy only the DynamoDB stack
#   .\deploy.ps1 -Stack lambdas      # deploy only the Lambda stack
#   .\deploy.ps1 -Stack apigateway   # deploy only the API Gateway stack
#   .\deploy.ps1 -Stack lambdas -Guided   # first-time SAM interactive setup

param(
    [string]$Stage = "prod",

    [ValidateSet("all", "dynamodb", "lambdas", "apigateway")]
    [string]$Stack = "all",

    [switch]$Guided
)

$ErrorActionPreference = "Stop"
$ScriptsDir = Join-Path $PSScriptRoot "scripts"

function Run-Script([string]$script, [string[]]$extraArgs) {
    $path = Join-Path $ScriptsDir $script
    Write-Host ""
    Write-Host ">> Running: $script" -ForegroundColor Magenta
    & $path -Stage $Stage @extraArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$script failed. Stopping."
        exit 1
    }
}

$GuidedArg = if ($Guided) { @("-Guided") } else { @() }

switch ($Stack) {
    "dynamodb"   { Run-Script "deploy-dynamodb.ps1"   @() }
    "lambdas"    { Run-Script "deploy-lambdas.ps1"    $GuidedArg }
    "apigateway" { Run-Script "deploy-apigateway.ps1" @() }
    "all" {
        Run-Script "deploy-dynamodb.ps1"   @()
        Run-Script "deploy-lambdas.ps1"    $GuidedArg
        Run-Script "deploy-apigateway.ps1" @()
    }
}

Write-Host ""
Write-Host "All done!" -ForegroundColor Green
