Function Get-FileName($initialDirectory){   
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "Powershell Script (*.ps1)| *.ps1"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
 $Script:fileloc = $OpenFileDialog.filename
 $Percent = 20
$Progress.value = $Percent
$Form.Dispatcher.Invoke( "Render", [Windows.Input.InputEventHandler]{ $Progress.UpdateLayout() }, $null, $null)
}
Function Create-Launcher{
    New-Item "$env:TEMP\PowerProtect\exec.bat" -Type File -Force
    Clear-Content "$env:TEMP\PowerProtect\exec.bat" -Force
    Add-Content "$env:TEMP\PowerProtect\exec.bat" -Value 'powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File ".\bits.ps1"'
}
Function Create-Filler{
New-Item "$env:TEMP\PowerProtect\rand.fil" -Type File -Force
    Clear-Content "$env:TEMP\PowerProtect\rand.fil" -Force
    $randfill = Get-Random -Minimum 99999999
    $i = 100
    while($i -gt 0){
        $randfill--
        Add-Content "$env:TEMP\PowerProtect\rand.fil" -Value $randfill
        $i--
    }
}
Function Create-Wrapper([switch]$fill){
New-Item "$env:TEMP\PowerProtect\wrap.sed" -Type File -Force
Clear-Content "$env:TEMP\PowerProtect\wrap.sed" -Force
if($fill){
Set-Content "$env:TEMP\PowerProtect\wrap.sed" -Value @'
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=0
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
'@
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value "TargetName=$env:TEMP\PowerProtect\comp.exe"
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value @'
FriendlyName=title
AppLaunched=cmd.exe /c echo.
PostInstallCmd=cmd.exe /c exec.bat
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="bits.ps1"
FILE1="exec.bat"
FILE2="rand.fil"
[SourceFiles]
'@
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value "SourceFiles0=$env:TEMP\PowerProtect\"
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value @'
[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
'@
}
else{
Set-Content "$env:TEMP\PowerProtect\wrap.sed" -Value @'
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=0
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
'@
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value "TargetName=$env:TEMP\PowerProtect\comp.exe"
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value @'
FriendlyName=title
AppLaunched=cmd.exe /c echo.
PostInstallCmd=cmd.exe /c exec.bat
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="bits.ps1"
FILE1="exec.bat"
[SourceFiles]
'@
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value "SourceFiles0=$env:TEMP\PowerProtect\"
Add-Content "$env:TEMP\PowerProtect\wrap.sed" -Value @'
[SourceFiles0]
%FILE0%=
%FILE1%=
'@
}
$owd = Get-Location
Set-Location "$env:TEMP\PowerProtect"
& iexpress.exe /N /Q wrap.sed
Wait-Process -Name iexpress
Set-Location $owd
}
Function Compile([switch]$randomize){
    if($randomize){
        Create-Launcher
        Create-Filler
        Create-Wrapper -fill
    }
    $dest = Split-Path -Parent $file
    $leaf = (Split-Path -Leaf $file).Split(".")[0]
    Rename-Item "$env:Temp\PowerProtect\comp.exe" -NewName ("$leaf"+".exe") -Force
    Move-Item "$env:Temp\PowerProtect\$leaf.exe" -Destination $dest -Force
}
Function Evaluate($file){
    if($MD5Ck.IsChecked){
        $utfbytes  = [System.Text.Encoding]::Unicode.GetBytes((Get-Content $file -Raw))
        $base64 = [System.Convert]::ToBase64String($utfbytes)
        $cryptoServiceProvider = [System.Security.Cryptography.MD5CryptoServiceProvider];
        $hashAlgorithm = new-object $cryptoServiceProvider
        $hashByteArray = $hashAlgorithm.ComputeHash([Char[]]$base64);
        foreach ($byte in $hashByteArray) { $MD5 += “{0:X2}” -f $byte}
        $utfMD5  = [System.Text.Encoding]::Unicode.GetBytes($MD5)
        $baseMD5 = [System.Convert]::ToBase64String($utfMD5)
        New-Item "$env:TEMP\PowerProtect\bits.ps1" -Type file -Force
        Set-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value @'
$ErrorActionPreference = "SilentlyContinue"
'@
        Add-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "`$base64 = `"$base64`""
        Add-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "`$baseMD5 = `"$baseMD5`""
        Add-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value @'
$MD5 = ""
$origMD5 = ""
$script = $SCRIPT:MyInvocation.MyCommand.Path
$cryptoServiceProvider = [System.Security.Cryptography.MD5CryptoServiceProvider];
$hashAlgorithm = new-object $cryptoServiceProvider
$hashByteArray = $hashAlgorithm.ComputeHash([Char[]]$base64)
foreach ($byte in $hashByteArray) { $MD5 += “{0:X2}” -f $byte}
$origMD5 = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($baseMD5))
if($MD5 -eq $origMD5){
    powershell.exe -EncodedCommand $base64
}
else{
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("TAMPERING DETECTED. Will now delete.",0,"Warning!!!",0x0)
    Remove-Item $script -Force | Out-Null 
}
'@
        if($DualLayerCk.IsChecked){
            $utfbytes  = [System.Text.Encoding]::Unicode.GetBytes((Get-Content "$env:TEMP\PowerProtect\bits.ps1" -Raw))
            $base64 = [System.Convert]::ToBase64String($utfbytes)
            New-Item "$env:TEMP\PowerProtect\bits.ps1" -Type file -Force
            Set-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "`$ErrorActionPreference = `"SilentlyContinue`""
            Add-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "`$base64 = `"$base64`""
            Add-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "powershell.exe -EncodedCommand `$base64"
        }
    }
    else{
        $utfbytes  = [System.Text.Encoding]::Unicode.GetBytes((Get-Content $file -Raw))
        $base64 = [System.Convert]::ToBase64String($utfbytes)
        New-Item "$env:TEMP\PowerProtect\bits.ps1" -Type file -Force
        Set-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "`$ErrorActionPreference = `"SilentlyContinue`""
        Add-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "`$base64 = `"$base64`""
        Add-Content -Path "$env:TEMP\PowerProtect\bits.ps1" -Value "powershell.exe -EncodedCommand `$base64"
    }
    if($CompileCk.IsChecked){
        if($RandCompCk.IsChecked){
            Compile -randomize
        }
        else{
            Compile
        }
    }
    else{
        $dest = Split-Path -Parent $file
        $leaf = (Split-Path -Leaf $file).Split(".")[0]
        Rename-Item "$env:Temp\PowerProtect\bits.ps1" -NewName ("$leaf"+".secure"+".ps1") -Force
        Move-Item "$env:Temp\PowerProtect\$leaf.ps1" -Destination $dest -Force
    }
}
New-Item "$env:TEMP\PowerProtect\" -Type Directory -Force | Out-Null
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerProtect" Height="264" Width="525" WindowStyle="None" ResizeMode="NoResize" Background="#FF6554FB" Foreground="Black" WindowStartupLocation="CenterScreen">
    <Grid Margin="0,-1,0,1">
    	<Label Name="Title" Content="PowerProtect" VerticalAlignment="Top" Margin="10,10,10,0" HorizontalAlignment="Center" FontSize="32" FontFamily="Trebuchet MS" FontWeight="Bold" FontStyle="Italic"/>
    	<Label Name="Description" Content="Choose a Powershell script file that you would like to protect." HorizontalAlignment="Center" Margin="78,72.156,67,0" VerticalAlignment="Top" Width="380" FontFamily="Trebuchet MS" FontSize="13.333"/>
        
    	<TextBox Name="BrowseBox" HorizontalAlignment="Left" Height="23" Margin="10,97.636,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="425"/>
    	<Button Name="BrowseButton" Content="Browse" HorizontalAlignment="Left" Margin="440,97.636,0,0" VerticalAlignment="Top" Width="75" Height="23" FontFamily="Trebuchet MS" FontSize="13.333"/>
    	<GroupBox Name="Protections" Header="Protections" HorizontalAlignment="Left" Margin="10,120.636,0,0" VerticalAlignment="Top" Height="110" Width="245" FontFamily="Trebuchet MS" FontSize="13.333">
    		<StackPanel Height="88">
				<CheckBox Name="MD5Ck" Content="Use MD5 verification technique" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top"/>
				<Line StrokeThickness="3" Fill="White" Stroke="White" ClipToBounds="True" StrokeEndLineCap="Round" StrokeLineJoin="Round" Stretch="UniformToFill" Height="2" Margin="10,10,10,0" X1="100" HorizontalAlignment="Center" VerticalAlignment="Center"/>
				<CheckBox Name="CompileCk" Content="Compile as an executable" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top"/>
				<CheckBox Name="RandCompCk" Content="Randomize executable bytes" HorizontalAlignment="Left" Margin="29,10,0,0" VerticalAlignment="Top" Width="192.697"/>
			</StackPanel>
		</GroupBox>
    	<GroupBox Name="Miscellaneous" Header="Miscellaneous" HorizontalAlignment="Left" Margin="270,120.636,0,0" VerticalAlignment="Top" Height="110" Width="245" FontFamily="Trebuchet MS" FontSize="13.333">
    		<StackPanel Margin="0,0,0,-0.48">
				<CheckBox Name="RemCommentCk" Content="Remove comments from script" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top"/>
			</StackPanel>
		</GroupBox>
    	<Button Name="OkButton" Content="Do It!" HorizontalAlignment="Left" Margin="10,235.636,0,0" VerticalAlignment="Top" Width="425" FontFamily="Trebuchet MS" FontSize="13.333"/>
    	<Button Name="CancelButton" Content="Cancel" HorizontalAlignment="Left" Margin="440,235.636,0,0" VerticalAlignment="Top" Width="75" FontFamily="Trebuchet MS" FontSize="13.333"/>
    	<ProgressBar Name="Progress" HorizontalAlignment="Left" Height="4.48" Margin="0,261.116,0,-1.596" VerticalAlignment="Top" Width="525"/>
		<Grid HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" Width="568"/>
        <Expander Name="Help" Header="Help" HorizontalAlignment="Left" VerticalAlignment="Top">
        	<Grid Height="269" Background="White">
        		<TextBlock Name="HelpText" HorizontalAlignment="Left" TextWrapping="Wrap" VerticalAlignment="Top" TextTrimming="CharacterEllipsis" Margin="10,10,0,0" Height="259" Width="513"><Run Text="This program is provided as is without a warranty. Its creator is not responsible for how, what, why, when, or even where you use this program. This program is designed to minimize the risk of code plagiarism, this is not to say that it can prevent it completely(A determined enough person can still bypass the securities provided by this program). This program's native language(Powershell) is pre-baked into and guaranteed to run on any Windows 7 or higher systems. If this program does not function as intended please try updating Powershell. As a gentle reminder, depending on your computer's hardware it may take a minute to complete a task. The the output files will be saved to the same folder as the original; stored in a folder with the same name as the input script. If your script has arguments please specify them in the arguments box in this form:"/><LineBreak/><Run Text=""/><LineBreak/><Run Text="&#x9;-MyScriptArgument &quot;My Script Parameter&quot;"/><LineBreak/><Run/><LineBreak/><Run Text="If all else fails cursed are the GitHub gods."/><LineBreak/><Run/><Run Text=" "/><Hyperlink Name="Attribution" Cursor="Hand" Foreground="#FFAC8C18" FontWeight="ExtraBlack" ForceCursor="True" FontSize="16"><Run Text="©2015 LogoiLab (CuddlyCactusMC, MrCBax, PentestingForever)"/></Hyperlink></TextBlock>
        	</Grid>
        </Expander>
    </Grid>
