param([Parameter(Mandatory=$true)][string]$BinDir,[Parameter(Mandatory=$true)][string]$OutDir,
 [string]$Obfuscar='D:\lisp\BHT\build-tools\obfuscar\2.2.50\tools\Obfuscar.Console.exe',
 [string]$AcadDir='D:\AutoCAD 2024')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$out=[IO.Path]::GetFullPath($OutDir);$bin=[IO.Path]::GetFullPath($BinDir)
if(!$out.StartsWith([IO.Path]::GetFullPath((Join-Path $root 'build'))+'\',[StringComparison]::OrdinalIgnoreCase) -or $out -eq $bin){throw 'Output must be a separate build directory'}
if(!(Test-Path -LiteralPath $Obfuscar)){throw 'Install pinned Obfuscar 2.2.50; see docs/PROTECTED_BUILD.md'}
New-Item -ItemType Directory -Force $out | Out-Null
$private=Join-Path (Split-Path -Parent $out) 'protection-private'
New-Item -ItemType Directory -Force $private | Out-Null
function X([string]$value){[Security.SecurityElement]::Escape($value)}
$config=@"
<Obfuscator>
 <Var name="InPath" value="$(X $bin)" />
 <Var name="OutPath" value="$(X $out)" />
 <Var name="LogFile" value="$(X (Join-Path $private 'Mapping.xml'))" />
 <Var name="XmlMapping" value="true" />
 <Var name="KeepPublicApi" value="true" />
 <Var name="HidePrivateApi" value="true" />
 <Var name="HideStrings" value="false" />
 <Var name="RenameProperties" value="false" />
 <Var name="RenameEvents" value="false" />
 <Var name="ReuseNames" value="false" />
 <AssemblySearchPath path="$(X $AcadDir)" />
 <Module file="$(X (Join-Path $bin 'BHT.Core.dll'))" />
 <Module file="$(X (Join-Path $bin 'BHT.Bridge.dll'))" />
</Obfuscator>
"@
$path=Join-Path $private 'obfuscar.xml';[IO.File]::WriteAllText($path,$config,[Text.UTF8Encoding]::new($true))
& $Obfuscar $path
if($LASTEXITCODE -ne 0){throw 'Obfuscation failed'}
# Palette is excluded: modeless UI, resource names and reflection need a separate policy.
Copy-Item -LiteralPath (Join-Path $bin 'BHT.Palette.dll') -Destination $out -Force
foreach($name in @('BHT.Core.dll','BHT.Bridge.dll')){
 if(!(Test-Path -LiteralPath (Join-Path $out $name))){throw "Missing $name"}
 if((Get-FileHash (Join-Path $out $name)).Hash -eq (Get-FileHash (Join-Path $bin $name)).Hash){throw "Unchanged obfuscation output $name"}
}
Write-Host 'Protected Core/Bridge; Palette preserved; mapping remains private.'

$hashes=@{}
foreach($name in @('BHT.Core.dll','BHT.Bridge.dll','BHT.Palette.dll')){$hashes[$name]=(Get-FileHash (Join-Path $out $name)).Hash}
@{tool='Obfuscar 2.2.50';scope='Core and Bridge nonpublic names; Palette unchanged';hashes=$hashes} | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $out 'protection.json') -Encoding UTF8