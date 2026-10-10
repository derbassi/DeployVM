<#
    Description: 
    This script removes a user from all groups associated with a specific AD OU..

    Autherization:
    The script must run in the context of an account with write permissions in Active Directory.

    ChangeLog:
    21.01.2019 - Version 1.0: Script creation
    19.08.2019 - Version 1.1: Adding email dispatch for VISIR users
    11.10.2019 - Version 1.2: Hinzufügen des Mailversands bei VISIR Usern
    03.02.2020 - Version 1.3: Adjust the GUI (everything in one window)
    01.02.2020 - Version 1.4: Admin accounts are checked and deactivated.
#>

#region function
$xaml = @'
<?xml version="1.0" encoding="utf-16"?>
<Window x:Name="Window" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="500" Height="460" MinHeight="460" MinWidth="500" ResizeMode="NoResize" SizeToContent="Height" Title="Remove-FromADGrpoup" WindowStartupLocation="CenterScreen">
	<Grid Margin="0,0,0,0">
		<Label x:Name="UserLable" Content="AD User" Width="60" Height="26" Margin="20,20,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" />
		<TextBox x:Name="UserBox" Width="90" Height="22" Margin="80,20,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" />
		<Label x:Name="OULable" Content="AD OU" Width="60" Height="26" Margin="200,20,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Column="0" Grid.Row="0" />
		<TextBox x:Name="OUBox" Width="90" Height="22" Margin="280,20,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" IsTabStop="False" Grid.Column="0" Grid.Row="0" />
		<TextBox x:Name="OutputBox" Width="450" Height="310" Margin="20,60,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" HorizontalContentAlignment="Left" HorizontalScrollBarVisibility="Auto" IsReadOnly="True" IsTabStop="False" Language="de-de" Text="" VerticalScrollBarVisibility="Auto" Grid.Column="0" Grid.Row="0" />
		<Button x:Name="But1" Content="weiter" Width="75" Height="20" Margin="0,0,20,20" HorizontalAlignment="Right" VerticalAlignment="Bottom" Grid.Column="0" Grid.Row="0" />
		<Button x:Name="But2" Content="zurück" Width="75" Height="20" Margin="0,0,120,20" HorizontalAlignment="Right" VerticalAlignment="Bottom" Visibility="Hidden" Grid.Column="0" Grid.Row="0" />
	</Grid>
</Window>
'@

function Write-Log {

  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]
    [string]$Inhalt
  )
  
  $FileExists = Test-Path -Path $LogFile
  $DateNow = Get-Date -Format 'dd.MM.yyyy HH:mm' # Determines the current date with this syntax: 01.10.2013 10:00
  $FileInp = $DateNow + ' | ' + $Inhalt # Constructs the line for our logfile
  if (!($FileExists)) # If the file exists, write into it.
  { 
    $Null = New-Item -Path $Logfile -ItemType file # If the file doesn't exist, create it.
  }
  Add-Content -Path $LogFile -Value $FileInp  # Append the line to the existing entries.
}
function Get-ADGroupNames {

  param(
    [Parameter(Mandatory, 
    ValueFromPipeline)]
    [Microsoft.ActiveDirectory.Management.ADUser]$Identity
  )

  Get-ADUser -Identity $Identity -Properties PrimaryGroup, MemberOf |
  Select-Object -Property @{Name='Gruppen'; Expression={ @($_ |
  Select-Object -ExpandProperty PrimaryGroup; $_ | Select-Object -ExpandProperty MemberOf)}} |
  Select-Object -ExpandProperty Gruppen
}
function Convert-XAMLtoWindow {
  param
  (
    [Parameter(Mandatory)]
    [string]
    $XAML
  )
  
  Add-Type -AssemblyName PresentationFramework
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  $reader.Close()
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  while ($reader.Read())
  {
    $name=$reader.GetAttribute('Name')
    if (!$name) { $name=$reader.GetAttribute('x:Name') }
    if($name)
    {$result | Add-Member -MemberType NoteProperty -Name $name -Value $result.FindName($name) -Force}
  }
  $reader.Close()
  $result
}
function Show-WPFWindow {
  param
  (
    [Parameter(Mandatory)]
    [Windows.Window]
    $Window
  )
  $null = $window.Dispatcher.InvokeAsync{
    $null = $window.ShowDialog()
  }.Wait()
}
$Window = Convert-XAMLtoWindow -XAML $xaml 
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
#endregion function

#region Variables
$ScriptName = ($MyInvocation.MyCommand.Name).Split('.')[0].Trim() # Script Name:
$logfile = 'D:\Tools\Data\Remove-FromADGroup.log' # Name and location of the logfile
$OU = '628' # The Organizational Unit (OU) being worked in
$Date = Get-Date -Format 'yyyy_MM_dd' # Current date
$Button = 'Weiter','Entfernen','Zurück' # Button labels
$Specialarea = 'VISIR' # Area for where the emails should be sent
$Special = 'vis' # Filter for special tasks
$Special2 = 'ViEng' # Filter for special tasks
$SMTPserver = 'derbazi.net' # The outgoing mail server used at Daimler
$ITMailbox = 'itAdmin@tbessa.lan' # Mailbox from which the email is sent
$To = 'ADAdmin@tbessa.lan' # Email address for topics with special tasks
$MailBodyStart = "Dear All, `n`n" # Beginning of the email text
$MailBodyEnd = "`n`nBest Regards `n`nIT - Administration`nYOUR Company" # End of the email text

$Window.Title = $ScriptName 
$null = $window.UserBox.Focus()
$Window.OUBox.Text = $OU # Standard entry for the OU
$Window.But1.Content = $Button[0] # Label of the first button
$Window.But2.Content = $Button[2] # Label of the second button
$Window.OutputBox.Text = 'Removing an AD user account from the permission groups of an OU'
#endregion Variables

