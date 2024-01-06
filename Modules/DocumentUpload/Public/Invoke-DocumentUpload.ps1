using namespace System.Net
function Invoke-DocumentUpload {
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $Parameters = @{
        recordId   = $Request.Body.record_id
        recordType = $Request.Body.record_type
        title      = $Request.Body.attachment_name
    }
    #Write-Host (ConvertTo-Json -InputObject $Request.Body)

    $DocUpload = @{
        Parameters      = $Parameters
        FileName        = $Request.Body.attachment_name
        FileContentType = $Request.Body.content_type
        FileContent     = $Request.Body.attachment
    }

    $Response = Invoke-CWDocUpload @DocUpload

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $Response
        })
}