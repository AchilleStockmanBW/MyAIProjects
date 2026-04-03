<#
.SYNOPSIS
    Generates a BrightWolves credential slide from the template PPTX.

.PARAMETER ConfigFile
    Path to a JSON configuration file with the credential content.

.EXAMPLE
    .\Generate-Credential.ps1 -ConfigFile "C:\Temp\credential-config.json"

JSON config schema:
{
  "layout":               "combined" | "split",
  "output_path":          "C:\\path\\Credential - ClientName - Title.pptx",
  "title":                "Lead commercial due diligence for ...",
  "subtitle":             "",                          // optional
  "capability":           "Strategy",
  "context_approach_text":"Opening sentence.\n- Bullet 1\n- Bullet 2\nBW delivered ...",  // combined only
  "context_text":         "Context paragraph ...",    // split only
  "approach_text":        "- Bullet 1\n- Bullet 2\nBW delivered ...",  // split only
  "results_text":         "- Result 1\n- Result 2",
  "year":                 "2024",
  "duration":             "3 months",
  "topic":                "Sustainability",
  "subcapability":        ""
}
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

# ── Read config ───────────────────────────────────────────────────────────────
$config = Get-Content $ConfigFile -Encoding UTF8 | ConvertFrom-Json

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputPath   = $config.output_path

# Allow config to override the template path (useful if the main template is locked by OneDrive/PowerPoint)
if ($config.template_override -and (Test-Path -LiteralPath $config.template_override)) {
    $templatePath = $config.template_override
} else {
    $templatePath = Join-Path $scriptDir '[BW] - Credential - Template.pptx'
}

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Template not found: $templatePath"
}

# Copy template to output
$resolvedTemplate = (Resolve-Path -LiteralPath $templatePath).Path
[System.IO.File]::Copy($resolvedTemplate, $outputPath, $true)

# ── Archive helpers ───────────────────────────────────────────────────────────
function Read-ArchiveEntry($archive, $path) {
    $entry = $archive.GetEntry($path)
    if (-not $entry) { return $null }
    $stream = $entry.Open()
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
    $content = $reader.ReadToEnd()
    $reader.Close()
    return $content
}

function Update-ArchiveEntry($archive, $path, $content) {
    $entry = $archive.GetEntry($path)
    if ($entry) { $entry.Delete() }
    $newEntry = $archive.CreateEntry($path, [System.IO.Compression.CompressionLevel]::Optimal)
    $stream = $newEntry.Open()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
}

function Remove-ArchiveEntry($archive, $path) {
    $entry = $archive.GetEntry($path)
    if ($entry) { $entry.Delete() }
}

