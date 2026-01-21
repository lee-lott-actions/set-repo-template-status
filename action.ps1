function Set-TemplateRepository {
    param(
        [string]$RepoName,
        [string]$IsTemplate,
        [string]$Owner,
        [string]$Token
    )

    # Validate required parameters
    if ([string]::IsNullOrEmpty($RepoName) -or
        [string]::IsNullOrEmpty($IsTemplate) -or
        [string]::IsNullOrEmpty($Owner) -or
        [string]::IsNullOrEmpty($Token)) {
        Write-Output "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    # Convert IsTemplate to lowercase for API compatibility
    $IsTemplate = $IsTemplate.ToLower()

    # Validate IsTemplate value
    if ($IsTemplate -ne "true" -and $IsTemplate -ne "false") {
        Write-Output "Error: Invalid IsTemplate value '$IsTemplate'. Must be 'true' or 'false'."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Invalid IsTemplate value '$IsTemplate'. Must be 'true' or 'false'."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    Write-Host "Attempting to set repository '$RepoName' to template status '$IsTemplate' for owner '$Owner'"

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/repos/$Owner/$RepoName"

    $headers = @{
        Authorization        = "Bearer $Token"
        Accept               = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent"         = "pwsh-action"
        "Content-Type"       = "application/json"
    }

    $jsonBody = @{ is_template = [bool]::Parse($IsTemplate) } | ConvertTo-Json

    try {
        Write-Host "Sending PATCH request to $uri"
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Patch -Body $jsonBody

        if ($response.StatusCode -eq 200) {
            Write-Host "Successfully set $RepoName to template status $IsTemplate"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
            Write-Host "Error: Failed to set $RepoName to template status $IsTemplate. HTTP Status: $($response.StatusCode)"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to set repository to template status $IsTemplate. HTTP Status: $($response.StatusCode)"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        }
    } catch {
        $httpStatus = $_.Exception.Response.StatusCode.value__
        Write-Host "Error: Failed to set $RepoName to template status $IsTemplate. HTTP Status: $httpStatus"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to set repository to template status $IsTemplate. HTTP Status: $httpStatus"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    }
}