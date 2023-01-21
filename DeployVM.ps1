Add-Type -AssemblyName presentationframework
[xml]$xaml=@'
<?xml version="1.0" encoding ="utf-16"?>
<Window 
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
Name="VMDeploy" Title="VM Deploy" Height="452" Width="464" WindowStartupLocation="CenterScreen" Background="#FFDFE084" IsHitTestVisible="False" WindowStyle="None" ResizeMode="NoResize">
<Grid Background="#FFB5B188" Width="464" Margin="0,0,0,1">
        <GroupBox Name="gbServer" Height="287" Margin="6,112,5,0" VerticalAlignment="Top" Header=" VM Caracteristics"/>
        <TextBlock Name="lblVMfolder" HorizontalAlignment="Left" Margin="26,165,0,0" TextWrapping="Wrap" Text="Folder >>" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="16"/>
        <TextBlock Name="lblVMName" HorizontalAlignment="Left" Margin="26,135,0,0" TextWrapping="Wrap" Text="Name &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="60" Height="16"/>
        <TextBlock Name="lblCPU" HorizontalAlignment="Left" Margin="88,313,0,0" TextWrapping="Wrap" Text="# of CPUs >>" VerticalAlignment="Top" Height="16" Width="80" FontFamily="Consolas"/>
        <TextBlock Name="lblDisk1" HorizontalAlignment="Left" Margin="38,266,0,0" TextWrapping="Wrap" Text="Disk 1 >>" VerticalAlignment="Top" Width="60" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblCore" HorizontalAlignment="Left" Margin="246,313,0,0" TextWrapping="Wrap" Text="# of Cores >>" VerticalAlignment="Top" Width="86" Height="16" FontFamily="Consolas"/>
        <TextBlock Name="lblDisk2" HorizontalAlignment="Left" Margin="244,266,0,0" TextWrapping="Wrap" Text="Disk 2 >>" VerticalAlignment="Top" Width="60" Height="16" FontFamily="Consolas"/>
        <ComboBox Name="tbVMOSBo" Width="344" Height="22" Margin="92,161,0,0" HorizontalAlignment="Left" Grid.Column="0" Grid.Row="0" VerticalAlignment="Top" FontFamily="Consolas" />
        <TextBlock Name="lblOS" Margin="26,196,0,0" TextWrapping="Wrap" Text="Operation System >>" VerticalAlignment="Top" FontFamily="Consolas" Width="126" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblOS" Width="282" Height="22" Margin="154,192,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <TextBlock Name="lblOSVersion" Margin="26,229,0,0" TextWrapping="Wrap" Text="Virsion / Distribution >>" VerticalAlignment="Top" FontFamily="Consolas" Width="166" Height="16" HorizontalAlignment="Left"/>
        <TextBox Name="tbVMName" HorizontalAlignment="Left" Margin="92,132,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="344" Height="22" FontFamily="Consolas"/>
        <Rectangle HorizontalAlignment="Center" Height="41" Margin="0,254,0,0" Stroke="Black" VerticalAlignment="Top" Width="408"/>
        <TextBox Name="tbDisk1" HorizontalAlignment="Left" Margin="102,265,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="112" Height="18" FontFamily="Consolas"/>
        <TextBox Name="tbDisk2" HorizontalAlignment="Left" Margin="308,265,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="112" Height="18" FontFamily="Consolas"/>
        <TextBlock Name="lblCapacity1" HorizontalAlignment="Left" Margin="198,267,0,0" TextWrapping="Wrap" Text="GB" VerticalAlignment="Top" Width="16" Height="13" FontFamily="Consolas" FontSize="10"/>
        <TextBlock Name="lblCapacity2" HorizontalAlignment="Left" Margin="404,267,0,0" TextWrapping="Wrap" Text="GB" VerticalAlignment="Top" Width="16" Height="13" FontFamily="Consolas" FontSize="10"/>
        <Rectangle HorizontalAlignment="Center" Height="37" Margin="0,302,0,0" Stroke="Black" VerticalAlignment="Top" Width="318"/>
        <TextBox Name="tbCpu" HorizontalAlignment="Left" Margin="182,311,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="36" Height="18" FontFamily="Consolas"/>
        <TextBox Name="tbCore" HorizontalAlignment="Left" Margin="336,311,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="40" Height="18" FontFamily="Consolas"/>
        <Rectangle HorizontalAlignment="Center" Height="40" Margin="0,346,0,0" Stroke="Black" VerticalAlignment="Top" Width="432" RenderTransformOrigin="0.514,6.348"/>
        <TextBlock Name="lblDatastore" Margin="22,358,0,0" TextWrapping="Wrap" Text="Datastore &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="80" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblDatastore" Width="140" Height="22" Margin="110,355,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <TextBlock Name="lblHost" Margin="254,358,0,0" TextWrapping="Wrap" Text="Host &gt;&gt;" VerticalAlignment="Top" FontFamily="Consolas" Width="48" Height="16" HorizontalAlignment="Left"/>
        <ComboBox Name="tblHost" Width="136" Height="22" Margin="304,355,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" />
        <Button Name="btnClose" HorizontalAlignment="Left" Margin="390,412,0,0" VerticalAlignment="Top" Width="68" Height="26" FontFamily="Consolas" Content="Close"/>
        <ComboBox Name="tblOSVersion" Height="22" Margin="198,226,28,0" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" FontFamily="Consolas" Width="238" />
        <Rectangle HorizontalAlignment="Center" Height="94" Stroke="Black" VerticalAlignment="Top" Width="452" Margin="0,4,0,0"/>
        <Label Content="Deploy VMware VM" HorizontalAlignment="Left" Margin="147,26,0,0" VerticalAlignment="Top" FontFamily="Britannic Bold" FontSize="36" Width="303" FontWeight="Bold"/>
        <Image HorizontalAlignment="Left" Height="77" Margin="15,12,0,0" VerticalAlignment="Top" Width="87"/>

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