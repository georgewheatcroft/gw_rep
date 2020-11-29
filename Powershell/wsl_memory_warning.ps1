#This is a script I made to monitor WSL2's usage of ram, as it currently has a tendancy to not release cached ram
# - this will send you a desktop toast notification (a la other windows notifications) when it detects WSL2 is being greedy
# - one can always set a hard limit on their WSL2's ram usage, but I prefer to just run a script to force it to drop cached ram when 
#   this script alerts me
# - on task scheduler (windows app that runs tasks on defined schedule), use something like this for "action": 
#   Powershell.exe -File C:\Documents\powershell\wsl_memory_warning.ps1 -WindowStyle Hidden
# - "-WindowStyle Hidden" is how one avoids seeing a powershell console open up each time this runs (annoying)

#check to see if VS code is running - this always eats up tons of ram via the wsl2 VM - if so, quit and ignore
$code_ps = Get-Process -Name Code
if($?){
    echo "vs code is running - quit"
    exit 0
}

# ok vs code can't be running - there's no excuse for using lots of ram so....
$Title = "WSL Memory Warning"
$limit = 2500.00 #in MB, set this based on your prefs.
$APP_ID = 'your-generated-gui-string' #get this from Powershell command New-Guid
$VMmemory = Get-Process -Name vmmem | Select-Object -First 2 -Property @{Name='vmmem';Expression={($_.PM/1MB)}}

foreach ($reading in $VMmemory){ ##sometimes get multiple readings for the same process (long story). but at least one (the max num) will be relevant
    if ($reading.vmmem -gt $limit) {
        #necessary boiler plate
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null

        #round it up nicely
            $reading.vmmem =  [math]::Round($reading.vmmem)

            #we all love xml don't we
            $ToastTemplate = '
            <toast launch="app-defined-string">
                <visual>
                    <binding template="ToastText02">
                        <text id="1">'+$Title+'</text>
                        <text id="2">wsl mem use at '+$reading.vmmem+'MB</text>
                    </binding>
                </visual>
            </toast>'
            
            #shoot it off and trigger the visual alert
            $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            $xml.LoadXml($ToastTemplate)
            $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($APP_ID).Show($toast)
    }
}
