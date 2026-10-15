<#
.SYNOPSIS
    Deploys a virtual machine to VMware vSphere.

.DESCRIPTION
    Provides a graphical interface for configuring and creating a powered-off
    virtual machine with the selected guest OS, compute resources, disks, and
    optional ISO installation media.

.NOTES
    Author  : Badrane DERBAZI
    Email   : derbassi@gmail.com
    Version : 2.0.0
    Date    : 2026-10-15
#>

Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

#region Variables
$iconPath    = "iconpath\DeployVM.png"  # Change this to the path of your icon file
$windowsList = @("Windows 10", "Windows 11", "Windows 2016", "Windows 2019", "Windows 2022", "Windows 2025")
$linuxList   = @("Ubuntu 20", "Ubuntu 21", "Ubuntu 22", "Debian 10", "Debian 11", "Debian 12", "Debian 15", "Suse 15", "OpenSuse Leap 42", "OpenSuse Leap 15", "Red Hat 7", "Red Hat 8", "Red Hat 9", "Cent OS 7", "Cent OS 8", "Cent OS 9 Stream", "Oracle Linux 7", "Oracle Linux 8", "Oracle Linux 9", "Fedora 36", "Fedora 37", "Fedora 38")
$maxDisks    = 15   # one SCSI controller = 15 usable slots
#endregion Variables

#region Guest OS tables
# Guest OS identifiers (VirtualMachineGuestOsIdentifier) used by vSphere when creating the VM.
$guestIdBySelection = @{
    "Windows|Windows 10"       = "windows9_64Guest"
    "Windows|Windows 11"       = "windows11_64Guest"
    "Windows|Windows 2016"     = "windows9Server64Guest"
    "Windows|Windows 2019"     = "windows2019srv_64Guest"
    "Windows|Windows 2022"     = "windows2019srvNext_64Guest"
    "Windows|Windows 2025"     = "windows2022srvNext_64Guest"
    "Linux|Ubuntu 20"          = "ubuntu64Guest"
    "Linux|Ubuntu 21"          = "ubuntu64Guest"
    "Linux|Ubuntu 22"          = "ubuntu64Guest"
    "Linux|Debian 10"          = "debian10_64Guest"
    "Linux|Debian 11"          = "debian11_64Guest"
    "Linux|Debian 12"          = "debian12_64Guest"
    "Linux|Debian 15"          = "otherLinux64Guest"
    "Linux|Suse 15"            = "sles15_64Guest"
    "Linux|OpenSuse Leap 42"   = "opensuse64Guest"
    "Linux|OpenSuse Leap 15"   = "opensuse64Guest"
    "Linux|Red Hat 7"          = "rhel7_64Guest"
    "Linux|Red Hat 8"          = "rhel8_64Guest"
    "Linux|Red Hat 9"          = "rhel9_64Guest"
    "Linux|Cent OS 7"          = "centos7_64Guest"
    "Linux|Cent OS 8"          = "centos8_64Guest"
    "Linux|Cent OS 9 Stream"   = "centos9_64Guest"
    "Linux|Oracle Linux 7"     = "oracleLinux7_64Guest"
    "Linux|Oracle Linux 8"     = "oracleLinux8_64Guest"
    "Linux|Oracle Linux 9"     = "oracleLinux9_64Guest"
    "Linux|Fedora 36"          = "fedora64Guest"
    "Linux|Fedora 37"          = "fedora64Guest"
    "Linux|Fedora 38"          = "fedora64Guest"
}
$guestIdFallbacksBySelection = @{
    "Windows|Windows 10"   = @("windows8_1_64Guest", "windows8_64Guest")
    "Windows|Windows 11"   = @("windows9_64Guest", "windows8_1_64Guest")
    "Windows|Windows 2016" = @("windows2019srv_64Guest", "windows2012srv_64Guest", "windows9_64Guest")
    "Windows|Windows 2019" = @("windows9Server64Guest", "windows2012srv_64Guest", "windows9_64Guest")
    "Windows|Windows 2022" = @("windows2019srv_64Guest", "windows9Server64Guest", "windows9_64Guest")
    "Windows|Windows 2025" = @("windows2019srvNext_64Guest", "windows2019srv_64Guest", "windows9Server64Guest", "windows9_64Guest")
    "Linux|Cent OS 9 Stream" = @("centos8_64Guest", "centos7_64Guest")
}
# Generic fallbacks for any Linux selection that has no specific fallback or whose profile is missing.
$linuxGenericFallbacks = @("other5xLinux64Guest", "other4xLinux64Guest", "other3xLinux64Guest", "otherLinux64Guest")
#endregion Guest OS tables

