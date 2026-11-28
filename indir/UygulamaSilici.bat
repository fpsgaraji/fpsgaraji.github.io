@echo off
title Windows Gereksiz Uygulama Temizleyici
rem === TEK DOSYA: PowerShell GUI asagida gomulu. ===
rem Batch kendini yoneticiye yukseltir, gomulu PowerShell kodunu gecici
rem dosyaya cikarir, -STA ile calistirir, sonra siler.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
set "PS=%TEMP%\WinTemizleyici_%RANDOM%%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=[IO.File]::ReadAllText('%~f0'); $i=$f.LastIndexOf('#==PSBODY==#'); [IO.File]::WriteAllText($env:PS, $f.Substring($i+12), (New-Object Text.UTF8Encoding $false))"
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%PS%"
del "%PS%" >nul 2>&1
exit /b
#==PSBODY==#
# Windows Gereksiz Uygulama Temizleyici
# Tek seferlik kucuk arac. Store (Appx) uygulamalarini YALNIZCA gecerli kullanici icin kaldirir.
# Dosyalar diskte kaldigi icin kaldirilanlar "Geri Yukle" ile tekrar aktif edilebilir ya da Store'dan yeniden kurulabilir.
# Cekirdek/sistem uygulamalari korunur (asagidaki ProtectedNames) ve listede gosterilmez.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---- Guvenli katalog: Appx adi -> kullaniciya gosterilecek ad ----
$Catalog = [ordered]@{
  'king.com.CandyCrushSaga'                 = 'Candy Crush Saga'
  'king.com.CandyCrushSodaSaga'             = 'Candy Crush Soda Saga'
  'king.com.BubbleWitch3Saga'               = 'Bubble Witch 3 Saga'
  'Microsoft.MicrosoftSolitaireCollection'  = 'Microsoft Solitaire Collection'
  'Microsoft.BingNews'                      = 'Haberler (Bing)'
  'Microsoft.BingWeather'                   = 'Hava Durumu (Bing)'
  'Microsoft.BingFinance'                   = 'Finans (Bing)'
  'Microsoft.BingSports'                    = 'Spor (Bing)'
  'Microsoft.BingSearch'                    = 'Web Aramasi (Bing)'
  'Clipchamp.Clipchamp'                     = 'Clipchamp Video Duzenleyici'
  'Microsoft.Microsoft3DViewer'             = '3D Viewer'
  'Microsoft.Print3D'                       = 'Print 3D'
  'Microsoft.3DBuilder'                     = '3D Builder'
  'Microsoft.MixedReality.Portal'           = 'Mixed Reality Portal'
  'Microsoft.GetHelp'                       = 'Yardim Al'
  'Microsoft.Getstarted'                    = 'Ipuclari (Get Started)'
  'Microsoft.WindowsFeedbackHub'            = 'Geri Bildirim Merkezi'
  'Microsoft.MicrosoftOfficeHub'            = 'Office (tanitim kisayolu)'
  'Microsoft.Office.OneNote'                = 'OneNote (UWP)'
  'Microsoft.MicrosoftStickyNotes'          = 'Yapiskan Notlar'
  'Microsoft.People'                        = 'Kisiler'
  'Microsoft.Todos'                         = 'Microsoft To Do'
  'Microsoft.PowerAutomateDesktop'          = 'Power Automate'
  'MicrosoftCorporationII.QuickAssist'      = 'Hizli Yardim (Quick Assist)'
  'Microsoft.WindowsMaps'                   = 'Haritalar'
  'Microsoft.Messaging'                     = 'Mesajlar'
  'Microsoft.OneConnect'                    = 'Mobil Plan (OneConnect)'
  'Microsoft.SkypeApp'                      = 'Skype'
  'Microsoft.GroupMe10'                     = 'GroupMe'
  'MicrosoftTeams'                          = 'Teams (tuketici)'
  'MSTeams'                                 = 'Teams (tuketici)'
  'Microsoft.Windows.DevHome'               = 'Dev Home'
  'Microsoft.OutlookForWindows'             = 'Yeni Outlook (tanitim)'
}

