function Invoke-CWDocUpload {
    Param(
        $Parameters,
        $FileName,
        $FileContentType,
        $FileContent
    )
    [string]$BaseUri = 'https://{0}/v4_6_Release/apis/3.0/{1}' -f $env:CWHost, 'system/documents'
    [string]$Authstring = $env:CWCompany + '+' + $env:CWPublicKey + ':' + $env:CWPrivateKey
    $encodedAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)))

    $Headers = @{
        'Authorization' = "Basic $encodedAuth"
        'Accept'        = 'application/vnd.connectwise.com+json'
        'clientId'      = $env:CWClientID
    }

    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()

    foreach ($Parameter in $Parameters.Keys) {
        $paramHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
        $paramHeader.name = $Parameter
        $paramContent = [System.Net.Http.StringContent]::new($Parameters.$Parameter)
        $paramContent.Headers.ContentDisposition = $paramHeader
        $multipartContent.Add($paramContent)
    }

    $FileBytes = [System.Convert]::FromBase64String($FileContent)
    $fileMs = New-Object System.IO.MemoryStream -ArgumentList (, $FileBytes)

    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
    $fileHeader.Name = 'file'
    $fileHeader.FileName = $FileName

    $fileContent = [System.Net.Http.StreamContent]::new($fileMs)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($FileContentType)
    $fileContent.Headers.ContentLength = $fileMs.Length
    $multipartContent.Add($fileContent)

    $Upload = @{
        Uri         = $BaseUri
        Headers     = $Headers
        Method      = 'Post'
        Body        = $multipartContent
        ContentType = 'multipart/form-data'
    }

    Invoke-RestMethod @Upload -SkipHttpErrorCheck
}
