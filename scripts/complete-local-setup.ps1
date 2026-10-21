param(
    [Parameter(Mandatory = $true)][string]$AdminEmail,
    [string]$ProjectPath = "$PSScriptRoot/../BackEnd/NguyenXuanPhu_KTGK_LTDD/NguyenXuanPhu_KTGK_LTDD"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Hoàn tất MVP điểm danh'
$form.ClientSize = New-Object System.Drawing.Size(540, 400)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.TopMost = $true

function Add-Field([string]$Label, [int]$Y, [string]$Value, [bool]$Secret) {
    $caption = New-Object System.Windows.Forms.Label
    $caption.Text = $Label
    $caption.Location = New-Object System.Drawing.Point(20, $Y)
    $caption.Size = New-Object System.Drawing.Size(500, 22)
    $form.Controls.Add($caption)
    $input = New-Object System.Windows.Forms.TextBox
    $input.Location = New-Object System.Drawing.Point(20, ($Y + 24))
    $input.Size = New-Object System.Drawing.Size(500, 26)
    $input.Text = $Value
    $input.UseSystemPasswordChar = $Secret
    $form.Controls.Add($input)
    return $input
}
$senderBox = Add-Field 'Gmail dùng để gửi OTP' 15 $AdminEmail $false
$appPasswordBox = Add-Field 'App Password Gmail (không phải mật khẩu đăng nhập Gmail)' 80 '' $true
$adminBox = Add-Field 'Email tài khoản quản trị viên' 145 $AdminEmail $false
$adminBox.ReadOnly = $true
$passwordBox = Add-Field 'Mật khẩu admin (8+ ký tự, hoa, thường, số, ký hiệu)' 210 '' $true
$notice = New-Object System.Windows.Forms.Label
$notice.Text = 'Chỉ lưu vào .NET User Secrets trên máy; không gửi mật khẩu vào chat.'
$notice.Location = New-Object System.Drawing.Point(20, 280)
$notice.Size = New-Object System.Drawing.Size(500, 40)
$form.Controls.Add($notice)
$save = New-Object System.Windows.Forms.Button
$save.Text = 'Lưu và tiếp tục chạy MVP'
$save.Location = New-Object System.Drawing.Point(250, 335)
$save.Size = New-Object System.Drawing.Size(270, 42)
$form.Controls.Add($save)
$form.AcceptButton = $save
$save.Add_Click({
    try {
        $address = $senderBox.Text.Trim()
        $appPassword = $appPasswordBox.Text.Replace(' ', '').Trim()
        $adminPassword = $passwordBox.Text
        if ($address -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { throw 'Email Gmail chưa hợp lệ.' }
        if ($appPassword.Length -ne 16) { throw 'App Password Gmail phải gồm 16 ký tự (bỏ khoảng trắng).' }
        if ($adminPassword.Length -lt 8 -or $adminPassword -cnotmatch '[A-Z]' -or $adminPassword -cnotmatch '[a-z]' -or $adminPassword -notmatch '[0-9]' -or $adminPassword -notmatch '[^a-zA-Z0-9]') { throw 'Mật khẩu admin cần ít nhất 8 ký tự, có hoa, thường, số và ký hiệu.' }
        $save.Enabled = $false
        $notice.Text = 'Đang lưu cấu hình trên máy...'
        $form.Refresh()
        $values = @{
            'Smtp:Host' = 'smtp.gmail.com'; 'Smtp:Port' = '587'; 'Smtp:EnableSsl' = 'true';
            'Smtp:User' = $address; 'Smtp:From' = $address; 'Smtp:Password' = $appPassword;
            'SeedAdmin:Email' = $adminBox.Text.Trim(); 'SeedAdmin:Password' = $adminPassword
        }
        # Pass settings over standard input, avoiding passwords in command arguments.
        $start = New-Object System.Diagnostics.ProcessStartInfo
        $start.FileName = 'dotnet'
        $start.ArgumentList.Add('user-secrets')
        $start.ArgumentList.Add('set')
        $start.ArgumentList.Add('--project')
        $start.ArgumentList.Add([System.IO.Path]::GetFullPath($ProjectPath))
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardInput = $true
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        $process = [System.Diagnostics.Process]::Start($start)
        $process.StandardInput.Write(($values | ConvertTo-Json -Compress))
        $process.StandardInput.Close()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw 'Không lưu được User Secrets. Hãy giữ hộp thoại và thử lại.' }
        $process.Dispose()
        $appPasswordBox.Clear()
        $passwordBox.Clear()
        $values.Clear()
        $appPassword = $null
        $adminPassword = $null
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    } catch {
        $notice.Text = $_.Exception.Message
        $save.Enabled = $true
    }
})
[void]$form.ShowDialog()
$form.Dispose()