# ── XML helpers ───────────────────────────────────────────────────────────────
function Escape-Xml([string]$text) {
    return $text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

# Replace <a:t> content inside the shape identified by cNvPr id
function Replace-SimpleText($xml, [string]$shapeId, [string]$placeholder, [string]$replacement) {
    $marker  = 'cNvPr id="' + $shapeId + '"'
    $mIdx    = $xml.IndexOf($marker)
    if ($mIdx -lt 0) { return $xml }

    $spStart = $xml.LastIndexOf('<p:sp>', $mIdx)
    $spEnd   = $xml.IndexOf('</p:sp>', $mIdx) + 7
    $sp      = $xml.Substring($spStart, $spEnd - $spStart)

    $tag     = '<a:t>' + $placeholder + '</a:t>'
    $newSp   = $sp.Replace($tag, '<a:t>' + $replacement + '</a:t>')

    return $xml.Substring(0, $spStart) + $newSp + $xml.Substring($spEnd)
}

# Replace the entire <a:p> paragraph that contains placeholder with newParasXml
function Replace-ParagraphContent($xml, [string]$shapeId, [string]$placeholder, [string]$newParasXml) {
    $marker  = 'cNvPr id="' + $shapeId + '"'
    $mIdx    = $xml.IndexOf($marker)
    if ($mIdx -lt 0) { return $xml }

    $spStart = $xml.LastIndexOf('<p:sp>', $mIdx)
    $spEnd   = $xml.IndexOf('</p:sp>', $mIdx) + 7
    $sp      = $xml.Substring($spStart, $spEnd - $spStart)

    $placeholderTag = '<a:t>' + $placeholder + '</a:t>'
    $plIdx = $sp.IndexOf($placeholderTag)
    if ($plIdx -lt 0) { return $xml }

    $pStart  = $sp.LastIndexOf('<a:p>', $plIdx)
    $pEnd    = $sp.IndexOf('</a:p>', $plIdx) + 6
    $newSp   = $sp.Substring(0, $pStart) + $newParasXml + $sp.Substring($pEnd)

    return $xml.Substring(0, $spStart) + $newSp + $xml.Substring($spEnd)
}

# Build body paragraph XML (Context & Approach area — dark text on light bg)
function New-BodyParagraph([string]$text, [bool]$isBullet) {
    $t    = Escape-Xml $text
    $rPr  = '<a:rPr lang="en-GB" sz="1400" b="0" dirty="0"><a:solidFill><a:schemeClr val="tx1"/></a:solidFill></a:rPr>'
    if ($isBullet) {
        return '<a:p><a:pPr marL="342900" indent="-342900" algn="just"><a:lnSpc><a:spcPct val="100000"/></a:lnSpc><a:spcBef><a:spcPts val="0"/></a:spcBef><a:spcAft><a:spcPts val="200"/></a:spcAft><a:buFont typeface="Arial" panose="020B0604020202020204" pitchFamily="34" charset="0"/><a:buChar char="-"/></a:pPr><a:r>' + $rPr + '<a:t>' + $t + '</a:t></a:r></a:p>'
    } else {
        return '<a:p><a:pPr marL="0" marR="0" indent="0" algn="just"><a:lnSpc><a:spcPct val="100000"/></a:lnSpc><a:spcBef><a:spcPts val="0"/></a:spcBef><a:spcAft><a:spcPts val="200"/></a:spcAft><a:buNone/></a:pPr><a:r>' + $rPr + '<a:t>' + $t + '</a:t></a:r></a:p>'
    }
}

# Build results paragraph XML (white text on dark bg)
function New-ResultsParagraph([string]$text) {
    $t   = Escape-Xml $text
    $rPr = '<a:rPr lang="en-US" sz="1400" dirty="0"><a:latin typeface="Arial" panose="020B0604020202020204" pitchFamily="34" charset="0"/><a:cs typeface="Arial" panose="020B0604020202020204" pitchFamily="34" charset="0"/></a:rPr>'
    return '<a:p><a:pPr marL="285750" indent="-285750" algn="l"><a:lnSpc><a:spcPct val="100000"/></a:lnSpc><a:spcBef><a:spcPts val="0"/></a:spcBef><a:spcAft><a:spcPts val="400"/></a:spcAft><a:buFont typeface="Arial" panose="020B0604020202020204" pitchFamily="34" charset="0"/><a:buChar char="-"/></a:pPr><a:r>' + $rPr + '<a:t>' + $t + '</a:t></a:r></a:p>'
}

# Parse text lines into paragraph XML
function Convert-ToBodyXml([string]$text) {
    $paras = @()
    foreach ($line in ($text -split "`n")) {
        $l = $line.Trim()
        if ($l -match '^-\s+(.+)$') {
            $paras += New-BodyParagraph $Matches[1] $true
        } elseif ($l -ne '') {
            $paras += New-BodyParagraph $l $false
        }
    }
    return $paras -join ''
}

function Convert-ToResultsXml([string]$text) {
    $paras = @()
    foreach ($line in ($text -split "`n")) {
        $l = $line.Trim()
        if ($l -match '^-\s+(.+)$') {
            $paras += New-ResultsParagraph $Matches[1]
        } elseif ($l -ne '') {
            $paras += New-ResultsParagraph $l
        }
    }
    return $paras -join ''
}

# ── Fill table cell in slide 3 ────────────────────────────────────────────────
# Finds the row whose first cell matches $label, then replaces [text] in that row with $value.
# Template uses [text] as placeholder in value cells and
# [LEAVE FREE FOR CONSULTANT TO COMPLETE] for cells Claude should not touch.
function Set-TableCell($xml, [string]$label, [string]$value) {
    $escapedVal = Escape-Xml $value
    $rows = [regex]::Matches($xml, '(?s)<a:tr\b[^>]*>.*?</a:tr>')
    foreach ($row in $rows) {
        # Check if first cell contains our label
        $cells = [regex]::Matches($row.Value, '(?s)<a:tc>.*?</a:tc>')
        if ($cells.Count -lt 2) { continue }
        $firstCellText = ([regex]::Matches($cells[0].Value, '<a:t[^>]*>([^<]*)</a:t>') |
                          ForEach-Object { $_.Groups[1].Value }) -join ''
        if ($firstCellText.Trim() -ne $label) { continue }

        # Replace [text] placeholder in this row only
        $newRow = $row.Value.Replace('<a:t>[text]</a:t>', '<a:t>' + $escapedVal + '</a:t>')
        return $xml.Replace($row.Value, $newRow)
    }
    return $xml
}

# ── Open archive and modify ───────────────────────────────────────────────────
$archive = [System.IO.Compression.ZipFile]::Open($outputPath, 'Update')

try {
    $layout = $config.layout.ToLower()

    # ── Step 1: Remove the unused layout slide ────────────────────────────────
    if ($layout -eq 'combined') {
        # Remove slide2 (split layout) and its companion notes slide
        Remove-ArchiveEntry $archive 'ppt/slides/slide2.xml'
        Remove-ArchiveEntry $archive 'ppt/slides/_rels/slide2.xml.rels'
        Remove-ArchiveEntry $archive 'ppt/notesSlides/notesSlide2.xml'
        Remove-ArchiveEntry $archive 'ppt/notesSlides/_rels/notesSlide2.xml.rels'

        $pres = Read-ArchiveEntry $archive 'ppt/presentation.xml'
        $pres = $pres.Replace('<p:sldId id="2147472811" r:id="rId6"/>', '')
        Update-ArchiveEntry $archive 'ppt/presentation.xml' $pres

        $rels = Read-ArchiveEntry $archive 'ppt/_rels/presentation.xml.rels'
        $rels = [regex]::Replace($rels, '<Relationship Id="rId6"[^/]*/>', '')
        Update-ArchiveEntry $archive 'ppt/_rels/presentation.xml.rels' $rels

        $ct = Read-ArchiveEntry $archive '[Content_Types].xml'
        $ct = $ct.Replace('<Override PartName="/ppt/slides/slide2.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>', '')
        $ct = $ct.Replace('<Override PartName="/ppt/notesSlides/notesSlide2.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml"/>', '')
        Update-ArchiveEntry $archive '[Content_Types].xml' $ct

    } else {
        # Remove slide1 (combined layout) and its companion notes slide
        Remove-ArchiveEntry $archive 'ppt/slides/slide1.xml'
        Remove-ArchiveEntry $archive 'ppt/slides/_rels/slide1.xml.rels'
        Remove-ArchiveEntry $archive 'ppt/notesSlides/notesSlide1.xml'
        Remove-ArchiveEntry $archive 'ppt/notesSlides/_rels/notesSlide1.xml.rels'

        $pres = Read-ArchiveEntry $archive 'ppt/presentation.xml'
        $pres = $pres.Replace('<p:sldId id="2147472807" r:id="rId5"/>', '')
        Update-ArchiveEntry $archive 'ppt/presentation.xml' $pres

        $rels = Read-ArchiveEntry $archive 'ppt/_rels/presentation.xml.rels'
        $rels = [regex]::Replace($rels, '<Relationship Id="rId5"[^/]*/>', '')
        Update-ArchiveEntry $archive 'ppt/_rels/presentation.xml.rels' $rels

        $ct = Read-ArchiveEntry $archive '[Content_Types].xml'
        $ct = $ct.Replace('<Override PartName="/ppt/slides/slide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>', '')
        $ct = $ct.Replace('<Override PartName="/ppt/notesSlides/notesSlide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml"/>', '')
        Update-ArchiveEntry $archive '[Content_Types].xml' $ct
    }

    # ── Step 2: Fill credential slide ─────────────────────────────────────────
    $titleXml      = Escape-Xml $config.title
    $subtitleXml   = if ($config.subtitle) { Escape-Xml $config.subtitle } else { '' }
    $capabilityXml = if ($config.capability) { Escape-Xml $config.capability } else { '' }

    if ($layout -eq 'combined') {
        $slidePath = 'ppt/slides/slide1.xml'
        $slide = Read-ArchiveEntry $archive $slidePath

        # Title (shape id=6)
        $slide = Replace-SimpleText $slide '6' '[TITLE]' $titleXml

        # Subtitle (shape id=16) — if provided, replace existing empty text or leave
        if ($subtitleXml) {
            $slide = $slide.Replace('<a:t></a:t>', '<a:t>' + $subtitleXml + '</a:t>')
        }

        # Capability (shape id=3)
        $slide = Replace-SimpleText $slide '3' 'Capability' $capabilityXml

        # Context & Approach body (shape id=7, placeholder "[Text]")
        $bodyXml = Convert-ToBodyXml $config.context_approach_text
        $slide = Replace-ParagraphContent $slide '7' '[Text]' $bodyXml

        # Results (shape id=24, placeholder "[Text]:")
        $resultsXml = Convert-ToResultsXml $config.results_text
        $slide = Replace-ParagraphContent $slide '24' '[Text]:' $resultsXml

        Update-ArchiveEntry $archive $slidePath $slide

    } else {
        # Split layout uses slide2.xml
        $slidePath = 'ppt/slides/slide2.xml'
        $slide = Read-ArchiveEntry $archive $slidePath

        # Title (shape id=3)
        $slide = Replace-SimpleText $slide '3' '[TITLE]' $titleXml

        # Capability (shape id=12)
        $slide = Replace-SimpleText $slide '12' 'Capability' $capabilityXml

        # Context body (shape id=7, placeholder "[Text]")
        $contextXml = Convert-ToBodyXml $config.context_text
        $slide = Replace-ParagraphContent $slide '7' '[Text]' $contextXml

        # Approach body (shape id=8, placeholder "[Text]")
        $approachXml = Convert-ToBodyXml $config.approach_text
        $slide = Replace-ParagraphContent $slide '8' '[Text]' $approachXml

        # Results (shape id=24, placeholder "[Text]")
        $resultsXml = Convert-ToResultsXml $config.results_text
        $slide = Replace-ParagraphContent $slide '24' '[Text]' $resultsXml

        Update-ArchiveEntry $archive $slidePath $slide
    }

    # ── Step 3: Fill slide 3 metadata ─────────────────────────────────────────
    $slide3 = Read-ArchiveEntry $archive 'ppt/slides/slide3.xml'

    # Project Info table
    if ($config.year)          { $slide3 = Set-TableCell $slide3 'Year'          $config.year }
    if ($config.duration)      { $slide3 = Set-TableCell $slide3 'Duration'      $config.duration }

    # Company information table
    if ($config.sector)        { $slide3 = Set-TableCell $slide3 'Sector'        $config.sector }
    if ($config.industry)      { $slide3 = Set-TableCell $slide3 'Industry'      $config.industry }
    if ($config.location)      { $slide3 = Set-TableCell $slide3 'Location'      $config.location }
    if ($config.activity)      { $slide3 = Set-TableCell $slide3 'Activity'      $config.activity }

    # Project Classification table
    if ($config.topic)         { $slide3 = Set-TableCell $slide3 'Topic'         $config.topic }
    if ($config.capability)    { $slide3 = Set-TableCell $slide3 'Capability'    $config.capability }
    if ($config.subcapability) { $slide3 = Set-TableCell $slide3 'Subcapability' $config.subcapability }

    # Clean up any remaining [text] placeholders (fields not provided) with empty string
    $slide3 = $slide3.Replace('<a:t>[text]</a:t>', '<a:t></a:t>')

    Update-ArchiveEntry $archive 'ppt/slides/slide3.xml' $slide3

} finally {
    $archive.Dispose()
}

Write-Host "Credential slide saved to: $outputPath"
