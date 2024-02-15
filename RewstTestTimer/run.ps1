using namespace System.Net

param($Timer)

$Headers = @{
    'x-rewst-secret' = $env:RewstSecret
    'Accept'         = 'application/json'
}

$Results = Invoke-RestMethod -Uri $env:RewstWebhook -Headers $Headers -SkipHttpErrorCheck

$Message = $false
if (($Results.messages | Measure-Object).Count -gt 0) {
    $MessagesNotProcessing = $false
    foreach ($Message in $Results.messages) {
        if (($Message.receivedDateTime | Get-Date) -lt (Get-Date).AddMinutes(-10)) {
            $MessagesNotProcessing = $true
        }
    }
    if ($MessagesNotProcessing) {
        $Message = ":warning: There are $(($Results.messages | Measure-Object).Count) messages in the Email Connector inbox that have not been processed for over 10 minutes. <$($env:EmailConnectorInbox)|Open Inbox>"
    }
} else {
    if ($Results.succeeded -eq $false) {
        $Message = ":warning: The connection to the Email Connector inbox was unsuccessful, check the workflow execution logs for more details. <$($env:RewstExecutionLogs)|Execution Logs>"
    }

    if (!$Results) {
        $Message = ':warning: The connection to Rewst was unsuccessful. Check to see if there are any service issues. <https://app.rewst.io|Open Rewst>'
    }
}

if ($Message) {
    $Json = @{
        'text' = $Message
    } | ConvertTo-Json -Compress

    Invoke-RestMethod -Uri $env:SlackAlertWebhook -Method Post -Body $Json
}