# ---- Gelismis modda bile ASLA kaldirilmayacak cekirdek bilesenler (ad icinde gecerse korunur) ----
$ProtectedNames = @(
  'WindowsStore','DesktopAppInstaller','StorePurchaseApp','WinGet',
  'SecHealthUI','Defender','ShellExperienceHost','StartMenuExperienceHost',
  'Windows.Client.CBS','Windows.CloudExperienceHost','AAD.BrokerPlugin','AccountsControl',
  'Windows.Search','Windows.Cortana','UI.Xaml','VCLibs','NET.Native','DirectXRuntime',
  'WindowsTerminal','Paint','Notepad','ScreenSketch','WindowsCalculator','WindowsCamera',
  'Windows.Photos','WindowsSoundRecorder','WindowsNotepad','SecureAssessmentBrowser',
  'Microsoft.UI','Microsoft.WindowsAppRuntime','Microsoft.Winget','Wallet','XboxGamingOverlay',
  'Xbox.TCUI','XboxGameOverlay','XboxIdentityProvider','XboxSpeechToTextOverlay','GamingApp',
  'Microsoft.WebMediaExtensions','Microsoft.HEIFImageExtension','VP9VideoExtensions',
  'WebpImageExtension','RawImageExtension','AV1VideoExtension','HEVCVideoExtension',
  'MPEG2VideoExtension','VCLibs','LanguageExperiencePack','InputApp','LockApp','PeopleExperienceHost',
  'StorePurchase','CapturePicker','ParentalControls','AsyncTextService','CredDialogHost',
  'ECApp','PinningConfirmationDialog','Win32WebViewHost','XGpuEjectDialog','PhoneLink','YourPhone',
  'VideoExtension','VideoExtensions','ImageExtension','ImageExtensions','WinAppRuntime','WindowsAppRuntime',
  'GamingServices','Microsoft.WidgetsPlatformRuntime','Microsoft.Advertising','Microsoft.Services.Store'
)

function Get-InfoList {
  param([bool]$Advanced)
  $pkgs = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object {
    -not $_.IsFramework -and $_.NonRemovable -ne $true -and $_.SignatureKind -ne 'System'
  }
  $out = @()
  foreach ($p in $pkgs) {
    $name = $p.Name
    if ($Advanced) {
      $prot = $false
      foreach ($pn in $ProtectedNames) { if ($name -like "*$pn*") { $prot = $true; break } }
      if ($prot) { continue }
      $disp = if ($Catalog.Contains($name)) { $Catalog[$name] } else { $name }
    } else {
      if (-not $Catalog.Contains($name)) { continue }
      $disp = $Catalog[$name]
    }
    $out += [pscustomobject]@{ Name = $name; Display = $disp; Pfn = $p.PackageFullName; Loc = $p.InstallLocation }
  }
  $out | Sort-Object Display -Unique
}

# ---------------- GUI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Windows Gereksiz Uygulama Temizleyici'
$form.Size = New-Object System.Drawing.Size(640, 620)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)

$head = New-Object System.Windows.Forms.Label
$head.Text = 'Kaldirmak istedigin uygulamalari isaretle'
$head.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
$head.Location = New-Object System.Drawing.Point(18, 14)
$head.Size = New-Object System.Drawing.Size(600, 28)
$form.Controls.Add($head)

$sub = New-Object System.Windows.Forms.Label
$sub.Text = 'Yalnizca senin kullanicindan kaldirilir; cogu Store`dan yeniden kurulabilir. Kamera, Paint, Terminal, Magaza, Defender gibi cekirdek uygulamalar korunur.'
$sub.Location = New-Object System.Drawing.Point(18, 44)
$sub.Size = New-Object System.Drawing.Size(600, 36)
$sub.ForeColor = [System.Drawing.Color]::FromArgb(90, 95, 105)
$form.Controls.Add($sub)

$clb = New-Object System.Windows.Forms.CheckedListBox
$clb.Location = New-Object System.Drawing.Point(18, 90)
$clb.Size = New-Object System.Drawing.Size(600, 380)
$clb.CheckOnClick = $true
$clb.BackColor = [System.Drawing.Color]::White
$clb.IntegralHeight = $false
$form.Controls.Add($clb)

$selAll = New-Object System.Windows.Forms.CheckBox
$selAll.Text = 'Tumunu sec'
$selAll.Location = New-Object System.Drawing.Point(18, 478)
$selAll.Size = New-Object System.Drawing.Size(110, 24)
$form.Controls.Add($selAll)

$adv = New-Object System.Windows.Forms.CheckBox
$adv.Text = 'Gelismis: tum kaldirilabilir uygulamalari goster'
$adv.Location = New-Object System.Drawing.Point(140, 478)
$adv.Size = New-Object System.Drawing.Size(340, 24)
$adv.ForeColor = [System.Drawing.Color]::FromArgb(150, 80, 0)
$form.Controls.Add($adv)

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(18, 508)
$status.Size = New-Object System.Drawing.Size(600, 20)
$status.ForeColor = [System.Drawing.Color]::FromArgb(90, 95, 105)
$form.Controls.Add($status)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = 'Secilenleri Kaldir'
$btnRemove.Location = New-Object System.Drawing.Point(18, 536)
$btnRemove.Size = New-Object System.Drawing.Size(180, 38)
$btnRemove.BackColor = [System.Drawing.Color]::FromArgb(197, 48, 48)
$btnRemove.ForeColor = [System.Drawing.Color]::White
$btnRemove.FlatStyle = 'Flat'
$form.Controls.Add($btnRemove)

