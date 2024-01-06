using namespace System.Net

function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)
    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    $FunctionName = 'Invoke-{0}' -f $Request.Params.Endpoint

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }

    & $FunctionName @HttpTrigger
}

function Receive-QueueTrigger {
    Param($QueueItem, $TriggerMetadata)
    $APIName = $QueueItem.FunctionName
    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    $FunctionName = 'Push-{0}' -f $APIName
    $QueueTrigger = @{
        QueueItem       = $QueueItem
        TriggerMetadata = $TriggerMetadata
    }

    & $FunctionName @QueueTrigger
}

Export-ModuleMember -Function @('Receive-HttpTrigger', 'Receive-QueueTrigger')

