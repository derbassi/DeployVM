Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

#region Variables
$iconPath="C:\gitHub\DeployVM\iconpath\DeployVM.png"
$windowsList = @("Windows 7", "Windows 8", "Windows 10", "Windows 11", "Windows 2016", "Windows 2019", "Windows 2022", "Windows 2025")
$linuxList = @("Ubuntu 20", "Ubuntu 21", "Ubuntu 22", "Ubuntu 23", "Ubuntu 24", "Ubuntu 25", "Ubuntu 26", "Debian 10", "Debian 11", "Debian 12", "Debian 13","Debian 14", "Suse 15", "Suse 16", "OpenSuse Leap 42", "OpenSuse Leap 15", "OpenSuse Leap 15", "Red Hat 7", "Red Hat 8", "Red Hat 9", "Cent OS 7", "Cent OS 8", "Cent OS 9 Stream", "Oracle Linux 7", "Oracle Linux 8", "Oracle Linux 9", "Fedora 36", "Fedora 37", "Fedora 38")
#endregion Variables

#region XAML
[xml]$xaml=@'
<?xml version="1.0" encoding ="utf-16"?>
<Window 
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
Name="VMDeploy" Title="VM Deploy" Height="432" Width="464" WindowStartupLocation="CenterScreen" Background="#FFDFE084" WindowStyle="None" ResizeMode="NoResize">
<Grid Background="#FFB5B188" Width="464" Margin="0,0,0,1">
        <Rectangle HorizontalAlignment="Center" Height="94" Stroke="Black" VerticalAlignment="Top" Width="452" Margin="0,4,0,0"/>
        <Label Content="Deploy VMware VM" HorizontalAlignment="Left" Margin="100,26,0,0" VerticalAlignment="Top" FontFamily="Britannic Bold" FontSize="36" Width="350" FontWeight="Bold"/>
        <Image Height="77" Width="87" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="12,12,0,0" Source="C:\gitHub\DeployVM\DeployVM.png" Stretch="Fill"/>
        <GroupBox Name="gbServer" Height="264" Margin="6,112,5,0" VerticalAlignment="Top" Header=" VM Caracteristics"/>
        <TextBlock Name="lblVMfolder" HorizontalAlignment="Left" Margin="26,165,0,0" TextWrapping="Wrap" Text="Folder >>" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="16"/>
        <ComboBox Name="tbVMfolder" Width="344" Height="22" Margin="92,161,0,0" HorizontalAlignment="Left" Grid.Column="0" Grid.Row="0" VerticalAlignment="Top" FontFamily="Consolas" />
        <TextBlock Name="lblVMName" HorizontalAlignment="Left" Margin="26,135,0,0" TextWrapping="Wrap" Text="Name &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="16"/>
        <TextBlock Name="lblCPU" HorizontalAlignment="Left" Margin="25,297,0,0" TextWrapping="NoWrap" Text="Sockets:" VerticalAlignment="Top" Height="16" Width="52" FontFamily="Consolas"/>
        <TextBlock Name="lblCore" HorizontalAlignment="Left" Margin="145,297,0,0" TextWrapping="NoWrap" Text="Cores/socket:" VerticalAlignment="Top" Width="94" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblMemory" HorizontalAlignment="Left" Margin="309,297,0,0" TextWrapping="NoWrap" Text="RAM (GB):" VerticalAlignment="Top" Width="58" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblOS" Margin="26,196,0,0" TextWrapping="Wrap" Text="Operation System >>" VerticalAlignment="Top" FontFamily="Consolas" Width="126" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblOS" Width="282" Height="22" Margin="154,192,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <TextBlock Name="lblOSVersion" Margin="26,229,0,0" TextWrapping="Wrap" Text="Version / Distribution >>" VerticalAlignment="Top" FontFamily="Consolas" Width="166" Height="16" HorizontalAlignment="Left"/>
        <TextBox Name="tbVMName" HorizontalAlignment="Left" Margin="92,132,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="344" Height="22" FontFamily="Consolas"/>
        <TextBlock Name="lblISO" HorizontalAlignment="Left" Margin="26,261,0,0" TextWrapping="NoWrap" Text="ISO file &gt;&gt;" VerticalAlignment="Top" Width="70" Height="16" FontFamily="Consolas"/>
        <ComboBox Name="tbISO" Width="258" Height="22" Margin="102,254,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" FontFamily="Consolas" ToolTip="ISO images found on all connected datastores, including local datastores"/>
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
$myReader = (New-Object System.Xml.XmlNodeReader $xaml)
$myForm = [Windows.Markup.XamlReader]::Load($myReader)
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $myForm.FindName($_.Name)}
#endregion