$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text = 'Kaldirilanlari Geri Yukle'
$btnRestore.Location = New-Object System.Drawing.Point(210, 536)
$btnRestore.Size = New-Object System.Drawing.Size(200, 38)
$btnRestore.FlatStyle = 'Flat'
$form.Controls.Add($btnRestore)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = 'Yenile'
$btnRefresh.Location = New-Object System.Drawing.Point(530, 536)
$btnRefresh.Size = New-Object System.Drawing.Size(88, 38)
$btnRefresh.FlatStyle = 'Flat'
$form.Controls.Add($btnRefresh)

$script:Items = @()

function Refresh-List {
  $clb.Items.Clear()
  $selAll.Checked = $false
  $status.Text = 'Taraniyor...'
  $form.Refresh()
  $script:Items = @(Get-InfoList -Advanced:$adv.Checked)
  foreach ($it in $script:Items) { [void]$clb.Items.Add($it.Display, $false) }
  if ($script:Items.Count -eq 0) {
    $status.Text = 'Kaldirilabilecek uygulama bulunamadi. Sistem zaten temiz gorunuyor.'
  } else {
    $status.Text = "$($script:Items.Count) uygulama listelendi."
  }
}

$selAll.Add_Click({ for ($i=0; $i -lt $clb.Items.Count; $i++) { $clb.SetItemChecked($i, $selAll.Checked) } })
$adv.Add_Click({
  if ($adv.Checked) {
    [System.Windows.Forms.MessageBox]::Show('Gelismis mod tum kaldirilabilir uygulamalari gosterir. Ne oldugunu bilmedigin bir seyi kaldirma; cekirdek bilesenler yine de gizli tutulur.','Gelismis mod','OK','Warning') | Out-Null
  }
  Refresh-List
})
$btnRefresh.Add_Click({ Refresh-List })

$btnRemove.Add_Click({
  $chosen = @()
  for ($i=0; $i -lt $clb.Items.Count; $i++) { if ($clb.GetItemChecked($i)) { $chosen += $script:Items[$i] } }
  if ($chosen.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('Once kaldirmak istediklerini isaretle.','Secim yok','OK','Information') | Out-Null; return }
  $r = [System.Windows.Forms.MessageBox]::Show("$($chosen.Count) uygulama kaldirilsin mi? (Yalnizca bu kullanicidan kaldirilir.)",'Onay','YesNo','Warning')
  if ($r -ne 'Yes') { return }
  $ok = 0; $fail = 0
  foreach ($it in $chosen) {
    $status.Text = "Kaldiriliyor: $($it.Display)"; $form.Refresh()
    try { Remove-AppxPackage -Package $it.Pfn -ErrorAction Stop; $ok++ }
    catch { $fail++ }
  }
  [System.Windows.Forms.MessageBox]::Show("$ok uygulama kaldirildi$(if($fail){"; $fail tanesi kaldirilamadi"})."," Bitti",'OK','Information') | Out-Null
  Refresh-List
})

$btnRestore.Add_Click({
  $status.Text = 'Geri yuklenebilecekler taraniyor...'; $form.Refresh()
  $all = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $Catalog.Contains($_.Name) }
  $cur = (Get-AppxPackage -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
  $restored = 0; $failed = 0; $any = $false
  foreach ($p in $all) {
    if ($cur -contains $p.Name) { continue }
    $any = $true
    $mani = Join-Path $p.InstallLocation 'AppxManifest.xml'
    if (-not (Test-Path $mani)) { $failed++; continue }
    try { Add-AppxPackage -DisableDevelopmentMode -Register $mani -ErrorAction Stop; $restored++ }
    catch { $failed++ }
  }
  if (-not $any) { [System.Windows.Forms.MessageBox]::Show('Geri yuklenecek (daha once kaldirilmis) katalog uygulamasi bulunamadi.','Geri Yukle','OK','Information') | Out-Null }
  else { [System.Windows.Forms.MessageBox]::Show("$restored uygulama geri yuklendi$(if($failed){"; $failed tanesi yuklenemedi (Store`dan kurman gerekebilir)"})." ,'Geri Yukle','OK','Information') | Out-Null }
  Refresh-List
})

Refresh-List
[void]$form.ShowDialog()
