param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod
        
        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $responseJson = $null
        $statusCode = 200

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # PATCH /repos/:owner/:repo
        if ($method -eq "PATCH" -and $path -match '^/repos/([^/]+)/([^/]+)$') {
            $owner = $Matches[1]
            $repo = $Matches[2]
            
            $headers = $request.Headers
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $requestBody = $reader.ReadToEnd()
            $reader.Close()
            Write-Host "Request headers: $($headers | Out-String)"
            Write-Host "Request body: $requestBody"

            $bodyObj = $null
            try { $bodyObj = $requestBody | ConvertFrom-Json } catch { $bodyObj = $null }
            $isTemplate = $bodyObj.is_template

            if ($null -eq $isTemplate -or ($isTemplate -isnot [bool])) {
                $statusCode = 400
                $responseJson = @{ message = "Bad Request: is_template must be a boolean" } | ConvertTo-Json
            }
            elseif ($owner -eq "test-owner" -and $repo -eq "test-repo") {
                $statusCode = 200
                $responseJson = @{ name = $repo; is_template = $isTemplate } | ConvertTo-Json
            }
            elseif ($repo -eq "existing-repo") {
                $statusCode = 403
                $responseJson = @{ message = "Forbidden: Repository cannot be modified" } | ConvertTo-Json
            }
            else {
                $statusCode = 404
                $responseJson = @{ message = "Not Found: Repository or owner does not exist" } | ConvertTo-Json
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json
        }
        
        # Send response
        $response.StatusCode = $statusCode
        $response.ContentType = "application/json"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}