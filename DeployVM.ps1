Add-Type -AssemblyName presentationframework
[xml]$xaml=@'
<?xml version="1.0" encoding ="utf-16"?>
<Window 
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
Name="VMCreation" Title="VM Creation" Height="342" Width="464" WindowStartupLocation="CenterScreen" Background="#FFDFE084"  WindowStyle="None" ResizeMode="NoResize">
    <Grid Background="#FFB5B188" Width="464" Margin="0,0,-2,-6">
        <GroupBox Name="gbServer" Height="287" Margin="5,6,6,0" VerticalAlignment="Top" Header=" VM Caracteristics"/>
        <TextBlock Name="lblVMfolder" HorizontalAlignment="Left" Margin="25,59,0,0" TextWrapping="Wrap" Text="Folder >>" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="16"/>
        <TextBlock Name="lblVMName" HorizontalAlignment="Left" Margin="25,31,0,0" TextWrapping="Wrap" Text="Name &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="22"/>
        <TextBlock Name="lblCPU" HorizontalAlignment="Left" Margin="88,207,0,0" TextWrapping="Wrap" Text="# of CPUs >>" VerticalAlignment="Top" Height="16" Width="80" FontFamily="Consolas"/>
        <TextBlock Name="lblDisk1" HorizontalAlignment="Left" Margin="38,160,0,0" TextWrapping="Wrap" Text="Disk 1 >>" VerticalAlignment="Top" Width="60" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblCore" HorizontalAlignment="Left" Margin="245,207,0,0" TextWrapping="Wrap" Text="# of Cores >>" VerticalAlignment="Top" Width="86" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblDisk2" HorizontalAlignment="Left" Margin="243,160,0,0" TextWrapping="Wrap" Text="Disk 2 >>" VerticalAlignment="Top" Width="60" Height="16" FontFamily="Consolas"/>
        <ComboBox Name="tbVMOS" Width="344" Height="22" Margin="92,55,0,0" HorizontalAlignment="Left" Grid.Column="0" Grid.Row="0" VerticalAlignment="Top" FontFamily="Consolas" />
        <TextBlock Name="lblOS" Margin="25,90,0,0" TextWrapping="Wrap" Text="Operation System >>" VerticalAlignment="Top" FontFamily="Consolas" Width="126" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblOS" Width="282" Height="22" Margin="154,86,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <ComboBox Name="tblOSVersion" Height="22" Margin="198,120,334,0" HorizontalAlignment="Left" Grid.Column="0" Grid.Row="0" VerticalAlignment="Top" FontFamily="Consolas" />
        <TextBlock Name="lblOSVersion" Margin="26,123,0,0" TextWrapping="Wrap" Text="Virsion / Distribution >>" VerticalAlignment="Top" FontFamily="Consolas" Width="166" Height="16" HorizontalAlignment="Left"/>
        <TextBox Name="tbVMName" HorizontalAlignment="Left" Margin="92,29,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="344" Height="18" FontFamily="Consolas"/>
        <Rectangle HorizontalAlignment="Left" Height="41" Margin="27,148,0,0" Stroke="Black" VerticalAlignment="Top" Width="408"/>
        <TextBox Name="tbDisk1" HorizontalAlignment="Left" Margin="101,159,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="112" Height="18" FontFamily="Consolas"/>
        <TextBox Name="tbDisk2" HorizontalAlignment="Left" Margin="307,159,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="112" Height="18" FontFamily="Consolas"/>
        <TextBlock Name="lblCapacity1" HorizontalAlignment="Left" Margin="198,161,0,0" TextWrapping="Wrap" Text="GB" VerticalAlignment="Top" Width="15" Height="13" FontFamily="Consolas" FontSize="10"/>
        <TextBlock Name="lblCapacity2" HorizontalAlignment="Left" Margin="403,161,0,0" TextWrapping="Wrap" Text="GB" VerticalAlignment="Top" Width="16" Height="13" FontFamily="Consolas" FontSize="10"/>
        <Rectangle HorizontalAlignment="Left" Height="37" Margin="73,196,0,0" Stroke="Black" VerticalAlignment="Top" Width="318"/>
        <TextBox Name="tbCpu" HorizontalAlignment="Left" Margin="174,205,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="36" Height="18" FontFamily="Consolas"/>
        <TextBox Name="tbCore" HorizontalAlignment="Left" Margin="336,205,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="40" Height="18" FontFamily="Consolas"/>
        <Rectangle HorizontalAlignment="Left" Height="40" Margin="15,240,0,0" Stroke="Black" VerticalAlignment="Top" Width="432" RenderTransformOrigin="0.514,6.348"/>
        <TextBlock Name="lblDatastore" Margin="25,252,0,0" TextWrapping="Wrap" Text="Datastore &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="88" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblDatastore" Width="140" Height="22" Margin="109,249,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <TextBlock Name="lblHost" Margin="255,252,0,0" TextWrapping="Wrap" Text="Host &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="48" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblHost" Width="136" Height="22" Margin="304,249,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <Button Name="btnClose" HorizontalAlignment="Left" Margin="389,306,0,0" VerticalAlignment="Top" Width="69" Height="26" FontFamily="Consolas" Content="Close"/>

        
    </Grid>
</Window>
'@


$myReader = (New-Object System.Xml.XmlNodeReader $xaml)
$myForm = [Windows.Markup.XamlReader]::Load($myReader)

# test to fill the ComboBox 
Get-Service | ForEach-Object {
                              $myForm.FindName("tblDatastore").items.Add($_.Name)
                              $myForm.FindName("tblDatastore").SelectedIndex = 0
                             }
                             
$myForm.FindName("btnClose").add_click({
    $myForm.Close()
})


$myForm.ShowDialog() 