function Read-VIServerName {
    $connectionWindow = New-Object System.Windows.Forms.Form
    $connectionWindow.Text = "Connect to VMware"
    $connectionWindow.ClientSize = New-Object System.Drawing.Size(380, 128)
    $connectionWindow.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $connectionWindow.MaximizeBox = $false
    $connectionWindow.MinimizeBox = $false
    $connectionWindow.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $connectionWindow.ShowInTaskbar = $false

    $serverLabel = New-Object System.Windows.Forms.Label
    $serverLabel.Text = "vCenter / ESXi server name or FQDN:"
    $serverLabel.AutoSize = $true
    $serverLabel.Location = New-Object System.Drawing.Point(12, 14)

    $serverTextBox = New-Object System.Windows.Forms.TextBox
    $serverTextBox.Location = New-Object System.Drawing.Point(15, 38)
    $serverTextBox.Size = New-Object System.Drawing.Size(350, 23)
    $serverTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
        [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    $connectButton = New-Object System.Windows.Forms.Button
    $connectButton.Text = "Connect"
    $connectButton.Size = New-Object System.Drawing.Size(85, 27)
    $connectButton.Location = New-Object System.Drawing.Point(190, 82)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Size = New-Object System.Drawing.Size(85, 27)
    $cancelButton.Location = New-Object System.Drawing.Point(280, 82)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $connectButton.Add_Click({
        if ([string]::IsNullOrWhiteSpace($serverTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                $connectionWindow,
                "Enter a vCenter or ESXi server name.",
                "Server required",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            $serverTextBox.Focus()
            return
        }
        $connectionWindow.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $connectionWindow.Close()
    })

    $connectionWindow.Controls.AddRange([System.Windows.Forms.Control[]]@(
        $serverLabel, $serverTextBox, $connectButton, $cancelButton
    ))
    $connectionWindow.AcceptButton = $connectButton
    $connectionWindow.CancelButton = $cancelButton

    try {
        if ($connectionWindow.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $serverTextBox.Text.Trim()
        }
        return $null
    }
    finally {
        $connectionWindow.Dispose()
    }
}

#region PowerCLI connection
$script:viServersToDisconnect = @()
if (-not (Get-Module -Name VMware.VimAutomation.Core)) {
    try { Import-Module VMware.VimAutomation.Core -ErrorAction Stop }
    catch {
        [System.Windows.MessageBox]::Show("VMware PowerCLI could not be loaded: $($_.Exception.Message)",
            "PowerCLI missing", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }
}
$connectedVIServers = @($global:DefaultVIServers | Where-Object { $_.IsConnected })
if ($connectedVIServers.Count -gt 0) {
    $script:viServersToDisconnect = $connectedVIServers
}
else {
    $viServer = Read-VIServerName
    if ([string]::IsNullOrWhiteSpace($viServer)) { return }
    try {
        $script:viServersToDisconnect = @(Connect-VIServer -Server $viServer -ErrorAction Stop)
    }
    catch {
        [System.Windows.MessageBox]::Show("Could not connect to '$viServer': $($_.Exception.Message)",
            "Connection failed", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }
}
#endregion PowerCLI connection

#region XAML - main window
$xamlText = @'
<?xml version="1.0" encoding ="utf-16"?>
<Window 
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
Name="VMDeploy" Title="VM Deploy" Height="432" Width="464" WindowStartupLocation="CenterScreen" Background="#FFDFE084" WindowStyle="None" ResizeMode="NoResize">
<Grid Background="#FFB5B188" Width="464" Margin="0,0,0,1">
        <Rectangle HorizontalAlignment="Center" Height="94" Stroke="Black" VerticalAlignment="Top" Width="452" Margin="0,4,0,0"/>
        <Label Content="Deploy VMware VM" HorizontalAlignment="Left" Margin="100,26,0,0" VerticalAlignment="Top" FontFamily="Britannic Bold" FontSize="36" Width="350" FontWeight="Bold"/>
        <Image Height="77" Width="87" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="12,12,0,0" Source="__ICONPATH__" Stretch="Fill"/>
        <GroupBox Name="gbServer" Height="264" Margin="6,112,5,0" VerticalAlignment="Top" Header=" VM Characteristics"/>
        <TextBlock Name="lblVMfolder" HorizontalAlignment="Left" Margin="26,165,0,0" TextWrapping="Wrap" Text="Folder &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="16"/>
        <ComboBox Name="tbVMfolder" Width="344" Height="22" Margin="92,161,0,0" HorizontalAlignment="Left" Grid.Column="0" Grid.Row="0" VerticalAlignment="Top" FontFamily="Consolas" />
        <TextBlock Name="lblVMName" HorizontalAlignment="Left" Margin="26,135,0,0" TextWrapping="Wrap" Text="Name &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="16"/>
        <TextBlock Name="lblCPU" HorizontalAlignment="Left" Margin="25,297,0,0" TextWrapping="NoWrap" Text="CPU:" VerticalAlignment="Top" Height="16" Width="52" FontFamily="Consolas"/>
        <TextBlock Name="lblCore" HorizontalAlignment="Left" Margin="145,297,0,0" TextWrapping="NoWrap" Text="Cores/socket:" VerticalAlignment="Top" Width="94" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblMemory" HorizontalAlignment="Left" Margin="309,297,0,0" TextWrapping="NoWrap" Text="RAM (GB):" VerticalAlignment="Top" Width="58" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblOS" Margin="26,196,0,0" TextWrapping="Wrap" Text="Operating System &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="126" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblOS" Width="282" Height="22" Margin="154,192,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <TextBlock Name="lblOSVersion" Margin="26,229,0,0" TextWrapping="Wrap" Text="Version / Distribution &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="166" Height="16" HorizontalAlignment="Left"/>
        <TextBox Name="tbVMName" HorizontalAlignment="Left" Margin="92,132,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="344" Height="22" FontFamily="Consolas"/>
        <TextBlock Name="lblISO" HorizontalAlignment="Left" Margin="26,261,0,0" TextWrapping="NoWrap" Text="ISO file &gt;&gt;" VerticalAlignment="Top" Width="70" Height="16" FontFamily="Consolas"/>
        <ComboBox Name="tbISO" Width="258" Height="22" Margin="102,254,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" FontFamily="Consolas" ToolTip="ISO images found on the datastores accessible from the selected host"/>
        <Button Name="btnFetchISO" HorizontalAlignment="Left" Margin="368,254,0,0" VerticalAlignment="Top" Width="70" Height="22" FontFamily="Consolas" Content="Fetch ISOs"/>
        <Rectangle HorizontalAlignment="Center" Height="37" Margin="0,286,0,0" Stroke="Black" VerticalAlignment="Top" Width="432"/>
        <ComboBox Name="tbCpu" HorizontalAlignment="Left" Margin="80,295,0,0" VerticalAlignment="Top" Width="50" Height="22" FontFamily="Consolas"/>
        <ComboBox Name="tbCore" HorizontalAlignment="Left" Margin="241,295,0,0" VerticalAlignment="Top" Width="50" Height="22" FontFamily="Consolas"/>
        <ComboBox Name="tbMemory" HorizontalAlignment="Left" Margin="369,295,0,0" VerticalAlignment="Top" Width="64" Height="22" FontFamily="Consolas"/>
        <Rectangle HorizontalAlignment="Center" Height="40" Margin="0,330,0,0" Stroke="Black" VerticalAlignment="Top" Width="432" RenderTransformOrigin="0.514,6.348"/>
        <TextBlock Name="lblDatastore" Margin="22,342,0,0" TextWrapping="Wrap" Text="Datastore &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="80" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblDatastore" Width="140" Height="22" Margin="110,339,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <TextBlock Name="lblHost" Margin="254,342,0,0" TextWrapping="Wrap" Text="Host &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="48" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblHost" Width="136" Height="22" Margin="304,339,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <ProgressBar Name="pbDeployment" HorizontalAlignment="Left" Margin="20,390,0,0" VerticalAlignment="Top" Width="280" Height="26" Minimum="0" Maximum="100" Value="0" Background="#FF404040" Foreground="#FF16803C"/>
        <TextBlock Name="txtDeploymentStatus" HorizontalAlignment="Left" Margin="20,394,0,0" Text="Ready" VerticalAlignment="Top" Width="280" Height="18" FontFamily="Consolas" Foreground="White" TextAlignment="Center" IsHitTestVisible="False"/>
        <Button Name="btnNext" HorizontalAlignment="Left" Margin="310,390,0,0" VerticalAlignment="Top" Width="70" Height="26" FontFamily="Consolas" Content="Next"/>
        <Button Name="btnClose" HorizontalAlignment="Left" Margin="390,390,0,0" VerticalAlignment="Top" Width="68" Height="26" FontFamily="Consolas" Content="Close"/>
        <ComboBox Name="tblOSVersion" Height="22" Margin="198,226,28,0" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" Width="238" />
    </Grid>
</Window>
'@
# Use the configurable icon path; drop the image gracefully if the file is missing.
if (Test-Path -LiteralPath $iconPath) {
    $xamlText = $xamlText.Replace('__ICONPATH__', [System.Security.SecurityElement]::Escape($iconPath))
}
else {
    $xamlText = [regex]::Replace($xamlText, '<Image\b[^>]*/>', '')
}
[xml]$xaml = $xamlText
$myReader = New-Object System.Xml.XmlNodeReader $xaml
$myForm = [Windows.Markup.XamlReader]::Load($myReader)
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $myForm.FindName($_.Name) -Scope Script }
#endregion

#region XAML - disk window
[xml]$diskConfigXaml = @'
<?xml version="1.0" encoding="utf-16"?>
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Name="DiskConfigWindow" Title="Configure VM Disks" Height="520" Width="480"
        WindowStartupLocation="CenterOwner" Background="#FFDFE084" WindowStyle="None" ResizeMode="NoResize">
    <Grid Background="#FFB5B188" Margin="6">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid Grid.Row="0" Margin="12,10,12,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="130"/>
                <ColumnDefinition Width="75"/>
                <ColumnDefinition Width="100"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Number of disks:" VerticalAlignment="Center" FontFamily="Consolas"/>
            <TextBox Name="tbDiskCount" Grid.Column="1" Text="1" Height="26" VerticalContentAlignment="Center" FontFamily="Consolas"/>
            <Button Name="btnSetDiskCount" Grid.Column="2" Content="Set count" Height="26" Margin="8,0,0,0" FontFamily="Consolas"/>
        </Grid>
        <Grid Grid.Row="1" Margin="12,0,12,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="130"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Disk type:" VerticalAlignment="Center" FontFamily="Consolas"/>
            <ComboBox Name="cbDiskType" Grid.Column="1" Height="26" FontFamily="Consolas"/>
        </Grid>
        <TextBlock Grid.Row="2" Margin="12,0,12,6" Text="Enter each disk capacity in GB:" VerticalAlignment="Center" FontFamily="Consolas"/>
        <ScrollViewer Grid.Row="3" Margin="12,0,12,8" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
            <StackPanel Name="spDiskSizes"/>
        </ScrollViewer>
        <Grid Grid.Row="4" Margin="12,4,12,10">
            <ProgressBar Name="pbDiskDeployment" Height="26" Minimum="0" Maximum="100" Value="0" Background="#FF404040" Foreground="#FF16803C"/>
            <TextBlock Name="txtDiskDeploymentStatus" Height="18" Text="Ready" VerticalAlignment="Center" FontFamily="Consolas" Foreground="White" TextAlignment="Center" IsHitTestVisible="False"/>
        </Grid>
        <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" Margin="12,0,12,10">
            <Button Name="btnDiskBack" Content="Back" Width="90" Height="28" Margin="0,0,8,0" FontFamily="Consolas"/>
            <Button Name="btnDiskDeploy" Content="Deploy" Width="110" Height="28" Margin="0,0,8,0" FontFamily="Consolas"/>
            <Button Name="btnDiskClose" Content="Close" Width="80" Height="28" FontFamily="Consolas"/>
        </StackPanel>
    </Grid>
</Window>
'@
$diskConfigReader = New-Object System.Xml.XmlNodeReader $diskConfigXaml
$diskConfigWindow = [Windows.Markup.XamlReader]::Load($diskConfigReader)
$tbDiskCount             = $diskConfigWindow.FindName("tbDiskCount")
$btnSetDiskCount         = $diskConfigWindow.FindName("btnSetDiskCount")
$cbDiskType              = $diskConfigWindow.FindName("cbDiskType")
$spDiskSizes             = $diskConfigWindow.FindName("spDiskSizes")
$pbDiskDeployment        = $diskConfigWindow.FindName("pbDiskDeployment")
$txtDiskDeploymentStatus = $diskConfigWindow.FindName("txtDiskDeploymentStatus")
$btnDiskBack             = $diskConfigWindow.FindName("btnDiskBack")
$btnDiskDeploy           = $diskConfigWindow.FindName("btnDiskDeploy")
$btnDiskClose            = $diskConfigWindow.FindName("btnDiskClose")
#endregion

#region Helpers
$updateDeploymentProgress = {
    param(
        [double]$Percent,
        [string]$Status,
        [object]$ProgressBar = $pbDeployment,
        [object]$StatusText = $txtDeploymentStatus,
        [object]$ProgressWindow = $myForm
    )
    $ProgressBar.IsIndeterminate = $false
    $ProgressBar.Value = $Percent
    $StatusText.Text = $Status
    # Render priority forces a repaint even while the UI thread is busy.
    $ProgressWindow.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Render)
}

function Show-Box {
    param(
        [string]$Text,
        [string]$Title,
        [System.Windows.MessageBoxButton]$Buttons = [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
    )
    [System.Windows.MessageBox]::Show($Text, $Title, $Buttons, $Icon)
}

function Get-VMFolderDisplayName {
    param([object]$Folder)
    try {
        $parts = New-Object System.Collections.Generic.List[string]
        $current = $Folder
        $guard = 0
        while ($null -ne $current -and $current.Name -ne 'vm' -and $guard -lt 32) {
            $parts.Insert(0, $current.Name)
            $current = $current.Parent
            $guard++
        }
        if ($parts.Count -gt 0) { return ($parts -join '/') }
    }
    catch { }
    return $Folder.Name
}

function Get-DatastoreIso {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Datastore)

    $datastoreBrowser = Get-View -Id $Datastore.ExtensionData.Browser -ErrorAction Stop
    $searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
    $searchSpec.MatchPattern = @("*.iso", "*.ISO")
    $searchSpec.Query = @((New-Object VMware.Vim.IsoImageFileQuery))

    $searchResults = $datastoreBrowser.SearchDatastoreSubFolders("[$($Datastore.Name)]", $searchSpec)
    foreach ($folderResult in $searchResults) {
        foreach ($file in $folderResult.File) {
            [PSCustomObject]@{
                Name    = "$($folderResult.FolderPath)$($file.Path)"
                IsoPath = "$($folderResult.FolderPath)$($file.Path)"
            }
        }
    }
}

function Update-DatastoreList {
    $sel = $tblHost.SelectedItem
    $tblDatastore.Items.Clear()
    $tbISO.Items.Clear()
    $script:selectedIso = $null
    if ($null -eq $sel) { return }
    Get-Datastore -RelatedObject $sel.VMHost -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Available' } |
        Sort-Object Name |
        ForEach-Object { [void]$tblDatastore.Items.Add($_) }
    if ($tblDatastore.Items.Count -gt 0) { $tblDatastore.SelectedIndex = 0 }
}
#endregion

#region Disk window logic
[void]$cbDiskType.Items.Add("Thin")
[void]$cbDiskType.Items.Add("Thick (lazy zeroed)")
$cbDiskType.SelectedIndex = 0

$setDiskRows = {
    $diskCount = 0
    if (-not [int]::TryParse($tbDiskCount.Text.Trim(), [ref]$diskCount) -or $diskCount -lt 1 -or $diskCount -gt $maxDisks) {
        Show-Box "Enter a whole number of disks between 1 and $maxDisks." "Invalid disk count" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    # Preserve sizes that were already typed.
    $previousSizes = @()
    foreach ($row in $spDiskSizes.Children) { $previousSizes += $row.Children[1].Text }

    $spDiskSizes.Children.Clear()
    for ($diskIndex = 1; $diskIndex -le $diskCount; $diskIndex++) {
        $diskRow = New-Object System.Windows.Controls.StackPanel
        $diskRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $diskRow.Margin = New-Object System.Windows.Thickness(0, 3, 0, 3)

        $diskLabel = New-Object System.Windows.Controls.TextBlock
        $diskLabel.Text = "Disk $diskIndex (GB):"
        $diskLabel.Width = 130
        $diskLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $diskLabel.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")

        $diskSizeInput = New-Object System.Windows.Controls.TextBox
        $diskSizeInput.Width = 120
        $diskSizeInput.Height = 24
        $diskSizeInput.Tag = $diskIndex
        $diskSizeInput.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
        if ($diskIndex -le $previousSizes.Count) { $diskSizeInput.Text = $previousSizes[$diskIndex - 1] }

        [void]$diskRow.Children.Add($diskLabel)
        [void]$diskRow.Children.Add($diskSizeInput)
        [void]$spDiskSizes.Children.Add($diskRow)
    }
}
& $setDiskRows
$btnSetDiskCount.Add_Click($setDiskRows)

# Back: hide (not close) so the window can be shown again.
$btnDiskBack.Add_Click({ $diskConfigWindow.Hide() })

$btnDiskClose.Add_Click({
    $ownerWindow = $diskConfigWindow.Owner
    $diskConfigWindow.Tag = "ClosingAll"
    $diskConfigWindow.Close()
    if ($null -ne $ownerWindow) { $ownerWindow.Close() }
})

$diskConfigWindow.Add_Closing({
    # Only react to a real close of a visible window (X button); ignore closes triggered by the owner.
    if ($diskConfigWindow.IsVisible -and $diskConfigWindow.Tag -ne "ClosingAll" -and $null -ne $diskConfigWindow.Owner) {
        $diskConfigWindow.Tag = "ClosingAll"
        $diskConfigWindow.Owner.Close()
    }
})
#endregion

#region Main window logic
$btnNext.Add_Click({
    if ([string]::IsNullOrWhiteSpace($tbVMName.Text)) {
        Show-Box "Enter a VM name." "Missing information" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    if ($null -eq $tbVMfolder.SelectedItem -or $null -eq $tblHost.SelectedItem -or $null -eq $tblDatastore.SelectedItem) {
        Show-Box "Select a VM folder, an ESXi host and a datastore." "Missing information" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    if ($null -eq $tblOSVersion.SelectedItem -or $null -eq $tbMemory.SelectedItem) {
        Show-Box "Select the operating system version and memory size." "Missing information" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    if ($null -eq $diskConfigWindow.Owner) { $diskConfigWindow.Owner = $myForm }
    $diskConfigWindow.Tag = $null
    $diskConfigWindow.ShowDialog() | Out-Null
})

$btnClose.Add_Click({ $myForm.Close() })

$myForm.Add_Closing({
    $disconnectErrors = @()
    foreach ($viServerConnection in $script:viServersToDisconnect) {
        if (-not $viServerConnection.IsConnected) { continue }
        try {
            Disconnect-VIServer -Server $viServerConnection -Confirm:$false -ErrorAction Stop | Out-Null
        }
        catch {
            $disconnectErrors += "Could not disconnect from '$($viServerConnection.Name)': $($_.Exception.Message)"
        }
    }
    if ($disconnectErrors.Count -gt 0) {
        Show-Box ($disconnectErrors -join "`n") "vCenter disconnect warning" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})

# The main window has no title bar, so allow dragging it.
$myForm.Add_MouseLeftButtonDown({ try { $myForm.DragMove() } catch { } })

# VM folders (with path so duplicates are distinguishable)
$tbVMfolder.DisplayMemberPath = "Name"
Get-Folder -Type VM | Where-Object { $_.Name -notin @("vm", "vCLS") } | ForEach-Object {
    [PSCustomObject]@{ Name = (Get-VMFolderDisplayName -Folder $_); Folder = $_ }
} | Sort-Object Name | ForEach-Object { [void]$tbVMfolder.Items.Add($_) }
if ($tbVMfolder.Items.Count -gt 0) { $tbVMfolder.SelectedIndex = 0 }

# OS and version / distribution
[void]$tblOS.Items.Add("Windows")
[void]$tblOS.Items.Add("Linux")
$tblOS.add_SelectionChanged({
    $tblOSVersion.Items.Clear()
    $versions = switch ($tblOS.SelectedItem) {
        "Windows" { $windowsList }
        "Linux"   { $linuxList }
        default   { @() }
    }
    foreach ($version in $versions) { [void]$tblOSVersion.Items.Add($version) }
    if ($tblOSVersion.Items.Count -gt 0) { $tblOSVersion.SelectedIndex = 0 }
})
$tblOS.SelectedIndex = 0

# CPU / cores / memory
foreach ($cpu in @(1, 2, 4, 8, 16, 32))                          { [void]$tbCpu.Items.Add($cpu) }
$tbCpu.SelectedIndex = 0
foreach ($core in @(1, 2, 3, 4, 6, 8, 12, 16, 24, 32))           { [void]$tbCore.Items.Add($core) }
$tbCore.SelectedIndex = 0
foreach ($memory in @(1, 2, 3, 4, 6, 8, 16, 24, 32, 64, 96, 128, 512)) { [void]$tbMemory.Items.Add($memory) }
$tbMemory.SelectedIndex = 0

# Datastores follow the selected host
$tblDatastore.DisplayMemberPath = "Name"
$tblHost.DisplayMemberPath = "Name"
$tblHost.Add_SelectionChanged({ Update-DatastoreList })

# Hosts (the selection event above fills the datastore list)
Get-VMHost | Where-Object { $_.ConnectionState -eq 'Connected' } | Sort-Object Name | ForEach-Object {
    $shortName = if ($_.Name -match '^\d{1,3}(\.\d{1,3}){3}$') { $_.Name } else { $_.Name.Split(".")[0] }
    [void]$tblHost.Items.Add([PSCustomObject]@{ Name = $shortName; VMHost = $_ })
}
if ($tblHost.Items.Count -gt 0) { $tblHost.SelectedIndex = 0 }

# ISO handling
$tbISO.DisplayMemberPath = "Name"
$script:selectedIso = $null
$tbISO.Add_SelectionChanged({ $script:selectedIso = $tbISO.SelectedItem })

$btnFetchISO.Add_Click({
    $btnFetchISO.IsEnabled = $false
    $tbISO.Items.Clear()
    try {
        if ($null -eq $tblHost.SelectedItem) { throw "Select an ESXi host first." }
        $datastoresToSearch = @(Get-Datastore -RelatedObject $tblHost.SelectedItem.VMHost -ErrorAction Stop |
                                Where-Object { $_.State -eq 'Available' } | Sort-Object Name)
        if ($datastoresToSearch.Count -eq 0) { throw "No accessible datastores are available on the selected host." }

        $isoSearchFailures = @()
        $isoCount = 0
        for ($datastoreIndex = 0; $datastoreIndex -lt $datastoresToSearch.Count; $datastoreIndex++) {
            $isoDatastore = $datastoresToSearch[$datastoreIndex]
            $progress = [math]::Round((($datastoreIndex / $datastoresToSearch.Count) * 100), 0)
            & $updateDeploymentProgress $progress "Searching datastore $($datastoreIndex + 1) of $($datastoresToSearch.Count): $($isoDatastore.Name)"
            try {
                foreach ($isoFile in (Get-DatastoreIso -Datastore $isoDatastore -ErrorAction Stop)) {
                    [void]$tbISO.Items.Add($isoFile)
                    $isoCount++
                }
            }
            catch { $isoSearchFailures += "$($isoDatastore.Name): $($_.Exception.Message)" }
        }

        $tbISO.SelectedIndex = -1
        & $updateDeploymentProgress 100 "ISO search complete. Found $isoCount file(s)."

        if ($isoSearchFailures.Count -gt 0) {
            $failureDetails = $isoSearchFailures -join [Environment]::NewLine
            Show-Box "ISO search found $isoCount file(s), but could not search some datastores:`n$failureDetails" "ISO search incomplete" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Warning) | Out-Null
        }
    }
    catch {
        & $updateDeploymentProgress 0 "ISO search failed."
        Show-Box $_.Exception.Message "ISO search failed" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Error) | Out-Null
    }
    finally { $btnFetchISO.IsEnabled = $true }
})
#endregion

#region Deployment
$btnDiskDeploy.Add_Click({
    $createdVM = $null
    $warnings = @()
    $btnDiskDeploy.IsEnabled = $false
    $dp = @($pbDiskDeployment, $txtDiskDeploymentStatus, $diskConfigWindow)
    try {
        & $updateDeploymentProgress 5 "Validating selections..." @dp
        $vmName     = $tbVMName.Text.Trim()
        $folderItem = $tbVMfolder.SelectedItem
        $folder     = if ($null -ne $folderItem) { $folderItem.Folder } else { $null }
        $osType     = [string]$tblOS.SelectedItem
        $osVersion  = [string]$tblOSVersion.SelectedItem
        $datastore  = $tblDatastore.SelectedItem
        $hostOption = $tblHost.SelectedItem
        $guestKey   = "$osType|$osVersion"

        if ([string]::IsNullOrWhiteSpace($vmName)) { throw "Enter a VM name." }
        if ($vmName.Length -gt 80 -or $vmName -match '[\\/:*?"<>|%&]') {
            throw "The VM name is longer than 80 characters or contains invalid characters."
        }
        if ($null -eq $folder -or $null -eq $datastore -or $null -eq $hostOption) {
            throw "Select a VM folder, connected ESXi host, and datastore."
        }
        if (-not $guestIdBySelection.ContainsKey($guestKey)) {
            throw "The selected operating system and version are not supported."
        }
        if (Get-VM -Name $vmName -ErrorAction SilentlyContinue) {
            throw "A VM named '$vmName' already exists in this inventory."
        }

        $requestedGuestId = $guestIdBySelection[$guestKey]
        & $updateDeploymentProgress 15 "Checking ESXi guest support..." @dp
        $computeResource = Get-View -Id $hostOption.VMHost.ExtensionData.Parent -Property EnvironmentBrowser -ErrorAction Stop
        if ($null -eq $computeResource.EnvironmentBrowser) {
            throw "Could not find the selected ESXi host's VM environment browser."
        }
        $environmentBrowser = Get-View -Id $computeResource.EnvironmentBrowser -ErrorAction Stop
        $defaultConfigOption = $environmentBrowser.QueryConfigOptionDescriptor() |
            Where-Object { $_.DefaultConfigOption } | Select-Object -First 1
        if ($null -eq $defaultConfigOption) {
            throw "Could not determine the selected ESXi host's supported VM hardware configuration."
        }
        $vmConfigOption = $environmentBrowser.QueryConfigOption($defaultConfigOption.Key, $hostOption.VMHost.ExtensionData.MoRef)
        $guestDescriptors = @($vmConfigOption.GuestOSDescriptor)
        $selectedGuestId = $requestedGuestId
        $selectedGuestDescriptor = $guestDescriptors | Where-Object { $_.Id -eq $requestedGuestId } | Select-Object -First 1

        if ($null -eq $selectedGuestDescriptor) {
            $fallbackGuestIds = @()
            if ($guestIdFallbacksBySelection.ContainsKey($guestKey)) { $fallbackGuestIds += $guestIdFallbacksBySelection[$guestKey] }
            if ($osType -eq "Linux") { $fallbackGuestIds += $linuxGenericFallbacks }

            $fallbackDescriptor = $null
            foreach ($fallbackGuestId in $fallbackGuestIds) {
                $fallbackDescriptor = $guestDescriptors | Where-Object { $_.Id -eq $fallbackGuestId } | Select-Object -First 1
                if ($null -ne $fallbackDescriptor) { break }
            }

            if ($null -eq $fallbackDescriptor) {
                $pattern = if ($osType -eq "Windows") { 'windows|win' } else { 'linux|ubuntu|debian|rhel|centos|sles|suse|oracle|fedora' }
                $supportedProfiles = @($guestDescriptors | Where-Object { $_.Id -match $pattern } | ForEach-Object { $_.Id } | Sort-Object -Unique)
                if ($supportedProfiles.Count -eq 0) { $supportedProfiles = @("No matching guest profiles were returned by the selected ESXi host.") }
                throw "The selected ESXi host does not support guest profile '$requestedGuestId'. No compatible fallback profile was found. $osType profiles reported by the host: $($supportedProfiles -join ', ')."
            }

            $fallbackName = $fallbackDescriptor.FullName
            if ([string]::IsNullOrWhiteSpace($fallbackName)) { $fallbackName = $fallbackDescriptor.Id }
            $fallbackChoice = Show-Box "The selected ESXi host does not support the '$osVersion' guest profile. Use '$fallbackName' instead? The VM will remain powered off." "Guest profile not supported" ([System.Windows.MessageBoxButton]::YesNo) ([System.Windows.MessageBoxImage]::Warning)
            if ($fallbackChoice -ne [System.Windows.MessageBoxResult]::Yes) {
                & $updateDeploymentProgress 0 "Deployment cancelled." @dp
                return
            }
            $selectedGuestId = $fallbackDescriptor.Id
            $selectedGuestDescriptor = $fallbackDescriptor
        }
        $selectedGuestProfileName = $selectedGuestDescriptor.FullName
        if ([string]::IsNullOrWhiteSpace($selectedGuestProfileName)) { $selectedGuestProfileName = $selectedGuestDescriptor.Id }

        $socketCount    = [int]$tbCpu.SelectedItem
        $coresPerSocket = [int]$tbCore.SelectedItem
        if ($socketCount -lt 1 -or $coresPerSocket -lt 1) { throw "Select a positive number of sockets and cores per socket." }
        $totalCpuCount = $socketCount * $coresPerSocket
        $hostThreads = [int]$hostOption.VMHost.ExtensionData.Hardware.CpuInfo.NumCpuThreads
        if ($hostThreads -gt 0 -and $totalCpuCount -gt $hostThreads) {
            throw "Requested $totalCpuCount vCPUs exceeds the host's $hostThreads logical processors."
        }

        if ($null -eq $tbMemory.SelectedItem) { throw "Select the amount of memory in GB." }
        $memoryGB = [int]$tbMemory.SelectedItem

        $diskSizesGB = @()
        foreach ($diskRow in $spDiskSizes.Children) {
            $diskSizeInput = $diskRow.Children[1]
            $diskSizeGB = 0
            if (-not [int]::TryParse($diskSizeInput.Text.Trim(), [ref]$diskSizeGB) -or $diskSizeGB -lt 1) {
                throw "Enter a positive whole-number capacity in GB for Disk $($diskSizeInput.Tag)."
            }
            $diskSizesGB += $diskSizeGB
        }
        if ($diskSizesGB.Count -eq 0) { throw "Set the disk count and enter a capacity for every disk." }
        if ($diskSizesGB.Count -gt $maxDisks) { throw "A maximum of $maxDisks disks is supported." }

        $diskStorageFormat = switch ($cbDiskType.SelectedItem) {
            "Thin"                { "Thin" }
            "Thick (lazy zeroed)" { "Thick" }
            default               { throw "Select a valid VMware disk provisioning type." }
        }
        $selectedIso = $script:selectedIso
        if ($null -ne $selectedIso -and [string]::IsNullOrWhiteSpace($selectedIso.IsoPath)) {
            throw "The selected ISO does not have a valid vSphere datastore path. Fetch the ISO list again and select an image."
        }

        & $updateDeploymentProgress 35 "Preparing VM configuration..." @dp
        $newVMParams = @{
            Name              = $vmName
            VMHost            = $hostOption.VMHost
            Datastore         = $datastore
            Location          = $folder
            GuestId           = $selectedGuestId
            NumCpu            = $totalCpuCount
            MemoryGB          = $memoryGB
            DiskGB            = $diskSizesGB[0]
            DiskStorageFormat = $diskStorageFormat
            ErrorAction       = "Stop"
        }
        & $updateDeploymentProgress 45 "Creating powered-off VM..." @dp
        $createdVM = New-VM @newVMParams

        # Windows 11 / Server 2025: UEFI + Secure Boot (and vTPM for Windows 11)
        if ($osVersion -in @("Windows 11", "Windows 2025")) {
            & $updateDeploymentProgress 55 "Configuring UEFI and Secure Boot..." @dp
            $bootSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
            $bootSpec.Firmware = "efi"
            $bootSpec.BootOptions = New-Object VMware.Vim.VirtualMachineBootOptions
            $bootSpec.BootOptions.EfiSecureBootEnabled = $true
            (Get-View -Id $createdVM.Id -ErrorAction Stop).ReconfigVM($bootSpec)

            if ($osVersion -eq "Windows 11") {
                if (Get-Command New-VTpm -ErrorAction SilentlyContinue) {
                    try { New-VTpm -VM $createdVM -ErrorAction Stop | Out-Null }
                    catch { $warnings += "vTPM could not be added (a key provider must be configured): $($_.Exception.Message)" }
                }
                else { $warnings += "New-VTpm is not available in this PowerCLI install; add a vTPM manually before installing Windows 11." }
            }
        }

        & $updateDeploymentProgress 65 "Applying CPU configuration..." @dp
        Set-VM -VM $createdVM -CoresPerSocket $coresPerSocket -Confirm:$false -ErrorAction Stop | Out-Null

        for ($diskIndex = 1; $diskIndex -lt $diskSizesGB.Count; $diskIndex++) {
            $progress = 70 + [math]::Round((($diskIndex / $diskSizesGB.Count) * 25), 0)
            & $updateDeploymentProgress $progress "Adding disk $($diskIndex + 1) of $($diskSizesGB.Count)..." @dp
            New-HardDisk -VM $createdVM -Datastore $datastore -CapacityGB $diskSizesGB[$diskIndex] -StorageFormat $diskStorageFormat -ErrorAction Stop | Out-Null
        }

        $cdDrive = Get-CDDrive -VM $createdVM -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $cdDrive) {
            if ($null -ne $selectedIso) {
                & $updateDeploymentProgress 96 "Adding CD/DVD drive and configuring selected ISO..." @dp
                New-CDDrive -VM $createdVM -IsoPath $selectedIso.IsoPath -StartConnected -ErrorAction Stop | Out-Null
            }
            else {
                & $updateDeploymentProgress 96 "Adding CD/DVD drive..." @dp
                New-CDDrive -VM $createdVM -ErrorAction Stop | Out-Null
            }
            $cdDrive = Get-CDDrive -VM $createdVM -ErrorAction Stop | Select-Object -First 1
        }
        if ($null -eq $cdDrive) { throw "A CD/DVD drive could not be added to VM '$vmName'." }

        if ($null -ne $selectedIso) {
            & $updateDeploymentProgress 97 "Configuring selected ISO to connect at power-on..." @dp
            Set-CDDrive -CD $cdDrive -IsoPath $selectedIso.IsoPath -StartConnected:$true -Confirm:$false -ErrorAction Stop | Out-Null
            $expectedIsoPath = ([string]$selectedIso.IsoPath).Trim().Replace("/", "\")
            $vmConfigView = Get-View -Id $createdVM.Id -Property Config.Hardware.Device -ErrorAction Stop
            $configuredCDDrive = $vmConfigView.Config.Hardware.Device |
                Where-Object { $_ -is [VMware.Vim.VirtualCdrom] } |
                Where-Object {
                    $_.Backing -is [VMware.Vim.VirtualCdromIsoBackingInfo] -and
                    ([string]$_.Backing.FileName).Trim().Replace("/", "\") -ieq $expectedIsoPath -and
                    $_.Connectable.StartConnected -eq $true
                } | Select-Object -First 1
            if ($null -eq $configuredCDDrive) {
                $cdDriveState = @($vmConfigView.Config.Hardware.Device |
                    Where-Object { $_ -is [VMware.Vim.VirtualCdrom] } |
                    ForEach-Object {
                        $backingPath = $null
                        if ($_.Backing -is [VMware.Vim.VirtualCdromIsoBackingInfo]) { $backingPath = $_.Backing.FileName }
                        "ISO='$backingPath', StartConnected=$($_.Connectable.StartConnected), Connected=$($_.Connectable.Connected)"
                    }) -join "; "
                throw "The CD/DVD drive was not saved with ISO '$($selectedIso.Name)' attached and set to connect at power-on. Current CD/DVD configuration: $cdDriveState"
            }
        }

        $createdVM = Get-VM -Id $createdVM.Id -ErrorAction Stop
        if ($createdVM.PowerState -ne "PoweredOff") {
            throw "VM '$vmName' should remain powered off after deployment, but its current state is '$($createdVM.PowerState)'."
        }

        $messageLines = @(
            "Deployment completed successfully."
            ""
            "VM DETAILS"
            "  Name: $vmName"
            "  Host: $($hostOption.Name)"
            "  Datastore: $($datastore.Name)"
            "  Power state: Powered off"
            ""
            "RESOURCES"
            "  CPU: $totalCpuCount vCPU(s) across $socketCount socket(s)"
            "  Memory: $memoryGB GB"
            "  Disks: $($diskSizesGB.Count) $diskStorageFormat"
        )
        if ($selectedGuestId -ne $requestedGuestId) {
            $messageLines += @(
                ""
                "GUEST PROFILE"
                "  Selected: $osVersion"
                "  Used: $selectedGuestProfileName (host-compatible fallback)"
            )
        }
        if ($null -ne $selectedIso) {
            $messageLines += @(
                ""
                "INSTALL MEDIA"
                "  ISO: $($selectedIso.Name)"
                "  Connect: When the VM is powered on"
            )
        }
        else {
            $messageLines += @(
                ""
                "INSTALL MEDIA"
                "  ISO: None selected"
            )
        }
        if ($warnings.Count -gt 0) {
            $messageLines += @("", "WARNINGS")
            foreach ($warning in $warnings) {
                $messageLines += "  - $warning"
            }
        }

        & $updateDeploymentProgress 100 "Deployment complete." @dp
        Show-Box ($messageLines -join "`n") "VM deployment complete" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Information) | Out-Null
    }
    catch {
        $txtDiskDeploymentStatus.Text = "Deployment failed."
        $pbDiskDeployment.Value = 0
        $message = $_.Exception.Message
        if ($null -ne $createdVM) {
            $answer = Show-Box "VM '$($createdVM.Name)' was created, but a later step failed:`n`n$message`n`nDelete the partially configured VM?" "VM deployment failed" ([System.Windows.MessageBoxButton]::YesNo) ([System.Windows.MessageBoxImage]::Error)
            if ($answer -eq [System.Windows.MessageBoxResult]::Yes) {
                try {
                    Remove-VM -VM $createdVM -DeletePermanently -Confirm:$false -ErrorAction Stop
                    $createdVM = $null
                    $txtDiskDeploymentStatus.Text = "Partial VM removed. Ready."
                }
                catch {
                    Show-Box "Cleanup failed: $($_.Exception.Message)" "Cleanup failed" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Error) | Out-Null
                }
            }
        }
        else {
            Show-Box $message "VM deployment failed" ([System.Windows.MessageBoxButton]::OK) ([System.Windows.MessageBoxImage]::Error) | Out-Null
        }
    }
    finally {
        # Re-enable only if no VM remains (failed before creation, or the partial VM was deleted).
        if ($null -eq $createdVM) { $btnDiskDeploy.IsEnabled = $true }
    }
})
#endregion

$myForm.ShowDialog() | Out-Null


#What changed
#Bugs fixed
#- Back/Next: Back now calls Hide(), so the disk window can be reopened. The Closing handler only acts on a visible window, so closing the main form while the disk window is hidden no longer throws.
#- Guest IDs: Server 2016 uses windows9Server64Guest, 2022 uses windows2019srvNext_64Guest, and 2025 uses windows2022srvNext_64Guest. CentOS Stream 9 uses centos9_64Guest, and openSUSE Leap 15 uses opensuse64Guest.
#- Removed ID: I removed windows10_64Guest from the Windows 11 fallbacks because it isn't a valid vSphere identifier. Windows 10 is windows9_64Guest.
#- Linux fallbacks: Linux now falls back to the generic other5x/4x/3x/otherLinux64Guest profiles, and the error message lists profiles for the right OS.
#- Host names: IP-addressed hosts are no longer truncated to the first octet.
#- Icon: $iconPath is now actually used, and the image is dropped if the file is missing.

#Deployment hardening
#- Datastores and ISOs: The datastore list, and the ISO search, are limited to datastores accessible from the selected host. Changing the host refreshes both lists.
#- Pre-flight checks: Checks cover VM name length and characters, duplicate VM names, vCPU count against host logical processors, and a limit of 15 disks.
#- UEFI and TPM: Windows 11 and Server 2025 get UEFI and Secure Boot. Windows 11 also tries to add a vTPM. If the vTPM can't be added (no key provider, or no New-VTpm), that is reported as a warning instead of failing the deployment.
#- Cleanup: A failed deployment offers to delete the partial VM, and the Deploy button is re-enabled after a successful cleanup.

#Changes from my earlier review
#- Firmware is set with the string "efi", which is what VirtualMachineConfigSpec.Firmware expects.
#- The vCPU check uses ExtensionData.Hardware.CpuInfo.NumCpuThreads, because VMHost.NumCpu isn't a reliable logical-processor count.

#UI polish
#- Startup: The script checks the PowerCLI module and vCenter connection at startup.
#- Validation: The Next button validates the main form before the disk window opens.
#- Dragging: The borderless window can be dragged.
#- Disk sizes: Sizes you've typed are kept when you change the disk count.
#- Progress bar: It repaints at Render priority.
#- Folders and ISOs: The folder list shows full paths, and ISO entries no longer repeat the datastore name.
#- Output: The final ShowDialog() output is suppressed.

#Remaining caveats
#- Guest OS availability depends on your ESXi version. Windows 11, Server 2022 and Server 2025 need recent ESXi builds, and the fallback prompt handles older hosts.
#- ISO scanning and VM creation still run on the UI thread, so the window can look unresponsive during long operations. A background runspace would fix that, but it is a larger rewrite.
#- There is no network adapter selector. Add -NetworkName to New-VM if your default port group isn't what you want.