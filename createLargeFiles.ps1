$path = "\\10.174.76.135\ansibleshare\14-East\testfile.txt"
$file = [io.file]::Create($path)
$file.SetLength(1gb)
$file.Close()
# Get-Item $path