</Window>
'@
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
$form=[Windows.Markup.XamlReader]::Load($reader)
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}
$CancelButton.Add_Click({
$Form.Close()
exit
})
$BrowseButton.Add_Click({
Get-FileName -initialDirectory "$env:HOMEPATH\Desktop"
$BrowseBox.Text = $fileloc
})
$Attribution.Add_Click({
start 'http://github.com/LogoiLab/PowerProtect-GUI'
})
$OkButton.Add_Click({
Evaluate -file $BrowseBox.Text
})
$BrowseBox.AcceptsReturn = $false
$ArgsBox.AcceptsReturn = $false
$Progress.value = 0
$Progress.Maximum = 100
$Form.Icon = [System.Convert]::FromBase64String('AAABAAQAEBAQAAAAAAAoAQAARgAAABAQAAAAAAAAaAUAAG4BAAAgIBAAAAAAAOgCAADWBgAAICAA
AAAAAACoCAAAvgkAACgAAAAQAAAAIAAAAAEABAAAAAAAwAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAA
AACAAACAAAAAgIAAgAAAAIAAgACAgAAAwMDAAICAgAAAAP8AAP8AAAD//wD/AAAA/wD/AP//AAD/
//8AAAAAEREAAAAAABETMREAAAARGAAAMREAERgABwAAMREYAAgHgAAAMQAICHeHAAAACIgHd4iI
AACIh3iHgAeIgIiIiHeHAAiAiIh3iIiICICIh3eAeIiIgIgIiHCHiAAAiPj4iIgHAIiCKIh3d4AA
iAAAiIiAAAAAAAAAiAAAAAD8P///8A///8AD//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//
AAD//wAA//8ABP//AAT///AP///8P///KAAAABAAAAAgAAAAAQAIAAAAAABAAQAAAAAAAAAAAAAA
AQAAAAAAAAAAAAAAAIAAAIAAAACAgACAAAAAgACAAICAAADAwMAAwNzAAPDKpgAEBAQACAgIAAwM
DAAREREAFhYWABwcHAAiIiIAKSkpAFVVVQBNTU0AQkJCADk5OQCAfP8AUFD/AJMA1gD/7MwAxtbv
ANbn5wCQqa0AAAAzAAAAZgAAAJkAAADMAAAzAAAAMzMAADNmAAAzmQAAM8wAADP/AABmAAAAZjMA
AGZmAABmmQAAZswAAGb/AACZAAAAmTMAAJlmAACZmQAAmcwAAJn/AADMAAAAzDMAAMxmAADMmQAA
zMwAAMz/AAD/ZgAA/5kAAP/MADMAAAAzADMAMwBmADMAmQAzAMwAMwD/ADMzAAAzMzMAMzNmADMz
mQAzM8wAMzP/ADNmAAAzZjMAM2ZmADNmmQAzZswAM2b/ADOZAAAzmTMAM5lmADOZmQAzmcwAM5n/
ADPMAAAzzDMAM8xmADPMmQAzzMwAM8z/ADP/MwAz/2YAM/+ZADP/zAAz//8AZgAAAGYAMwBmAGYA
ZgCZAGYAzABmAP8AZjMAAGYzMwBmM2YAZjOZAGYzzABmM/8AZmYAAGZmMwBmZmYAZmaZAGZmzABm
mQAAZpkzAGaZZgBmmZkAZpnMAGaZ/wBmzAAAZswzAGbMmQBmzMwAZsz/AGb/AABm/zMAZv+ZAGb/
zADMAP8A/wDMAJmZAACZM5kAmQCZAJkAzACZAAAAmTMzAJkAZgCZM8wAmQD/AJlmAACZZjMAmTNm
AJlmmQCZZswAmTP/AJmZMwCZmWYAmZmZAJmZzACZmf8AmcwAAJnMMwBmzGYAmcyZAJnMzACZzP8A
mf8AAJn/MwCZzGYAmf+ZAJn/zACZ//8AzAAAAJkAMwDMAGYAzACZAMwAzACZMwAAzDMzAMwzZgDM
M5kAzDPMAMwz/wDMZgAAzGYzAJlmZgDMZpkAzGbMAJlm/wDMmQAAzJkzAMyZZgDMmZkAzJnMAMyZ
/wDMzAAAzMwzAMzMZgDMzJkAzMzMAMzM/wDM/wAAzP8zAJn/ZgDM/5kAzP/MAMz//wDMADMA/wBm
AP8AmQDMMwAA/zMzAP8zZgD/M5kA/zPMAP8z/wD/ZgAA/2YzAMxmZgD/ZpkA/2bMAMxm/wD/mQAA
/5kzAP+ZZgD/mZkA/5nMAP+Z/wD/zAAA/8wzAP/MZgD/zJkA/8zMAP/M/wD//zMAzP9mAP//mQD/
/8wAZmb/AGb/ZgBm//8A/2ZmAP9m/wD//2YAIQClAF9fXwB3d3cAhoaGAJaWlgDLy8sAsrKyANfX
1wDd3d0A4+PjAOrq6gDx8fEA+Pj4APD7/wCkoKAAgICAAAAA/wAA/wAAAP//AP8AAAD/AP8A//8A
AP///wAAAAAAAAAjIyMjAAAAAAAAAAAAACMjIyoqIyMjAAAAAAAAIyMjdGxsbGwqIyMjAAAjIyN0
bGxs7xJsbGwqIyMjI3RsbGzsEgfrEhJsbGwqI2xsbOwS7PEH6+8SEhJsbGxs7OvsEvHxB+vs7OwS
AABs6+zr8fHr6wfrEhLv7OzrAOvs6+vr6/EH6+8SEhLs6xLr7Ovr7+/r6+vr6+sS7OsS6+zr7+/v
7BLv6+vr6+vrEuvrEuvs7AcS6+/r6xISEhLr6//r9Ovr6+vrEu8SAOvr6zMz6+vr7wcH7+sSEgDr
cQAAAADr6+vs7BISEgAAAAAAAAAAAADr6xISAAAAAAAA/D////AP///AA///AAD//wAA//8AAP//
AAD//wAA//8AAP//AAD//wAA//8AAP//AAT//wAE///wD////D///ygAAAAgAAAAQAAAAAEABAAA
AAAAgAIAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAACAAACAAAAAgIAAgAAAAIAAgACAgAAAwMDAAICA
gAAAAP8AAP8AAAD//wD/AAAA/wD/AP//AAD///8AAAAAAAAAAAEQAAAAAAAAAAAAAAAAAAETMRAA
AAAAAAAAAAAAAAEYgzMxEAAAAAAAAAAAAAEYiIMzMzEQAAAAAAAAAAEYiIiAAzMzMRAAAAAAAAEY
iIiACIADMzMxEAAAAAEYiIiACIiIgAMzMzEQAAEYiIiACIh3AIiAAzMzMRAYiIiACIiA94gIiIAD
MzMxGIiACIiIh/eIcAiIgAMzMRiACIiAh3f3iHdwCIiAAzEQCIiIAHd394h3d3AIiIABCIiIhwB3
d/eIeHeHcAiIgAiIh3cHd3f3iHiHd3eACIAIeId3d3eH94hwd3d4eIgACHiHd3eHh/eIcIB3d4iI
AAh4h3eHh3f3iHdwcHh4iAAIeIeHh3d394h3eHCAiIgACPiHh3d3eIeIiId3cHiIAAh4h3d3d3h4
h4iIh3eIiAAI+Id3d3d3cHd3eIiHeIgACPiHd393eHC7h3d4iIiIAAiIh3j/eH9wu7eHdwiAgAAI
iAiI+H93eId3d4cIiAgACAgAiP93eId4h3d3CACAgAgAAAj/eHd3d3gHdwAAgAAIIgAI+Id3d3d3
eAcAAIiACCIgCIiHd3d3d3iAAACIiAAAAAAIiId3d3iAAAAAAAAAAAAAAAiIh3iAAAAAAAAAAAAA
AAAACIiAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAD//n////gf///gB///gAH//gAAf/gAAB/gAAAH
gAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAGAAAABgAAAAYAAAAGAAAABgAAAAYAAAAGA
AAABgAAAAYAAAAGsAAA1vgAAd44AAHGGAABw/4AB///gB///+B////5//ygAAAAgAAAAQAAAAAEA
CAAAAAAAgAQAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAACAAACAAAAAgIAAgAAAAIAAgACAgAAAwMDA
AMDcwADwyqYABAQEAAgICAAMDAwAERERABYWFgAcHBwAIiIiACkpKQBVVVUATU1NAEJCQgA5OTkA
gHz/AFBQ/wCTANYA/+zMAMbW7wDW5+cAkKmtAAAAMwAAAGYAAACZAAAAzAAAMwAAADMzAAAzZgAA
M5kAADPMAAAz/wAAZgAAAGYzAABmZgAAZpkAAGbMAABm/wAAmQAAAJkzAACZZgAAmZkAAJnMAACZ
/wAAzAAAAMwzAADMZgAAzJkAAMzMAADM/wAA/2YAAP+ZAAD/zAAzAAAAMwAzADMAZgAzAJkAMwDM
ADMA/wAzMwAAMzMzADMzZgAzM5kAMzPMADMz/wAzZgAAM2YzADNmZgAzZpkAM2bMADNm/wAzmQAA
M5kzADOZZgAzmZkAM5nMADOZ/wAzzAAAM8wzADPMZgAzzJkAM8zMADPM/wAz/zMAM/9mADP/mQAz
/8wAM///AGYAAABmADMAZgBmAGYAmQBmAMwAZgD/AGYzAABmMzMAZjNmAGYzmQBmM8wAZjP/AGZm
AABmZjMAZmZmAGZmmQBmZswAZpkAAGaZMwBmmWYAZpmZAGaZzABmmf8AZswAAGbMMwBmzJkAZszM
AGbM/wBm/wAAZv8zAGb/mQBm/8wAzAD/AP8AzACZmQAAmTOZAJkAmQCZAMwAmQAAAJkzMwCZAGYA
mTPMAJkA/wCZZgAAmWYzAJkzZgCZZpkAmWbMAJkz/wCZmTMAmZlmAJmZmQCZmcwAmZn/AJnMAACZ
zDMAZsxmAJnMmQCZzMwAmcz/AJn/AACZ/zMAmcxmAJn/mQCZ/8wAmf//AMwAAACZADMAzABmAMwA
mQDMAMwAmTMAAMwzMwDMM2YAzDOZAMwzzADMM/8AzGYAAMxmMwCZZmYAzGaZAMxmzACZZv8AzJkA
AMyZMwDMmWYAzJmZAMyZzADMmf8AzMwAAMzMMwDMzGYAzMyZAMzMzADMzP8AzP8AAMz/MwCZ/2YA
zP+ZAMz/zADM//8AzAAzAP8AZgD/AJkAzDMAAP8zMwD/M2YA/zOZAP8zzAD/M/8A/2YAAP9mMwDM
ZmYA/2aZAP9mzADMZv8A/5kAAP+ZMwD/mWYA/5mZAP+ZzAD/mf8A/8wAAP/MMwD/zGYA/8yZAP/M
zAD/zP8A//8zAMz/ZgD//5kA///MAGZm/wBm/2YAZv//AP9mZgD/Zv8A//9mACEApQBfX18Ad3d3
AIaGhgCWlpYAy8vLALKysgDX19cA3d3dAOPj4wDq6uoA8fHxAPj4+ADw+/8ApKCgAICAgAAAAP8A
AP8AAAD//wD/AAAA/wD/AP//AAD///8AAAAAAAAAAAAAAAAAAAAAIyMAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAIyMqKiMjAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyN0dCoqKiojIwAAAAAA
AAAAAAAAAAAAAAAAAAAAIyN0dHR0KioqKioqIyMAAAAAAAAAAAAAAAAAAAAAIyN0dHR0dHRsbCoq
KioqKiMjAAAAAAAAAAAAAAAAIyN0dHR0dHRsbHFxbGwqKioqKiojIwAAAAAAAAAAIyN0dHR0dHRs
bHFxcXFxcWxsKioqKioqIyMAAAAAIyN0dHR0dHRsbHFxcbzvEhJxcXFsbCoqKioqKiMjACN0dHR0
dHRsbHFxcXES9Afs6xJxcXFxbGwqKioqKiojI3R0dHRsbHR0dHHs7PH0B+zr7xIScXFxcWxsKioq
KiMjdHRsbHFxdHQS7PHx8f8H7Ovv7+8SEnFxcXFsbCoqIyNsbHFxcXHsEhLx8fHx9Afs6+/v7+/v
EhJxcXFxbGwjbHFxcXHs7PESEvG8vPH/B+zr7+zv7+zv7xIScXFxcWxscXHs67zx8RLx8fHx8fQH
7Ovv7Ozv7+/v7+wAAHFxbADrvOzrvPHx8fHx8evx/wfs6+8S7+/v7+/s7+zr7GwAAOu87Ou88fHx
8evx6/H/B+zr7xLsEu/v7+/s7OvsAAAA6/Hs67zx8evx6/G88fQH7Ovv7+8S7xLv7O/s6+wSAADr
8ezrvOvx6/Hx8fHx9Afs6+/v7+zvEuwS7Ozr7BIAAOv07Ou86/Hx8fHv7+vrB+zr6+vr7+/v7xLv
7OvsEgAA6/Hs67zx8fHv7+/v7PHr6+/s6+vr6+/v7+zs6+wSAADr9OzrvLzv7+/v8Qfx8RLv7+/v
7+vr6+vv7+zr7BIAAOv07Ovv7+/v9PHx8ezxEvv76+/v7+/r6+vr7OvsEgAA6+zs6+/v6/T08ewH
//ES+/v77+vv7+8S6+sS6xISAADr6+sS6+vr9OwH//Hx8evr7+/v7+/r7xLr6+sS6xIAAOsA6wAA
6+v0//Hx8evr7+/r6+/v7+/vEusAAOsA6wAA6wAAAAAA6/T08evv7++8vO/v6xLv7+8SAAAA6wAA
AADrMzMAAADr9Ovr77y8B7wHB7zv7+sS7xIAAADrcXEAAOszMzMAAOvr7Ozv77y8BwcHvO/v7OwS
EgAAAOtxcXEAAAAAAAAAAADr6+zs7++8vO/v7OwSEgAAAAAAAAAAAAAAAAAAAAAAAAAA6+vs7O/v
7OwSEgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOvr7OwSEgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAADrEgAAAAAAAAAAAAAAAAAAAP/+f///+B///+AH//+AAf/+AAB/+AAAH+AAAAeAAAABAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAYAAAAGAAAABgAAAAYAAAAGAAAABgAAAAYAAAAGAAAAB
gAAAAawAADW+AAB3jgAAcYYAAHD/gAH//+AH///4H////n//')
$Form.ShowDialog() | out-null