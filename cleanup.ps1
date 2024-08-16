Write-Output "$(Get-Date) Lab Files Clean Up Script"

Get-ChildItem -path "C:\labfiles" -Recurse -Filter ".gitattributes" -Hidden | Remove-Item -Force -Recurse
Get-ChildItem -path "C:\labfiles" -Recurse -Filter ".gitignore" -Hidden | Remove-Item -Force -Recurse
Get-ChildItem -path "C:\labfiles" -Recurse -Filter "README.md" -Hidden | Remove-Item -Force -Recurse
