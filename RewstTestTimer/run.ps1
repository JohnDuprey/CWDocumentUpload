using namespace System.Net

param($Timer)

$Headers = @{
    'x-rewst-secret' = $env:RewstSecret
    'Accept'         = 'application/json'
}


try {
    $Success = $false
    $Count = 0
    do {
        try {
            $Results = Invoke-RestMethod -Uri $env:RewstWebhook -Headers $Headers -TimeoutSec 120 -ErrorAction Stop
            $Success = $true
        } catch {
            $Count++
            Start-Sleep -Seconds 5
        }
    } while (!$Success -and $Count -lt 4)
    
    $Message = $false
    if (($Results.messages | Measure-Object).Count -gt 0) {
        $MessagesNotProcessing = $false
        foreach ($Message in $Results.messages) {
            if ((Get-Date $Message.receivedDateTime) -lt (Get-Date).AddMinutes(-10)) {
                $MessagesNotProcessing = $true
            }
        }
        if ($MessagesNotProcessing) {
            $Text = ":warning: There are $(($Results.messages | Where-Object {(Get-Date $_.receivedDateTime) -lt (Get-Date).AddMinutes(-10)}| Measure-Object).Count) messages in the Email Connector inbox that have not been processed for over 10 minutes. <$($env:EmailConnectorInbox)|Open Inbox>"
        }
    } else {
        if ($Results.succeeded -eq $false) {
            $Text = ":warning: The connection to the Email Connector inbox was unsuccessful, check the workflow execution logs for more details. <$($env:RewstExecutionLogs)|Execution Logs>"
        }

        if (!$Results) {
            $Text = ':warning: The connection to Rewst was unsuccessful. Check to see if there are any service issues. <https://app.rewst.io|Open Rewst>'
        }
    }
} catch {
    $Text = ':warning: The connection to Rewst was unsuccessful. Check to see if there are any service issues. <https://app.rewst.io|Open Rewst> ```Exception: {0}```' -f $_.Exception.Message
}

if ($Text) {
    $Json = @{
        'text' = $Text
    } | ConvertTo-Json -Compress
    Write-Host $Json
    Invoke-RestMethod -Uri $env:SlackAlertWebhook -Method Post -Body $Json
}
