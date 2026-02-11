# validate-synth-xml.ps1
# Validates Synth XML files against XSD schemas

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$XmlFile,

    [Parameter(Mandatory=$false)]
    [string]$SchemaFile
)

$workspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

# Auto-detect schema based on file pattern
if (-not $SchemaFile) {
    if ($XmlFile -like "*\components\*" -or $XmlFile -like "*/components/*") {
        $SchemaFile = Join-Path $workspaceRoot "synth\synth-protocol\docs\schema\synth\component\1.0\component.xsd"
        Write-Host "Auto-detected: Component Schema" -ForegroundColor Cyan
    }
    elseif ($XmlFile -like "*\scenes\*" -or $XmlFile -like "*/scenes/*") {
        $SchemaFile = Join-Path $workspaceRoot "synth\synth-protocol\docs\schema\synth\scene\1.0\scene.xsd"
        Write-Host "Auto-detected: Scene Schema" -ForegroundColor Cyan
    }
    else {
        Write-Error "Could not auto-detect schema. Please specify -SchemaFile parameter."
        Write-Host "Usage: .\validate-synth-xml.ps1 <xml-file> [-SchemaFile <xsd-file>]"
        exit 1
    }
}

# Resolve paths
$XmlFilePath = Resolve-Path $XmlFile -ErrorAction Stop
$SchemaFilePath = Resolve-Path $SchemaFile -ErrorAction Stop

Write-Host ""
Write-Host "Validating Synth XML File" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
Write-Host "XML File: $XmlFilePath"
Write-Host "Schema:   $SchemaFilePath"
Write-Host ""

# Validation using .NET XmlDocument
$xml = New-Object System.Xml.XmlDocument
$xml.Schemas.Add($null, $SchemaFilePath) | Out-Null

$validationErrors = @()
$validationHandler = {
    param($sender, $e)
    $script:validationErrors += $e.Message
}

try {
    $xml.Load($XmlFilePath)
    $xml.Validate($validationHandler)

    if ($validationErrors.Count -eq 0) {
        Write-Host "✓ Validation successful!" -ForegroundColor Green
        Write-Host ""
        exit 0
    }
    else {
        Write-Host "✗ Validation failed with $($validationErrors.Count) error(s):" -ForegroundColor Red
        Write-Host ""
        foreach ($error in $validationErrors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
        Write-Host ""
        exit 1
    }
}
catch {
    Write-Host "✗ XML parsing failed:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