[xml]$diskConfigXaml = @'
<?xml version="1.0" encoding="utf-16"?>
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Name="DiskConfigWindow" Title="Configure VM Disks" Height="520" Width="480"
        WindowStartupLocation="CenterOwner" Background="#FFDFE084" ResizeMode="NoResize">
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
            <TextBlock Grid.Column="0" Text="Number of disks:" VerticalAlignment="Center"
                       FontFamily="Consolas"/>
            <TextBox Name="tbDiskCount" Grid.Column="1" Text="1" Height="26"
                     VerticalContentAlignment="Center" FontFamily="Consolas"/>
            <Button Name="btnSetDiskCount" Grid.Column="2" Content="Set count" Height="26"
                    Margin="8,0,0,0" FontFamily="Consolas"/>
        </Grid>
        <Grid Grid.Row="1" Margin="12,0,12,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="130"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Disk type:" VerticalAlignment="Center"
                       FontFamily="Consolas"/>
            <ComboBox Name="cbDiskType" Grid.Column="1" Height="26"
                      FontFamily="Consolas"/>
        </Grid>
        <TextBlock Grid.Row="2" Margin="12,0,12,6" Text="Enter each disk capacity in GB:"
                   VerticalAlignment="Center" FontFamily="Consolas"/>
        <ScrollViewer Grid.Row="3" Margin="12,0,12,8"
                      VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
            <StackPanel Name="spDiskSizes"/>
        </ScrollViewer>
        <Grid Grid.Row="4" Margin="12,4,12,10">
            <ProgressBar Name="pbDiskDeployment" Height="26" Minimum="0" Maximum="100" Value="0"
                     Background="#FF404040" Foreground="#FF16803C"/>
            <TextBlock Name="txtDiskDeploymentStatus" Height="18" Text="Ready"
                       VerticalAlignment="Center" FontFamily="Consolas"
                       Foreground="White" TextAlignment="Center" IsHitTestVisible="False"/>
        </Grid>
        <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right"
                    Margin="12,0,12,10">
            <Button Name="btnDiskBack" Content="Back" Width="90" Height="28"
                    Margin="0,0,8,0" FontFamily="Consolas"/>
            <Button Name="btnDiskDeploy" Content="Deploy" Width="110" Height="28"
                    Margin="0,0,8,0" FontFamily="Consolas"/>
            <Button Name="btnDiskClose" Content="Close" Width="80" Height="28"
                    FontFamily="Consolas"/>
        </StackPanel>
    </Grid>
</Window>
'@
$diskConfigReader = New-Object System.Xml.XmlNodeReader $diskConfigXaml
$diskConfigWindow = [Windows.Markup.XamlReader]::Load($diskConfigReader)
$tbDiskCount = $diskConfigWindow.FindName("tbDiskCount")
$btnSetDiskCount = $diskConfigWindow.FindName("btnSetDiskCount")
$cbDiskType = $diskConfigWindow.FindName("cbDiskType")
$spDiskSizes = $diskConfigWindow.FindName("spDiskSizes")
$pbDiskDeployment = $diskConfigWindow.FindName("pbDiskDeployment")
$txtDiskDeploymentStatus = $diskConfigWindow.FindName("txtDiskDeploymentStatus")
$btnDiskBack = $diskConfigWindow.FindName("btnDiskBack")
$btnDiskDeploy = $diskConfigWindow.FindName("btnDiskDeploy")
$btnDiskClose = $diskConfigWindow.FindName("btnDiskClose")

[void]$cbDiskType.Items.Add("Thin")
[void]$cbDiskType.Items.Add("Thick (lazy zeroed)")
$cbDiskType.SelectedIndex = 0

$setDiskRows = {
    $diskCount = 0
    if (-not [int]::TryParse($tbDiskCount.Text.Trim(), [ref]$diskCount) -or $diskCount -lt 1) {
        [System.Windows.MessageBox]::Show(
            "Enter a positive whole-number disk count.",
            "Invalid disk count",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        ) | Out-Null
        return
    }

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

        [void]$diskRow.Children.Add($diskLabel)
        [void]$diskRow.Children.Add($diskSizeInput)
        [void]$spDiskSizes.Children.Add($diskRow)
    }
}
& $setDiskRows

