# df19-6secrets
Six Secrets of Service Cloud Success: Entitlements Automation

Code and configuration examples as utilised in the above Dreamforce19 Theatre session. You are free to use, re-use, copy and disseminate this repo at your own risk. Provar and myself provide no warranty, support or maintenance for the examples in this repository, they are there as examples on what can be done and should be revised for your own use case before implementing in your Salesforce orgs.

Updates coming on 18th November ahead of Dreamforce 19

Installation:

Clone the repo locally using:
git clone https://github.com/rclark-provar/df19-6secrets

This will provide the building blocks for deploying the examples to a SFDX Scratch Org using the following commands:
sfdx force:org:create -f project-scratch-def.json -a MySixSecrets

Now push the project into your new scratch org
sfdx force:source:push -u MySixSecrets

To checkout the declarative contents open the scratch org to inspect the process builder items:
sfdx force:org:open -u MySixSecrets

