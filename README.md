# df19-6secrets
Six Secrets of Service Cloud Success: Entitlements Automation

Code and configuration examples as utilised in the above Dreamforce19 Theatre session. You are free to use, re-use, copy and disseminate this repo at your own risk. Provar and myself provide no warranty, support or maintenance for the examples in this repository, they are there as examples on what can be done and should be revised for your own use case before implementing in your Salesforce orgs.

Updates coming on 18th November ahead of Dreamforce 19

Examples Installation
---------------------

The examples used in my Dreamforce 19 talk are available for a limited time as an Unmanaged Package by installing from here:


On a more permanent basis you can install into a Scratch Org using Salesforce DX:

Clone this repo locally using:
git clone https://github.com/rclark-provar/df19-6secrets

This will provide the building blocks for deploying the examples to a SFDX Scratch Org using the following commands:
sfdx force:org:create -f project-scratch-def.json -a MySixSecrets

Now push the project into your new scratch org
sfdx force:source:push -u MySixSecrets

To checkout the declarative contents open the scratch org to inspect the process builder items:
sfdx force:org:open -u MySixSecrets

Contents
--------
The contents of this repo relate to the following points:

#1 Automate your Entitlement Creation
    Account_Management.flow-meta.xml
    EntitlementsHelper.cls
    
#2 Case Entitlement Lookup Population
    CaseTrigger.cls
    EntitlementsHelper.cls
    
#3 Case Path Automation
    Email_Automation.flow-meta.xml
    
#4 Milestone Autocompletion
    Case_Management.flow-meta.xml

#5 Stop & Start the SLA Clock
    Case_Management.flow-meta.xml

#6 Case Close Automation
    Case_Management.flow-meta.xml

Six Secrets Presentation
------------------------
The Dreamforce19 slide deck will be posted here after the talk on Tues 19th November. Don't want to give too much away now!
