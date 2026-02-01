Describe "Set-TemplateRepository" {
    BeforeAll {
        $script:RepoName    = "test-repo"
        $script:IsTemplate  = "true"
        $script:IsTemplateF = "false"
        $script:Owner       = "test-owner"
        $script:Token       = "fake-token"
        $script:MockApiUrl  = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
    BeforeEach {
        $env:GITHUB_OUTPUT = "$PSScriptRoot/github_output.temp"
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        $env:MOCK_API = $script:MockApiUrl
    }
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Variable -Name MOCK_API -Scope Global -ErrorAction SilentlyContinue
    }

    It "succeeds with HTTP 200 for is_template true" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 200; Content = '{"name":"test-repo","is_template":true}' }
        }
        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=success"
    }

    It "succeeds with HTTP 200 for is_template false" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 200; Content = '{"name":"test-repo","is_template":false}' }
        }
        Set-TemplateRepository -RepoName $RepoName -IsTemplate "false" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=success"
    }

    It "fails with HTTP 404 (repository not found)" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 404; Content = '{"message":"Not Found"}' }
        }
        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Failed to set repository to template status true. HTTP Status: 404"
    }

    It "fails with invalid is_template value" {
        Set-TemplateRepository -RepoName $RepoName -IsTemplate "invalid-value" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Invalid IsTemplate value 'invalid-value'. Must be 'true' or 'false'."
    }

    It "fails with empty repo_name" {
        Set-TemplateRepository -RepoName "" -IsTemplate "true" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
    }

    It "fails with empty is_template" {
        Set-TemplateRepository -RepoName $RepoName -IsTemplate "" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
    }

    It "fails with empty owner" {
        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner "" -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
    }

    It "fails with empty token" {
        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner $Owner -Token ""
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
    }
	
	It "writes result=failure and error-message on exception" {
		Mock Invoke-WebRequest { throw "API Error" }

		try {
			Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner $Owner -Token $Token
		} catch {}

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Where-Object { $_ -match "^error-message=Error: Failed to set $RepoName to template status true\. Exception:" } |
			Should -Not -BeNullOrEmpty
	}
}