$btnSetDiskCount.Add_Click($setDiskRows)
$btnDiskBack.Add_Click({
    $diskConfigWindow.Tag = "Back"
    $diskConfigWindow.Close()
})
$btnDiskClose.Add_Click({
    $ownerWindow = $diskConfigWindow.Owner
    $diskConfigWindow.Tag = "ClosingAll"
    $diskConfigWindow.Close()
    if ($null -ne $ownerWindow) {
        $ownerWindow.Close()
    }
})
$diskConfigWindow.Add_Closing({
    if ($diskConfigWindow.Tag -ne "Back" -and $diskConfigWindow.Tag -ne "ClosingAll" -and $null -ne $diskConfigWindow.Owner) {
        $diskConfigWindow.Tag = "ClosingAll"
        $diskConfigWindow.Owner.Close()
    }
})
$btnNext.Add_Click({
    $diskConfigWindow.Owner = $myForm
    $diskConfigWindow.Tag = $null
    $diskConfigWindow.ShowDialog() | Out-Null
})

$myForm.FindName("btnClose").add_click({
    $myForm.Close()
})

# Ensure the vCenter connection exists before any vSphere action is attempted.
$vcServer = $env:VCENTER_SERVER
if ([string]::IsNullOrWhiteSpace($vcServer)) {
    $vcServer = Read-Host "Enter the vCenter server name or IP"
}
$vcUser = $env:VCENTER_USERNAME
if ([string]::IsNullOrWhiteSpace($vcUser)) {
    $vcUser = Read-Host "Enter the vCenter username"
}
$vcPassword = $env:VCENTER_PASSWORD
if ([string]::IsNullOrWhiteSpace([string]$vcPassword)) {
    $vcPassword = Read-Host "Enter the vCenter password" -AsSecureString
}

Import-Module VMware.VimAutomation.Core -ErrorAction Stop
if ($null -eq $global:DefaultVIServer) {
    Connect-VIServer -Server $vcServer -User $vcUser -Password $vcPassword -ErrorAction Stop | Out-Null
}

#Fill the ComboBoxes
#List of Folders from vSphere
$tbVMfolder.DisplayMemberPath = "Name"
Get-Folder -Type VM | Where-Object { $_.Name -notin @("vm", "vCLs") } | Sort-Object Name | ForEach-Object {
    [void]$tbVMfolder.Items.Add($_)
}
if ($tbVMfolder.Items.Count -gt 0) {
    $tbVMfolder.SelectedIndex = 0
}

# OS and version / distribution choices
[void]$tblOS.Items.Add("Windows")
[void]$tblOS.Items.Add("Linux")
$tblOS.add_SelectionChanged({
    $tblOSVersion.Items.Clear()
    $versions = switch ($tblOS.SelectedItem) {
        "Windows" { $windowsList }
        "Linux" { $linuxList }
        default { @() }
    }
    foreach ($version in $versions) {
        [void]$tblOSVersion.Items.Add($version)
    }
    if ($tblOSVersion.Items.Count -gt 0) {
        $tblOSVersion.SelectedIndex = 0
    }
})
$tblOS.SelectedIndex = 0

# CPU choices
$cpuOptions = @(1, 2, 4, 8, 16, 32)
foreach ($cpu in $cpuOptions) {
    [void]$tbCpu.Items.Add($cpu)
}
$tbCpu.SelectedIndex = 0

# Core choices
$coreOptions = @(1, 2, 3, 4, 6, 8, 12, 16, 24, 32)
foreach ($core in $coreOptions) {
    [void]$tbCore.Items.Add($core)
}
$tbCore.SelectedIndex = 0

# Memory choices in GB
$memoryOptions = @(1, 2, 3, 4, 6, 8, 16, 24, 32, 64, 96, 128, 512)
foreach ($memory in $memoryOptions) {
    [void]$tbMemory.Items.Add($memory)
}
$tbMemory.SelectedIndex = 0

