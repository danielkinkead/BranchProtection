using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$Request = $Request.Body # Setting the request to the body of the payload
$action  = $Request.action # What action did the log show?
$username = "testdkinkead" # Set the username of the GitHub user we want to mention in the issue
Write-Host "Action Type:" $Request.action # What type of event is this?
Write-Host "Repository Name:" $Request.repository.name # What is the repo name?
Write-Host "Private Repository:" $Request.repository.private # Is this a private repo?

# Header for GitHub API
$ghToken = $env:ghToken # This is pulling the GitHub token from the Application Settings in Azure
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]" # Setting up the object for the headers
$headers.Add("Accept", "application/vnd.github.v3+json") # This is the recommended accept statement according to the GitHub docs to use the REST API
$headers.Add("Authorization", "Basic $ghToken") # Add the auth token
$headers.Add("Content-Type", "application/json") # Setting the content-type

$ghRepoName = $Request.repository.name # Setting the repo name

# This function configures the branch protection by requiring a pull request where one approver is required and the restrictions are all applied to administrators
function ConfigureBranchProtection {
    $bodyConfigureProtection = "{
    `n    `"required_status_checks`": null,
    `n    `"enforce_admins`": true,
    `n    `"required_pull_request_reviews`": {
    `n        `"dismissal_restrictions`": {},
    `n        `"dismiss_stale_reviews`": false,
    `n        `"require_code_owner_reviews`": false,
    `n        `"required_approving_review_count`": 1
    `n    },
    `n    `"restrictions`": null
    `n}"
    
# Sending response to GitHub API
    $response = Invoke-RestMethod "https://api.github.com/repos/danielkinkead/$ghRepoName/branches/main/protection" -Method 'PUT' -Headers $headers -Body $bodyConfigureProtection
    $response | ConvertTo-Json
}

# Creating README.md file and content is base64 encoded
function DummyCommit {
    $bodyDummyCommit = "{
    `n  `"branch`": `"main`", 
    `n  `"message`": `"README.md file created to create a branch`",
    `n  `"content`": `"UGxlYXNlIGFkZCBhIHJlYWwgUkVBRE1FLm1kIGZpbGU=`"
    `n}"

# Sending response to GitHub API
    $response = Invoke-RestMethod "https://api.github.com/repos/danielkinkead/$ghRepoName/contents/README.md" -Method 'PUT' -Headers $headers -Body $bodyDummyCommit
    $response | ConvertTo-Json
}

# Creating issue with what has been added and making sure to @ mention a GitHub username that we defined
function CreateIssue {
    $bodyCreateIssue = "{
    `n    `"title`": `"Branch Protection added to $ghRepoName`",
    `n    `"body`": `"Require a pull request and require one approval before merging as well as including the restrictions on administrators branch protections were added @$username`"
    `n}"

# Sending response to GitHub API
    $response = Invoke-RestMethod "https://api.github.com/repos/danielkinkead/$ghRepoName/issues" -Method 'POST' -Headers $headers -Body $bodyCreateIssue
    $response | ConvertTo-Json
}
if ($action -eq "created") # Checking to see if a repo has been created
{
    try { # First tries to configure branch protection and then will create an issue
        Write-Host Configuring branch protection  - $ghRepoName
    ConfigureBranchProtection
    CreateIssue
    }
    catch { # If unable to create branch protection due to no branches exisiting this will create the README.md file, config branch protection, and then create the issue
        Write-Host No branches exist, creating dummy commit to initialize branch.
        DummyCommit
        ConfigureBranchProtection
        CreateIssue
    }
    finally { # Write to the Azure Functions log stream.
        Write-Host Branch protection configured
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $Request
})
