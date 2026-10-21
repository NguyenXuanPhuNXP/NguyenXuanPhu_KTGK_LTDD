param([string]$ProjectPath = "$PSScriptRoot/../BackEnd/NguyenXuanPhu_KTGK_LTDD/NguyenXuanPhu_KTGK_LTDD")
$ErrorActionPreference = 'Stop'
# Run interactively on your machine; do not paste Gmail secrets into chat.
function Save-Secret([string]$Key, [string]$Value) {
    dotnet user-secrets set $Key $Value --project $ProjectPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Không lưu được $Key" }
}
$gmail = Read-Host 'Gmail gửi OTP'
$appPasswordSecure = Read-Host 'Gmail App Password (ẩn khi nhập)' -AsSecureString
$adminEmail = Read-Host 'Email nhận OTP của quản trị viên'
$adminPasswordSecure = Read-Host 'Mật khẩu admin (8+ ký tự, hoa, thường, số, ký hiệu)' -AsSecureString
$appPassword = [System.Net.NetworkCredential]::new('', $appPasswordSecure).Password.Replace(' ', '')
$adminPassword = [System.Net.NetworkCredential]::new('', $adminPasswordSecure).Password
Save-Secret 'Jwt:Secret' ([Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(48)))
Save-Secret 'Smtp:Host' 'smtp.gmail.com'
Save-Secret 'Smtp:Port' '587'
Save-Secret 'Smtp:EnableSsl' 'true'
Save-Secret 'Smtp:User' $gmail
Save-Secret 'Smtp:From' $gmail
Save-Secret 'Smtp:Password' $appPassword
Save-Secret 'SeedAdmin:Email' $adminEmail
Save-Secret 'SeedAdmin:Password' $adminPassword
$appPassword = $null
$adminPassword = $null
Write-Host 'Đã lưu cấu hình vào .NET User Secrets. Khởi động backend ở môi trường Development.'
