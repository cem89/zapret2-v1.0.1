$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,System.Xaml
. "$PSScriptRoot\zapret2-roblox-common.ps1"

if (-not (Test-ZapretAdmin)) {
  Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  exit
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Zapret2 Roblox Kontrol Merkezi"
        Width="1180"
        Height="820"
        MinWidth="1040"
        MinHeight="720"
        WindowStartupLocation="CenterScreen"
        Background="#F3EFE7"
        FontFamily="Bahnschrift">
  <Grid>
    <Grid.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#F6F0E8" Offset="0"/>
        <GradientStop Color="#E3ECF0" Offset="0.55"/>
        <GradientStop Color="#D6E1D4" Offset="1"/>
      </LinearGradientBrush>
    </Grid.Background>

    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Margin="24,24,24,16" Padding="24" CornerRadius="28" Background="#132A2A">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel>
          <TextBlock Text="Zapret2 Roblox Kontrol Merkezi" FontSize="30" FontWeight="Bold" Foreground="#F7F3EB"/>
          <TextBlock Margin="0,8,0,0" Text="Baslat, durdur, test et ve durumu tek ekrandan izle." FontSize="15" Foreground="#C6D8D3"/>
        </StackPanel>
        <Border Grid.Column="1" x:Name="StatusBadge" Padding="18,10" CornerRadius="999" Background="#B64A4A" VerticalAlignment="Center">
          <TextBlock x:Name="StatusBadgeText" Text="KAPALI" FontSize="15" FontWeight="Bold" Foreground="#FFF7F0"/>
        </Border>
      </Grid>
    </Border>

    <Grid Grid.Row="1" Margin="24,0,24,18">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="360"/>
        <ColumnDefinition Width="18"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <StackPanel Grid.Column="0">
        <Border Margin="0,0,0,16" Padding="20" CornerRadius="24" Background="#FFFDF9">
          <StackPanel>
            <TextBlock Text="Hizli Kontroller" FontSize="22" FontWeight="Bold" Foreground="#193535"/>
            <TextBlock Margin="0,6,0,18" Text="En cok kullanilan islemler burada." FontSize="13" Foreground="#5C7171"/>
            <Button x:Name="StartButton" Height="48" Margin="0,0,0,10" Content="Bypass Baslat" Background="#1F7A6D" Foreground="White" BorderThickness="0" FontSize="16" FontWeight="Bold"/>
            <Button x:Name="StopButton" Height="48" Margin="0,0,0,10" Content="Bypass Durdur" Background="#A14545" Foreground="White" BorderThickness="0" FontSize="16" FontWeight="Bold"/>
            <Button x:Name="TestButton" Height="48" Margin="0,0,0,10" Content="Roblox Erisim Testi" Background="#DAA520" Foreground="#17211E" BorderThickness="0" FontSize="16" FontWeight="Bold"/>
            <Button x:Name="RefreshButton" Height="44" Margin="0,0,0,10" Content="Durumu Yenile" Background="#D7E7E1" Foreground="#193535" BorderThickness="0" FontSize="14" FontWeight="Bold"/>
            <UniformGrid Columns="2" Margin="0,4,0,0">
              <Button x:Name="OpenFolderButton" Margin="0,0,8,0" Height="42" Content="Klasoru Ac" Background="#EDE7DD" Foreground="#193535" BorderThickness="0"/>
              <Button x:Name="OpenLogButton" Margin="8,0,0,0" Height="42" Content="Logu Ac" Background="#EDE7DD" Foreground="#193535" BorderThickness="0"/>
            </UniformGrid>
          </StackPanel>
        </Border>

        <Border Margin="0,0,0,16" Padding="20" CornerRadius="24" Background="#FFFDF9">
          <StackPanel>
            <TextBlock Text="Canli Durum" FontSize="22" FontWeight="Bold" Foreground="#193535"/>
            <TextBlock x:Name="ServiceStateText" Margin="0,14,0,4" FontSize="16" FontWeight="Bold" Foreground="#193535" Text="Servis: kontrol ediliyor"/>
            <TextBlock x:Name="PidText" Margin="0,2,0,2" FontSize="13" Foreground="#5C7171" Text="PID: -"/>
            <TextBlock x:Name="AdminText" Margin="0,2,0,2" FontSize="13" Foreground="#5C7171" Text="Yonetici: -"/>
            <TextBlock x:Name="BinaryText" Margin="0,2,0,2" FontSize="13" Foreground="#5C7171" Text="Binary: -"/>
            <TextBlock x:Name="LastLogText" Margin="0,2,0,0" FontSize="13" Foreground="#5C7171" Text="Son log guncellemesi: -"/>
          </StackPanel>
        </Border>

        <Border Padding="20" CornerRadius="24" Background="#FFFDF9">
          <StackPanel>
            <TextBlock Text="Kisa Notlar" FontSize="22" FontWeight="Bold" Foreground="#193535"/>
            <TextBlock Margin="0,12,0,6" TextWrapping="Wrap" FontSize="13" Foreground="#5C7171"
                       Text="1. Baslat'a bastiktan sonra durum rozetinin YESIL olmasi gerekir."/>
            <TextBlock Margin="0,0,0,6" TextWrapping="Wrap" FontSize="13" Foreground="#5C7171"
                       Text="2. Test bolumu Roblox alan adlarina HTTP baslik erisimi dener."/>
            <TextBlock Margin="0,0,0,0" TextWrapping="Wrap" FontSize="13" Foreground="#5C7171"
                       Text="3. Sorun durumunda log ac butonuyla winws ciktilarini hemen gorebilirsin."/>
          </StackPanel>
        </Border>
      </StackPanel>

      <Grid Grid.Column="2">
        <Grid.RowDefinitions>
          <RowDefinition Height="230"/>
          <RowDefinition Height="18"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Padding="20" CornerRadius="24" Background="#FFFDF9">
          <Grid>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="Erisim Test Sonuclari" FontSize="22" FontWeight="Bold" Foreground="#193535"/>
              <TextBlock x:Name="TestSummaryText" Margin="14,6,0,0" FontSize="13" Foreground="#5C7171" Text="Henuz test calismadi."/>
            </StackPanel>
            <DataGrid x:Name="ResultGrid" Grid.Row="1" Margin="0,16,0,0" AutoGenerateColumns="False" HeadersVisibility="Column" CanUserAddRows="False" IsReadOnly="True" BorderThickness="0" RowBackground="#FFF9F0" AlternatingRowBackground="#F7F7F2">
              <DataGrid.Columns>
                <DataGridTextColumn Header="Durum" Binding="{Binding ResultText}" Width="90"/>
                <DataGridTextColumn Header="Adres" Binding="{Binding Url}" Width="*"/>
                <DataGridTextColumn Header="HTTP" Binding="{Binding Status}" Width="220"/>
              </DataGrid.Columns>
            </DataGrid>
          </Grid>
        </Border>

        <Border Grid.Row="2" Padding="20" CornerRadius="24" Background="#FFFDF9">
          <Grid>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="Canli Log Onizleme" FontSize="22" FontWeight="Bold" Foreground="#193535"/>
              <TextBlock x:Name="LogHintText" Margin="14,6,0,0" FontSize="13" Foreground="#5C7171" Text="Son 30 satir gosteriliyor."/>
            </StackPanel>
            <TextBox x:Name="LogPreviewBox" Grid.Row="1" Margin="0,16,0,0" IsReadOnly="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Background="#122626" Foreground="#DFF7F1" BorderThickness="0" FontFamily="Consolas" FontSize="13" Padding="14"/>
          </Grid>
        </Border>
      </Grid>
    </Grid>

    <Border Grid.Row="2" Margin="24,0,24,24" Padding="18,14" CornerRadius="18" Background="#FFF7EA">
      <TextBlock x:Name="FooterText" FontSize="13" Foreground="#5C7171" Text="Hazir. Bu pencere acikken durum otomatik yenilenir."/>
    </Border>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$StartButton = $window.FindName('StartButton')
$StopButton = $window.FindName('StopButton')
$TestButton = $window.FindName('TestButton')
$RefreshButton = $window.FindName('RefreshButton')
$OpenFolderButton = $window.FindName('OpenFolderButton')
$OpenLogButton = $window.FindName('OpenLogButton')
$ServiceStateText = $window.FindName('ServiceStateText')
$PidText = $window.FindName('PidText')
$AdminText = $window.FindName('AdminText')
$BinaryText = $window.FindName('BinaryText')
$LastLogText = $window.FindName('LastLogText')
$FooterText = $window.FindName('FooterText')
$StatusBadge = $window.FindName('StatusBadge')
$StatusBadgeText = $window.FindName('StatusBadgeText')
$LogPreviewBox = $window.FindName('LogPreviewBox')
$ResultGrid = $window.FindName('ResultGrid')
$TestSummaryText = $window.FindName('TestSummaryText')

function Set-FooterMessage {
  param([string]$Text)
  $FooterText.Text = $Text
}

function Update-UiStatus {
  $status = Get-ZapretStatus

  if ($status.IsRunning) {
    $ServiceStateText.Text = 'Servis: aktif'
    $StatusBadge.Background = [Windows.Media.Brushes]::SeaGreen
    $StatusBadgeText.Text = 'AKTIF'
  } else {
    $ServiceStateText.Text = 'Servis: kapali'
    $StatusBadge.Background = [Windows.Media.Brushes]::IndianRed
    $StatusBadgeText.Text = 'KAPALI'
  }

  $PidText.Text = 'PID: ' + ($(if ($status.ProcessId) { $status.ProcessId } else { '-' }))
  $AdminText.Text = 'Yonetici: ' + ($(if ($status.IsAdmin) { 'Evet' } else { 'Hayir' }))
  $BinaryText.Text = 'Binary: ' + ($(if ($status.WinwsExists) { 'Bulundu' } else { 'Eksik' }))
  $LastLogText.Text = 'Son log guncellemesi: ' + ($(if ($status.LastLogUpdate) { $status.LastLogUpdate.ToString('dd.MM.yyyy HH:mm:ss') } else { '-' }))
  $LogPreviewBox.Text = Get-LatestLogPreview
}

function Invoke-UiAction {
  param(
    [string]$BusyMessage,
    [scriptblock]$Action
  )

  try {
    Set-FooterMessage $BusyMessage
    & $Action
  } catch {
    [System.Windows.MessageBox]::Show($_.Exception.Message, 'Zapret2 Roblox Kontrol Merkezi', 'OK', 'Error') | Out-Null
    Set-FooterMessage ('Hata: ' + $_.Exception.Message)
  } finally {
    Update-UiStatus
  }
}

$StartButton.Add_Click({
  Invoke-UiAction 'Bypass baslatiliyor...' {
    Start-RobloxDpiBypass | Out-Null
    Set-FooterMessage 'Bypass baslatildi.'
  }
})

$StopButton.Add_Click({
  Invoke-UiAction 'Bypass durduruluyor...' {
    if (Stop-RobloxDpiBypass) {
      Set-FooterMessage 'Bypass durduruldu.'
    } else {
      Set-FooterMessage 'Calisan winws2.exe bulunamadi.'
    }
  }
})

$TestButton.Add_Click({
  Invoke-UiAction 'Roblox erisim testi calisiyor...' {
    $results = Invoke-RobloxReachabilityTest | ForEach-Object {
      [pscustomobject]@{
        ResultText = if ($_.Success) { 'OK' } else { 'FAIL' }
        Url = $_.Url
        Status = if ($_.Status) { $_.Status } else { "curl_exit=$($_.ExitCode)" }
        Details = $_.Details
      }
    }

    $ResultGrid.ItemsSource = $results
    $okCount = @($results | Where-Object ResultText -eq 'OK').Count
    $TestSummaryText.Text = "$okCount / $($results.Count) basarili"
    Set-FooterMessage 'Erisim testi tamamlandi.'
  }
})

$RefreshButton.Add_Click({
  Update-UiStatus
  Set-FooterMessage 'Durum yenilendi.'
})

$OpenFolderButton.Add_Click({
  Start-Process explorer.exe (Get-ZapretProjectRoot)
})

$OpenLogButton.Add_Click({
  $paths = Get-ZapretPaths
  if (Test-Path -LiteralPath $paths.LogOut) {
    Start-Process notepad.exe $paths.LogOut
  } else {
    [System.Windows.MessageBox]::Show('Henuz acilabilecek bir log dosyasi yok.', 'Zapret2 Roblox Kontrol Merkezi', 'OK', 'Information') | Out-Null
  }
})

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(3)
$timer.Add_Tick({
  Update-UiStatus
})
$timer.Start()

$window.Add_Closed({
  $timer.Stop()
})

Update-UiStatus
$window.ShowDialog() | Out-Null
