Write-Output "$(Get-Date) Lab Files Clean Up Script"

Get-ChildItem -path "C:\labfiles" -Recurse -Filter ".gitattributes" | Remove-Item -Force -Recurse
Get-ChildItem -path "C:\labfiles" -Recurse -Filter ".gitignore" | Remove-Item -Force -Recurse
Get-ChildItem -path "C:\labfiles" -Recurse -Filter "README.md" | Remove-Item -Force -Recurse
