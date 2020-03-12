$fork = "PathOfBuildingCommunity";
$original = "Openarl";

Write-Output "Patching manifest to use the $fork fork...";

# Where our manifest files are located
$manifestFile = "$env:ProgramData\Path of Building\manifest.xml";
$manifestFileBackup = "$env:ProgramData\Path of Building\manifest_backup.xml";

# Read in our original manifest file
$manifest = New-Object System.Xml.XmlDocument;
$manifest.PreserveWhitespace = $true;
$manifest.Load($manifestFile);

# Save our backup
Copy-Item $manifestFile $manifestFileBackup;

foreach($entry in $manifest.PoBVersion.Source) {
    $src = $entry.url;
    $dst = $entry.url -replace $original, $fork;
    if ($entry.part -eq "program") {
        # We'll force replace this one since some people may be pointing at LocalIdentity repo not PathOfBuildingCommunity
        $dst = "https://raw.githubusercontent.com/$fork/PathOfBuilding/{branch}/";
    }
    Write-Output "Updating $src -> $dst";

    # Update the url to the forked repo
    $entry.url = $dst;
}

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false);
$sw = New-Object System.IO.StreamWriter($manifestFile, $false, $utf8WithoutBom);
$manifest.Save($sw);

Write-Output "Manifest file updated.";
