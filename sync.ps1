Set-Location "c:\"
Get-ChildItem -path ".\labfiles" -Directory -Recurse -Filter ".git" -Hidden | Remove-Item -Force -Recurse
Get-ChildItem -path ".\labfiles" -Recurse -Filter ".gitignore" -Hidden | Remove-Item -Force -Recurse
Get-ChildItem -path ".\labfiles" -Recurse -Filter "README.md" -Hidden | Remove-Item -Force -Recurse