#region main
try
{
  Import-Module -Name ActiveDirectory -ErrorAction Stop
}
catch
{
  $null = [Windows.MessageBox]::Show("Module could not be loaded! `nThere is no access to the Active Directory.. ",$ScriptName,'OK','Error')
  return
}
Write-Output '########## Script start ##########' | Write-Log
Write-Output "Script was started as: $env:USERNAME"| Write-Log
$Window.But1.add_Click(
  {
    $ADUser = $Window.UserBox.Text
    $ADOU = $Window.OUBox.Text
    try
    {
      Get-ADUser -Identity $ADUser -ErrorAction Stop
    }
    catch
    {
      Write-Output "User $ADUser does not exist in the AD." | Write-Log
      $Window.OutputBox.Text = "User $ADUser does not exist in the AD."
      return
    }
    try
    {
      $ADAdminuser = Get-ADUser -Identity "ESTR_$($OU)_a_$ADUser" -Properties Description -ErrorAction Stop
    }
    catch
    {
    }
    $Groups = Get-ADGroupNames -Identity $ADUser -ErrorAction SilentlyContinue  | Where-Object {($_ -like "*OU=$ADOU*")}
    if ($Window.But1.Content -eq $Button[0])
    {
      if (($Groups -eq $null) -and (($ADAdminuser -eq $Null) -or ($ADAdminuser.Enabled -eq $false)))
      {
        Write-Output "User $ADUser has no permissions below the ADOU $ADOU" | Write-Log
        $Window.OutputBox.Text = "User $ADUser has no permissions below the ADOU $ADOU"
      }
      else 
      {
        $ADGroup = @()
        ForEach ($Group in $Groups)
        {
          $Groupsplit = $Group.Split('=')
          $Groupsplit = $Groupsplit[1].split(',')
          $ADGroup += "`n" + $Groupsplit[0]
        }
    
        # Query whether the action (removal from groups) should be performed
        $Window.OutputBox.Text =''
        if ($ADGroup)
        {
          $Window.OutputBox.Text ="The User $ADUser is being removed from the following groups: $ADGroup `n"
        }
        if ($ADAdminuser.Enabled -eq $true)
        {
          $Window.OutputBox.Text += "The Adminuser $($ADAdminuser.Name) being deactivated."
        }
        $Window.But1.Content = $Button[1] 
        $Window.But2.Visibility = 0
        $Window.UserBox.IsEnabled = $false
        $Window.OUBox.IsEnabled = $false
      }
    }
    elseif ($Window.But1.Content -eq $Button[1])
    {
      $Window.But1.IsEnabled = $false
      $Window.OutputBox.Text =''
      if ($Groups)
      {
        #Write-Output "User $ADUser was removed from the following groups in the ADOU $ADOU:" | Write-Log
        #$Window.OutputBox.Text = "User $ADUser was removed from the following groups in the ADOU $ADOU:"
        ForEach ($Group in $Groups)
        {
          # Removes the user from the AD groups
          $Window.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
          Remove-ADGroupMember -Identity $Group -Members $ADUser -Confirm:$false
          Write-Output "$Group" | Write-Log
          $Window.OutputBox.AddText("`n$Group")
        
          if (($Group -like "*$Special*") -or ($Group -like "*$Special2*"))
          {
            $Specialflag = $true
          }
        }
      }
      if ($ADAdminuser.Enabled -eq $true)
      {
        Set-ADUser -Identity $ADAdminuser.Name -Enabled $false -Description "User left company, deactivated on $Date by $env:USERNAME, $($ADAdminuser.Description)"
        $Window.OutputBox.Text += "User $($ADAdminuser.Name) was deactivated."
        Write-Output "User $ADAdminuser was deactivated" | Write-Log
      }
      if ($Specialflag -eq $true)
      {
        $MailSubject = "User $ADUser in $Specialarea Area"
        $MailBodyMid = "The user $ADUser (from the $Specialarea area) has been removed from group memberships in the OU $($Window.OUBox.Text) removed. `n Please check if further actions are necessary."
        $MailBody = "$MailBodyStart$MailBodyMid$MailBodyEnd"
        try
        {
          Send-MailMessage -To $To `
          -Cc $ITMailbox `
          -From $ITMailbox `
          -Body $Mailbody `
          -Subject $MailSubject `
          -SmtpServer $SMTPserver `
          -Encoding ([System.Text.Encoding]::UTF8) -ErrorAction Stop
  
          Write-Output "Mail sent successfully to: $To with the Subject $MailSubject."| Write-Log
          $Window.OutputBox.AddText("Mail sent successfully to: $To with the Subject $MailSubject")
        }
        catch
        {
          Write-Output "Error: Mail delivery failed to: $To with the Subject $MailSubject." | Write-Log
          $Window.OutputBox.AddText("Error: Mailversandt fehlgeschlagen an: $To mit dem Subject $MailSubject.")
        }
      }
    }
  }
)
$Window.But2.add_Click(
  {
    $Window.UserBox.IsEnabled = $true
    $Window.UserBox.Text = ''
    $Window.UserBox.Focus()
    $Window.OUBox.IsEnabled = $true
    $Window.OutputBox.Text = 'Removing an AD user account from the permission groups of an OU'
    $Window.But1.IsEnabled = $true
    $Window.But1.Content = $Button[0] 
    $Window.But2.Visibility = 1
  }
)
$null = Show-WPFWindow -Window $Window # Opens the GUI
Write-Output '########## Skript end ##########' | Write-Log
#endregion main