#List of Datastores
$tblDatastore.DisplayMemberPath = "Name"
Get-Datastore | Sort-Object Name | ForEach-Object {
    [void]$tblDatastore.Items.Add($_)
}
if ($tblDatastore.Items.Count -gt 0) {
    $tblDatastore.SelectedIndex = 0
}

#List of Hosts
$tblHost.DisplayMemberPath = "Name"
Get-VMHost | Where-Object { $_.ConnectionState -eq 'Connected' } | Sort-Object Name | ForEach-Object {
    $hostOption = [PSCustomObject]@{
        Name = $_.Name.Split(".")[0]
        VMHost = $_
    }
    [void]$tblHost.Items.Add($hostOption)
}
if ($tblHost.Items.Count -gt 0) {
    $tblHost.SelectedIndex = 0
}

function Get-DatastoreIso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Datastore
    )

    $datastoreBrowser = Get-View -Id $Datastore.ExtensionData.Browser -ErrorAction Stop
    $searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
    $searchSpec.MatchPattern = @("*.iso", "*.ISO")
    $searchSpec.Query = @((New-Object VMware.Vim.IsoImageFileQuery))

    $searchResults = $datastoreBrowser.SearchDatastoreSubFolders(
        "[$($Datastore.Name)]",
        $searchSpec
    )

    foreach ($folderResult in $searchResults) {
        foreach ($file in $folderResult.File) {
            [PSCustomObject]@{
                Name = "$($Datastore.Name): $($folderResult.FolderPath)$($file.Path)"
                IsoPath = "$($folderResult.FolderPath)$($file.Path)"
            }
        }
    }
}

$tbISO.DisplayMemberPath = "Name"
$script:selectedIso = $null
$tbISO.Add_SelectionChanged({
    $script:selectedIso = $tbISO.SelectedItem
})

$btnFetchISO.Add_Click({
    $btnFetchISO.IsEnabled = $false
    $tbISO.Items.Clear()
    try {
        $datastoresToSearch = @(Get-Datastore -ErrorAction Stop | Sort-Object Name)
        if ($datastoresToSearch.Count -eq 0) {
            throw "No vSphere datastores are available to search."
        }

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
            catch {
                $isoSearchFailures += "$($isoDatastore.Name): $($_.Exception.Message)"
            }
        }

        $tbISO.SelectedIndex = -1
        & $updateDeploymentProgress 100 "ISO search complete. Found $isoCount file(s)."

        if ($isoSearchFailures.Count -gt 0) {
            $failureDetails = $isoSearchFailures -join [Environment]::NewLine
            [System.Windows.MessageBox]::Show(
                "ISO search found $isoCount file(s), but could not search some datastores:`n$failureDetails",
                "ISO search incomplete",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
        }
    }
    catch {
        & $updateDeploymentProgress 0 "ISO search failed."
        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            "ISO search failed",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    finally {
        $btnFetchISO.IsEnabled = $true
    }
})

# Guest OS identifiers used by vSphere when creating the VM.
$guestIdBySelection = @{
    "Windows|Windows 10" = "windows9_64Guest"
    "Windows|Windows 11" = "windows11_64Guest"
    "Windows|Windows 2016" = "windows2016srv_64Guest"
    "Windows|Windows 2019" = "windows2019srv_64Guest"
    "Windows|Windows 2022" = "windows2022srv_64Guest"
    "Windows|Windows 2025" = "windows2025srv_64Guest"
    "Linux|Ubuntu 20" = "ubuntu64Guest"
    "Linux|Ubuntu 21" = "ubuntu64Guest"
    "Linux|Ubuntu 22" = "ubuntu64Guest"
    "Linux|Debian 10" = "debian10_64Guest"
    "Linux|Debian 11" = "debian11_64Guest"
    "Linux|Debian 12" = "debian12_64Guest"
    "Linux|Debian 15" = "otherLinux64Guest"
    "Linux|Suse 15" = "sles15_64Guest"
    "Linux|OpenSuse Leap 42" = "opensuse64Guest"
    "Linux|OpenSuse Leap 15" = "opensuseLeap15_64Guest"
    "Linux|Red Hat 7" = "rhel7_64Guest"
    "Linux|Red Hat 8" = "rhel8_64Guest"
    "Linux|Red Hat 9" = "rhel9_64Guest"
    "Linux|Cent OS 7" = "centos7_64Guest"
    "Linux|Cent OS 8" = "centos8_64Guest"
    "Linux|Cent OS 9 Stream" = "centosStream9_64Guest"
    "Linux|Oracle Linux 7" = "oracleLinux7_64Guest"
    "Linux|Oracle Linux 8" = "oracleLinux8_64Guest"
    "Linux|Oracle Linux 9" = "oracleLinux9_64Guest"
    "Linux|Fedora 36" = "fedora64Guest"
    "Linux|Fedora 37" = "fedora64Guest"
    "Linux|Fedora 38" = "fedora64Guest"
}
$guestIdFallbacksBySelection = @{
    "Windows|Windows 10" = @(
        "windows9_64Guest",
        "windows8_1_64Guest",
        "windows8_64Guest"
    )
    "Windows|Windows 11" = @(
        "windows10_64Guest",
        "windows9_64Guest",
        "windows8_1_64Guest"
    )
    "Windows|Windows 2016" = @(
        "windows2019srv_64Guest",
        "windows2012srv_64Guest",
        "windows9_64Guest",
        "windows8srv_64Guest"
    )
    "Windows|Windows 2019" = @(
        "windows2016srv_64Guest",
        "windows2012srv_64Guest",
        "windows9_64Guest"
    )
    "Windows|Windows 2022" = @(
        "windows2019srv_64Guest",
        "windows2016srv_64Guest",
        "windows9_64Guest"
    )
    "Windows|Windows 2025" = @(
        "windows2022srv_64Guest",
        "windows2019srv_64Guest",
        "windows2016srv_64Guest",
        "windows9_64Guest"
    )
}

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
    $ProgressWindow.Dispatcher.Invoke(
        [Action] { $ProgressWindow.UpdateLayout() },
        [Windows.Threading.DispatcherPriority]::Background
    )
}

