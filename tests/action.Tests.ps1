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
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
	    It "unit: Set-TemplateRepository succeeds with HTTP 200 for is_template true" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 200; Content = '{"name":"test-repo","is_template":true}' }
	        }
	        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }
	
	    It "unit: Set-TemplateRepository succeeds with HTTP 200 for is_template false" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 200; Content = '{"name":"test-repo","is_template":false}' }
	        }
	        Set-TemplateRepository -RepoName $RepoName -IsTemplate "false" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }
	}

	Context "Failure Cases" {
	    It "unit: Set-TemplateRepository fails with HTTP 404" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 404; Content = '{"message":"Not Found"}' }
	        }
	        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Error: Failed to set repository to template status true. HTTP Status: 404"
	    }
	}

	Context "Parameter Validation Failure Cases" {
		It "unit: Set-TemplateRepository fails with invalid is_template value" {
	        Set-TemplateRepository -RepoName $RepoName -IsTemplate "invalid-value" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Invalid IsTemplate value 'invalid-value'. Must be 'true' or 'false'."
	    }
	
	    It "unit: Set-TemplateRepository fails with empty RepoName" {
	        Set-TemplateRepository -RepoName "" -IsTemplate "true" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
	    }
	
	    It "unit: Set-TemplateRepository fails with empty IsTemplate" {
	        Set-TemplateRepository -RepoName $RepoName -IsTemplate "" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
	    }
	
	    It "unit: Set-TemplateRepository fails with empty Owner" {
	        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner "" -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
	    }
	
	    It "unit: Set-TemplateRepository fails with empty Token" {
	        Set-TemplateRepository -RepoName $RepoName -IsTemplate "true" -Owner $Owner -Token ""
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: RepoName, IsTemplate, Owner, and Token must be provided."
	    }	
	}

	Context "Exception Failure Cases" {
		It "unit: Set-TemplateRepository fails with exception" {
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
}
