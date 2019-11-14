public with sharing class EntitlementsHelper {
    
    // NOTE! The case list passed is modified by reference for performance reasons and as part of a call from a before trigger
    // so that we don't have to re-save after the initial commit.
    public static void updateCaseEntitlements(List<Case> caseList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id,Id> contactMap = new Map<Id,Id>();
        
        // Populate the sets with unique values for the associated Contacts and Accounts
        for (Case c : caseList) {
            if (c.AccountId != null && !accountIds.contains(c.AccountId)) {
                accountIds.add(c.AccountId);
            }
            // Salesforce populates Accounts for us automatically but doesn't do this until the AFTER trigger
            // Lets find the Accounts first to avoid multiple updates on the Case
            else if (c.AccountId == null && 
                     c.ContactId != null &&
                     !contactIds.contains(c.ContactId)) {
                contactIds.add(c.ContactId);
            }
        }
        
        // Get the corresponding AccountIds for any contacts that have been added without the corresponding Account
        for (Contact con : [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]) {
            contactMap.put(con.Id, con.AccountId);
            // If the corresponding AccountId isn't already in our set then add it
            if (!accountIds.contains(con.AccountId)) {
                accountIds.add(con.AccountId);
            }
        }
        
        // Now we can process these against the Entitlements as per the apex code shared in the Entitlements 
        // We've trimmed this down as we only care about Entitlements at the Account level, not Contact or Asset.
        // NB: Status = Active is simply a formula field based on the end date, i.e. we don't need to check this
        // Excluded End Date as it's not mandatory, instead sorting results by the start date descending so that we
        // should pick the most recent entitlement
        List <Entitlement> entls = [SELECT e.StartDate, e.Id, e.EndDate,
                                    e.AccountId, e.AssetId
                                    FROM   Entitlement e
                                    WHERE  e.AccountId in :accountIds 
                                    AND    e.StartDate <= TODAY
                                    ORDER BY e.StartDate DESC];
		// Hopefully we found some entitlements for these Case(s)	
        if (entls.isEmpty() == false) {
            for (Case c : caseList) {
                //System.debug('EntitlementId='+c.EntitlementId+'<>AccountId='+c.AccountId);
                if(c.EntitlementId == null && 
                   (c.AccountId != null || c.ContactId != null)
                  ) {
                    // Yes a Map of Lists keyed by AccountId would be better, but I know my cases don't get 
                    // created in bulk in reality so I can afford the nested for loop
                    for (Entitlement e : entls) {
                        if (e.AccountId == c.AccountId ||
                            e.AccountId == contactMap.get(c.ContactId)) {
                            c.EntitlementId = e.Id;
                            // We can populate c.AccountId too if it was null, but we know thats going to happen
                            // anyway and lets not mess with the ootb plumbing
                            //No need to find another!
                            break;
                        }
                    }
                    // Debug if we didn't find a valid entitlement for the Case
                    if (c.EntitlementId == null) {
                            System.debug('No active Entitlement found for Account ' + c.AccountId + ' on Case ' + c.Id);
                    }
                }
            }
        }
        else {
            // Lets at least recognise this in our debug log when it happens
            System.debug('No entitlement records found for these cases ' + caseList);
        }
    }
    

    @InvocableMethod(label='Create Entitlement' description='Create an Entitlement record for the specified Account')
    public static void manageEntitlement(List<EntitlementRequest> entRequests) {

        for (EntitlementRequest er : entRequests) {
            List<Account> accList = new List<Account>();
            accList.add(er.accountRecord);

            if (er != null && er.deactivate) {
            	terminateAccountEntitlements(accList);    
            }
            else {
                autoCreateAccountEntitlements(accList, er.slaProcessName);
            }
        }
        
       
	}
    
    // When passed a list of Accounts automatically create an entitlement record    
    public static void autoCreateAccountEntitlements(List<Account> accList, String slaProcessName) {        

		// Get all the active SLAs and form a map to the ids
		//Map<String, Id> slaMap = getCaseSlaMap();
        
        slaProcessName = '%'+slaProcessName+'%';
        // Get the SLA list for the Case object
        List<SlaProcess> slaList = [SELECT Id, Name 
                                    FROM   SlaProcess 
                                    WHERE  SObjectType ='Case'
                                    AND    IsActive = true
                                    AND    Name LIKE :slaProcessName];

        if (slaList.size() > 0) {
	        autoCreateAccountEntitlements(accList, slaList[0]);
        }
    }
    
    public static void autoCreateAccountEntitlements(List<Account> accList, SlaProcess sla) {
        
        List<Entitlement> entList = new List<Entitlement>();
        
        for (Account acc : accList) {
            if (acc.Customer_Status__c == 'Active') {
	            Entitlement ent = new Entitlement(Name = acc.Name + ' ' + sla.Name,
                                                  AccountId = acc.Id,
                                                  StartDate = System.today(), 
                                                  SlaProcessId = sla.Id);
    	        entList.add(ent);
            }
        }
        
        insert entList;
    }
    
	// For the listed accounts set the End Date for the entitlement to yesterday
    public static void terminateAccountEntitlements(List<Account> accList) {        
		// Find the Entitlements to update
		List<Entitlement> entList = [SELECT Id, EndDate 
                                       FROM	  Entitlement 
                                       WHERE  AccountId IN :accList];

        for (Entitlement e : entList) {
        	e.EndDate = System.today();                          
		}
        
        // Save our changes
        update entList;
    }
    // Retrieve the SlaProcesses from the Org
    // Overkill for now, come back to this when we want to instigate upgrade/downgrade process
    /*
    private static Map<String, Id> getCaseSlaMap() {
        Map<String, Id> slaMap = new Map<String, Id>();
        // Populate the map with active case slas
        for (SlaProcess sla : [SELECT Id, Name 
                               FROM   SlaProcess 
                               WHERE  SObjectType ='Case'
                               AND    IsActive = true]) {
			slaMap.put(sla.Name, sla.Id);                                   
                               }
        
        return slaMap;
    }
	*/

    public class EntitlementRequest {
        @InvocableVariable(required=true)
        public Account accountRecord;
        
        @InvocableVariable(required=true)
        public String slaProcessName;
        
        @InvocableVariable()
        public Boolean deactivate;
    }

}