$btnDiskDeploy.Add_Click({
    $createdVM = $null
    $btnDiskDeploy.IsEnabled = $false
    try {
        & $updateDeploymentProgress 5 "Validating selections..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
        $vmName = $tbVMName.Text.Trim()
        $folder = $tbVMfolder.SelectedItem
        $osType = [string]$tblOS.SelectedItem
        $osVersion = [string]$tblOSVersion.SelectedItem
        $datastore = $tblDatastore.SelectedItem
        $hostOption = $tblHost.SelectedItem
        $guestKey = "$osType|$osVersion"

        if ([string]::IsNullOrWhiteSpace($vmName)) {
            throw "Enter a VM name."
        }
        if ($null -eq $folder -or $null -eq $datastore -or $null -eq $hostOption) {
            throw "Select a VM folder, connected ESXi host, and datastore."
        }
        if (-not $guestIdBySelection.ContainsKey($guestKey)) {
            throw "The selected operating system and version are not supported."
        }

        $requestedGuestId = $guestIdBySelection[$guestKey]
        & $updateDeploymentProgress 15 "Checking ESXi guest support..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
        $computeResource = Get-View -Id $hostOption.VMHost.ExtensionData.Parent -Property EnvironmentBrowser -ErrorAction Stop
        if ($null -eq $computeResource.EnvironmentBrowser) {
            throw "Could not find the selected ESXi host's VM environment browser."
        }
        $environmentBrowser = Get-View -Id $computeResource.EnvironmentBrowser -ErrorAction Stop
        $defaultConfigOption = $environmentBrowser.QueryConfigOptionDescriptor() |
            Where-Object { $_.DefaultConfigOption } |
            Select-Object -First 1
        if ($null -eq $defaultConfigOption) {
            throw "Could not determine the selected ESXi host's supported VM hardware configuration."
        }

        $vmConfigOption = $environmentBrowser.QueryConfigOption(
            $defaultConfigOption.Key,
            $hostOption.VMHost.ExtensionData.MoRef
        )
        $guestDescriptors = @($vmConfigOption.GuestOSDescriptor)
        $selectedGuestId = $requestedGuestId
        $selectedGuestDescriptor = $guestDescriptors |
            Where-Object { $_.Id -eq $requestedGuestId } |
            Select-Object -First 1

        if ($null -eq $selectedGuestDescriptor) {
            $fallbackGuestIds = @($guestIdFallbacksBySelection[$guestKey])
            $fallbackDescriptor = $null
            foreach ($fallbackGuestId in $fallbackGuestIds) {
                $fallbackDescriptor = $guestDescriptors |
                    Where-Object { $_.Id -eq $fallbackGuestId } |
                    Select-Object -First 1
                if ($null -ne $fallbackDescriptor) {
                    break
                }
            }

            if ($null -eq $fallbackDescriptor) {
                $supportedWindowsProfiles = @(
                    $guestDescriptors |
                        Where-Object { $_.Id -match 'windows|win' } |
                        ForEach-Object { $_.Id } |
                        Sort-Object -Unique
                )
                if ($supportedWindowsProfiles.Count -eq 0) {
                    $supportedWindowsProfiles = @("No Windows guest profiles were returned by the selected ESXi host.")
                }
                throw "The selected ESXi host does not support guest profile '$requestedGuestId'. No configured compatible fallback profile was found. Windows profiles reported by the host: $($supportedWindowsProfiles -join ', ')."
            }

            $fallbackName = $fallbackDescriptor.FullName
            if ([string]::IsNullOrWhiteSpace($fallbackName)) {
                $fallbackName = $fallbackDescriptor.Id
            }
            $fallbackChoice = [System.Windows.MessageBox]::Show(
                "The selected ESXi host does not support the '$osVersion' guest profile. Use '$fallbackName' instead? The VM will remain powered off.",
                "Guest profile not supported",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($fallbackChoice -ne [System.Windows.MessageBoxResult]::Yes) {
                & $updateDeploymentProgress 0 "Deployment cancelled." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
                return
            }
            $selectedGuestId = $fallbackDescriptor.Id
            $selectedGuestDescriptor = $fallbackDescriptor
        }
        $selectedGuestProfileName = $selectedGuestDescriptor.FullName
        if ([string]::IsNullOrWhiteSpace($selectedGuestProfileName)) {
            $selectedGuestProfileName = $selectedGuestDescriptor.Id
        }

        $socketCount = [int]$tbCpu.SelectedItem
        $coresPerSocket = [int]$tbCore.SelectedItem
        if ($socketCount -lt 1 -or $coresPerSocket -lt 1) {
            throw "Select a positive number of sockets and cores per socket."
        }
        $totalCpuCount = $socketCount * $coresPerSocket

        if ($null -eq $tbMemory.SelectedItem) {
            throw "Select the amount of memory in GB."
        }
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
        if ($diskSizesGB.Count -eq 0) {
            throw "Set the disk count and enter a capacity for every disk."
        }
        $diskStorageFormat = switch ($cbDiskType.SelectedItem) {
            "Thin" { "Thin" }
            "Thick (lazy zeroed)" { "Thick" }
            default { throw "Select a valid VMware disk provisioning type." }
        }
        $selectedIso = $script:selectedIso
        if ($null -ne $selectedIso -and [string]::IsNullOrWhiteSpace($selectedIso.IsoPath)) {
            throw "The selected ISO does not have a valid vSphere datastore path. Fetch the ISO list again and select an image."
        }

        & $updateDeploymentProgress 35 "Preparing VM configuration..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
        $newVMParams = @{
            Name = $vmName
            VMHost = $hostOption.VMHost
            Datastore = $datastore
            Location = $folder
            GuestId = $selectedGuestId
            NumCpu = $totalCpuCount
            MemoryGB = $memoryGB
            DiskGB = $diskSizesGB[0]
            DiskStorageFormat = $diskStorageFormat
            ErrorAction = "Stop"
        }
        & $updateDeploymentProgress 45 "Creating powered-off VM..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
        $createdVM = New-VM @newVMParams
        & $updateDeploymentProgress 70 "Applying CPU configuration..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
        Set-VM -VM $createdVM -CoresPerSocket $coresPerSocket -Confirm:$false -ErrorAction Stop | Out-Null

        for ($diskIndex = 1; $diskIndex -lt $diskSizesGB.Count; $diskIndex++) {
            $progress = 70 + [math]::Round((($diskIndex / $diskSizesGB.Count) * 25), 0)
            & $updateDeploymentProgress $progress "Adding disk $($diskIndex + 1) of $($diskSizesGB.Count)..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
            New-HardDisk -VM $createdVM -Datastore $datastore -CapacityGB $diskSizesGB[$diskIndex] -StorageFormat $diskStorageFormat -ErrorAction Stop | Out-Null
        }

        $cdDrive = Get-CDDrive -VM $createdVM -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $cdDrive) {
            if ($null -ne $selectedIso) {
                & $updateDeploymentProgress 96 "Adding CD/DVD drive and configuring selected ISO..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
                New-CDDrive -VM $createdVM -IsoPath $selectedIso.IsoPath -StartConnected -ErrorAction Stop | Out-Null
            }
            else {
                & $updateDeploymentProgress 96 "Adding CD/DVD drive..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
                New-CDDrive -VM $createdVM -ErrorAction Stop | Out-Null
            }
            $cdDrive = Get-CDDrive -VM $createdVM -ErrorAction Stop | Select-Object -First 1
        }
        if ($null -eq $cdDrive) {
            throw "A CD/DVD drive could not be added to VM '$vmName'."
        }

        if ($null -ne $selectedIso) {
            & $updateDeploymentProgress 96 "Configuring selected ISO to connect at power-on..." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
            Set-CDDrive -CD $cdDrive -IsoPath $selectedIso.IsoPath -StartConnected:$true -Confirm:$false -ErrorAction Stop | Out-Null
            $expectedIsoPath = ([string]$selectedIso.IsoPath).Trim().Replace("/", "\")
            $vmConfigView = Get-View -Id $createdVM.Id -Property Config.Hardware.Device -ErrorAction Stop
            $configuredCDDrive = $vmConfigView.Config.Hardware.Device |
                Where-Object { $_ -is [VMware.Vim.VirtualCdrom] } |
                Where-Object {
                    $_.Backing -is [VMware.Vim.VirtualCdromIsoBackingInfo] -and
                    ([string]$_.Backing.FileName).Trim().Replace("/", "\") -ieq $expectedIsoPath -and
                    $_.Connectable.StartConnected -eq $true
                } |
                Select-Object -First 1
            if ($null -eq $configuredCDDrive) {
                $cdDriveState = @($vmConfigView.Config.Hardware.Device |
                    Where-Object { $_ -is [VMware.Vim.VirtualCdrom] } |
                    ForEach-Object {
                        $backingPath = $null
                        if ($_.Backing -is [VMware.Vim.VirtualCdromIsoBackingInfo]) {
                            $backingPath = $_.Backing.FileName
                        }
                        "ISO='$backingPath', StartConnected=$($_.Connectable.StartConnected), Connected=$($_.Connectable.Connected)"
                    }
                ) -join "; "
                throw "The CD/DVD drive was not saved with ISO '$($selectedIso.Name)' attached and set to connect at power-on. Current CD/DVD configuration: $cdDriveState"
            }
        }

        $createdVM = Get-VM -Id $createdVM.Id -ErrorAction Stop
        if ($createdVM.PowerState -ne "PoweredOff") {
            throw "VM '$vmName' should remain powered off after deployment, but its current state is '$($createdVM.PowerState)'."
        }

        $guestProfileMessage = ""
        if ($selectedGuestId -ne $requestedGuestId) {
            $guestProfileMessage = " The host-compatible guest profile '$selectedGuestProfileName' was used instead of '$osVersion'."
        }
        $isoMessage = " No ISO was selected."
        if ($null -ne $selectedIso) {
            $isoMessage = " ISO '$($selectedIso.Name)' is mounted and configured to connect when the VM is powered on."
        }
        & $updateDeploymentProgress 100 "Deployment complete." $pbDiskDeployment $txtDiskDeploymentStatus $diskConfigWindow
        $btnDiskDeploy.IsEnabled = $false
        [System.Windows.MessageBox]::Show(
            "VM '$vmName' was created on '$($hostOption.Name)' using datastore '$($datastore.Name)' with $socketCount socket(s), $totalCpuCount vCPU(s), and $($diskSizesGB.Count) $diskStorageFormat disk(s). It is powered off.$isoMessage$guestProfileMessage",
            "VM deployment complete",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    }
    catch {
        $txtDiskDeploymentStatus.Text = "Deployment failed."
        $message = $_.Exception.Message
        if ($null -ne $createdVM) {
            $message = "VM '$($createdVM.Name)' was created, but a later configuration step failed: $message"
        }
        [System.Windows.MessageBox]::Show(
            $message,
            "VM deployment failed",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    finally {
        if ($null -eq $createdVM) {
            $btnDiskDeploy.IsEnabled = $true
        }
    }
})

$myForm.ShowDialog()
