## Issue

Our security team is asking for help ensuring proper reviews are being done to code being added into our repositories. We have hundreds of repositories in our organization. What is the best way we can achieve at scale? We are new to some of the out-of-the-box settings and the GitHub API. Can you please help us create a solution that will accomplish this for our security team?

## How to Solve

For this issue I am using an Azure Function App to capture the webhook and run some PowerShell code to add a README.md (if needed), add branch protections, and then creating an issue in the repo with an @ mention to a GitHub user with the protections we added.  You need the following:

1. GitHub Organization account
2. Personal Access Token for the account you can admin the organization account
3. Function App in Azure
4. Webhook created under GitHub Organization account

## Getting Started

1. Create GitHub Personal Access Token
   * Login to GitHub and goto `Account Settings -> Developer Settings -> Personal Access Tokens`
   * Click on `Generate new token`
   * Provide a note on what the token is for and give permissions for `Repo` and click on `Generate token`
   * Make sure you save the personal access token as we will need it for the next step
2. Create Function App in Azure
   * From Azure portal click on `New Resource`
   * In the search box search for `function app` and click on `create` in there
   * Set the runtime stack to be `PowerShell Core` and provide a name, resource group, and region for your app and the click on `Review+create` and the click on `Create` on the next screen
   * Once the app has been created, click on `Go to resource`
   * Click on `Configuration` under the Settings menu on the left
   * Click on `+New application setting`
   * The name will be `ghToken` and the value will be your `GitHub username:Personal Access Token` that has been encoded in base64 and then click `OK`
   * Click on `Save` near the top of the screen and then click on `Continue`
   * Click on `Functions` and then click on `Create`
   * Select `HTTP trigger` under the "Select a template" header and click on `Create'
   * Click on `Get Function URL` near the top of the screen and copy the URL that it provides you
   * Click on `Code + Test` under "Developer" near the left hand side
   * Verify the dropdown is on `run.ps1` and then replace the contents of that file with the contents from my repo
   * Click on `Save` near the top of the screen
3. Create Webhook in GitHub
   * Under the settings of the GitHub Organization account click on `Webhooks` and then click on `Add Webhook`
   * For `Payload URL` provide the Function URL you got from Azure
   * For `Content type` set it to `application/json`
   * Under "Which events would you like to trigger this webhook?" select `Let me select individual events.` and only check off `Repositories` and uncheck everything else.
   * Make sure to keep the `Active` checkbox selected as we want this webhook to fire
   * Click on `Add webhook`

## Testing everything out
1. Create a new repo
2. Monitor the logs of the Function App on Azure to see what is going on
3. Verify that the new branch has the protections
4. Verify that an issue has been created

## References
* https://www.wesleyhaakman.org/using-azure-functions-to-configure-github-branch-protection/
* https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
* https://docs.microsoft.com/en-us/azure/azure-functions/functions-get-started?pivots=programming-language-powershell
* https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api
* https://www.base64encode.org/
 
   
