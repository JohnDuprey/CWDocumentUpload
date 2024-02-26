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
            $Results = Invoke-RestMethod -Uri $env:RewstWebhook -Headers $Headers -TimeoutSec 90 -ErrorAction Stop
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
            if ($Message.receivedDateTime -lt (Get-Date).AddMinutes(-10).ToUniversalTime()) {
                $MessagesNotProcessing = $true
            }
        }
        if ($MessagesNotProcessing) {
            $Message = ":warning: There are $(($Results.messages | Where-Object {($_.receivedDateTime | Get-Date) -lt (Get-Date).AddMinutes(-10)}| Measure-Object).Count) messages in the Email Connector inbox that have not been processed for over 10 minutes. <$($env:EmailConnectorInbox)|Open Inbox>"
        }
    } else {
        if ($Results.succeeded -eq $false) {
            $Message = ":warning: The connection to the Email Connector inbox was unsuccessful, check the workflow execution logs for more details. <$($env:RewstExecutionLogs)|Execution Logs>"
        }

        if (!$Results) {
            $Message = ':warning: The connection to Rewst was unsuccessful. Check to see if there are any service issues. <https://app.rewst.io|Open Rewst>'
        }
    }
} catch {
    $Message = ':warning: The connection to Rewst was unsuccessful. Check to see if there are any service issues. <https://app.rewst.io|Open Rewst> ```Exception: {0}```' -f $_.Exception.Message
}

if ($Message) {
    $Json = @{
        'text' = $Message
    } | ConvertTo-Json -Compress

    Invoke-RestMethod -Uri $env:SlackAlertWebhook -Method Post -Body $Json
}
