# scripts/upload-lambda-artifacts.ps1
# Uploads all built Lambda artifacts from .aws-sam/build to the specified S3 bucket for SAM/CloudFormation deploys.
# Usage:
#   .\scripts\upload-lambda-artifacts.ps1 -Bucket profiler-cdk-bucket

param(
    [Parameter(Mandatory=$true)]
    [string]$Bucket
)

$ErrorActionPreference = "Stop"
$BackendRoot = Join-Path $PSScriptRoot ".."
$BuildDir = Join-Path $BackendRoot ".aws-sam\build"

if (-not (Test-Path $BuildDir)) {
    Write-Error ".aws-sam/build directory not found. Run 'sam build' first."
    exit 1
}

# Find all Lambda zip artifacts in the build directory
$zips = Get-ChildItem -Path $BuildDir -Recurse -Filter "*.zip"
if ($zips.Count -eq 0) {
    Write-Error "No Lambda zip artifacts found in .aws-sam/build. Run 'sam build' first."
    exit 1
}

Write-Host "Uploading Lambda artifacts to S3 bucket: $Bucket" -ForegroundColor Cyan
foreach ($zip in $zips) {
    $key = $zip.FullName.Substring($BuildDir.Length + 1).Replace("\\", "/")
    Write-Host "Uploading $($zip.Name) to s3://$Bucket/$key ..."
    aws s3 cp $zip.FullName "s3://$Bucket/$key"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to upload $($zip.Name) to S3."
        exit 1
    }
}

Write-Host "All Lambda artifacts uploaded successfully." -ForegroundColor Green
