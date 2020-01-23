$fork = "LocalIdentity";
Write-Output "Patching to use the $fork fork...";
$source = "https://raw.githubusercontent.com/$fork/PathOfBuilding/master/manifest.xml";
$dest = "$env:ProgramData\Path of Building\manifest.xml";

$cli = New-Object System.Net.WebClient;
$cli.Headers['User-Agent'] = 'Mozilla/5.0 Powershell';
$cli.DownloadFile($source, $dest)