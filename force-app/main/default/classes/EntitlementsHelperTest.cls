@isTest(SeeAllData=true)
private with sharing class EntitlementsHelperTest {
       
    // We test with org data because we don't actually want to re-create all the entitlement data here, it's important
    // to use what's in the org setup to test or the testing is pretty meaningless and doesn't tell us about missing SLA\
    // or Business Hours for example
        
    // For completeness we should always test the trigger and test the methods on the helper class
    // If the trigger is removed in future (maybe replaced with a flow or direct invocation) this ensures we still have coverage
    static testMethod void testCaseTrigger() {
        
        Account a1 = (Account)TestFactory.createSObject(new Account(), true);
        Account a2 = (Account)TestFactory.createSObject(new Account(), true);
        
        Contact c1 = (Contact)TestFactory.createSObject(new Contact(AccountId=a1.id), true);        
        Contact c2 = (Contact)TestFactory.createSObject(new Contact(AccountId=a2.id), true);        

		// Read Business Hours and SlaProcess from Org Data
        BusinessHours bh = [SELECT id FROM BusinessHours LIMIT 1];
        List<SlaProcess> slaList = [SELECT Id, Name, isActive, isDeleted FROM SlaProcess 
                                    WHERE SObjectType ='Case'
                                    AND   isActive = true];

        // If there is no SLA process in the org then we want the unit test to fail
        System.debug('slaList size is: ' + slaList.size());

        //Create Entitlements for these Accounts, first for expected fields
        Entitlement entClosed = (Entitlement)TestFactory.createSObject(new Entitlement(AccountId=a1.id,
                                                                                 Name='Date bound entitlement',
                                                                                 StartDate=System.today(),
                                                                                 EndDate=System.today()+365,
                                                                                 BusinessHoursId=bh.id,
                                                                                 SlaProcessId=slaList[0].id),
                                                                       true);
        
		// Second for mandatory fields only
        Entitlement entOpen = (Entitlement)TestFactory.createSObject(new Entitlement(AccountId=a2.id,
                                                                                 Name='Unbounded open entitlement end date',
                                                                                 StartDate=System.today(),
                                                                                 SlaProcessId=slaList[0].id),
                                                                   	 true);


        Test.startTest();
        Case cs1 = new Case(Subject='Unit test 1', Priority='Low', Origin='Web', 
                          Status='New', AccountId=a1.id, ContactId=c1.id,
                          EntitlementId=null);
        Insert cs1;
        cs1 = [SELECT Id, EntitlementId FROM Case WHERE Id = :cs1.Id];
        // Check correct end date entitlement assigned
        System.assertEquals(entClosed.Id, cs1.EntitlementId);
        
        Case cs2 = new Case(Subject='Unit test 1', Priority='Low', Origin='Web', 
                          Status='New', AccountId=a2.id, ContactId=c2.id,
                          EntitlementId=null);
        Insert cs2;
        cs2 = [SELECT Id, EntitlementId FROM Case WHERE Id = :cs2.Id];
        
        // Check correct open entitlement assigned
        System.assertEquals(entOpen.Id, cs2.EntitlementId);
        
        // This Unit Test is just testing the Apex trigger. As we 
        // inserted directly into the object db we expect Salesforce
        // to automatically assign the entitlement in this scenario. 
        // It's via the Email2Case, Web2Case or communities that we need 
        // our custom code to assign the correct entitlement to the case.
        
        Test.stopTest();
        
    }
    
    static testMethod void testCaseEntitlements() {
		// First get the slaprocesses
        List<SlaProcess> slaList = [SELECT Id, Name, isActive, isDeleted FROM SlaProcess 
                                    WHERE SObjectType ='Case'
                                    AND   isActive = true];

        // Create the Test Accounts & Contacts
        Account aGood = (Account)TestFactory.createSObject(new Account(),true);
        Account aNoEnt = (Account)TestFactory.createSObject(new Account(),true);
        Account aNoCon = (Account)TestFactory.createSObject(new Account(),true);
        Account aMulti = (Account)TestFactory.createSObject(new Account(),true);

        Contact cGood = (Contact)TestFactory.createSObject(new Contact(AccountId=aGood.id),true);        
        Contact cNoEnt = (Contact)TestFactory.createSObject(new Contact(AccountId=aNoEnt.id),true);
		Contact cMulti = (Contact)TestFactory.createSObject(new Contact(AccountId=aMulti.id), true); 
        Contact cOrphan = (Contact)TestFactory.createSObject(new Contact(), true);
        
        // Create the Account Entitlements
        Entitlement entGood = (Entitlement)TestFactory.createSObject(new Entitlement(AccountId=aGood.id,
                                                                                 Name='Happy day entitlement',                                                                                     
                                                                                 StartDate=System.today(),
                                                                                 EndDate=System.today()+365,    
                                                                                 SlaProcessId=slaList[0].id),
                                                                    true);

		Entitlement entNoCon = (Entitlement)TestFactory.createSObject(new Entitlement(AccountId=aNoCon.id,
                                                                                 Name='No contact entitlement',                                                                                 
                                                                                 StartDate=System.today(),
                                                                                 SlaProcessId=slaList[0].id),
                                                                    true);

		Entitlement entMulti1 = (Entitlement)TestFactory.createSObject(new Entitlement(AccountId=aMulti.id,
                                                                                 Name='Entitlement out of date',
                                                                                 StartDate=System.today()-365,
                                                                                 EndDate=System.today()-1,
                                                                                 SlaProcessId=slaList[0].id),
                                                                    true);
		Entitlement entMulti2 = (Entitlement)TestFactory.createSObject(new Entitlement(AccountId=aMulti.id,
                                                                                 Name='Entitlement current',                                                                                       
                                                                                 StartDate=System.today(),
                                                                                 EndDate=System.today()+365,
                                                                                 SlaProcessId=slaList[0].id),
                                                                    true);
		Entitlement entMulti3 = (Entitlement)TestFactory.createSObject(new Entitlement(AccountId=aMulti.id,
                                                                                 Name='Entitlement future date',                                                                                       
                                                                                 StartDate=System.today()+366,
                                                                                 EndDate=System.today()+731,
                                                                                 SlaProcessId=slaList[0].id),
                                                                    true);

        Test.startTest();
        // Create one case for an account
        Case cs1 = new Case(Subject='Happy Day Create', Priority='Low', Origin='Web', 
                          Status='New', AccountId=aGood.id, ContactId=cGood.id,
                          EntitlementId=null);
        Insert cs1;
        Case csVerify = [SELECT Id, EntitlementId FROM Case WHERE Id = :cs1.Id];

        // Check the correct Entitlement is set
        System.assertEquals(entGood.Id, csVerify.EntitlementId);

        // Create a new case with no account
        Case cs2 = new Case(Subject='Account Update', Priority='Low', Origin='Web', 
                          Status='New', AccountId=null, ContactId=null,
                          EntitlementId=null);
        Insert cs2;

        // Check no Entitlement is set
        csVerify = [SELECT Id, EntitlementId FROM Case WHERE Id = :cs2.Id];
        System.assertEquals(null, csVerify.EntitlementId);
        
        // Update the Account on the Case
        cs2.AccountId = aGood.id;
        update cs2;
        
        // Check the correct Entitlement is now set
        csVerify = [SELECT Id, EntitlementId FROM Case WHERE Id = :cs2.Id];
        System.assertEquals(entGood.Id, csVerify.EntitlementId);

        // Case for Account with no entitlements
        Case csNoEnt = new Case(Subject='No Entitlement', Priority='High', Origin='Email', 
                          Status='New', AccountId=aNoEnt.id, ContactId=cNoEnt.id,
                          EntitlementId=null);
        Insert csNoEnt;
        //Check no entitlement assigned 
        csVerify = [SELECT Id, EntitlementId FROM Case WHERE Id = :csNoEnt.Id];
        System.assertEquals(null, csVerify.EntitlementId);
                
        // Test Case for Account with multiple active entitlements, gets the current active entitlement
        Case csMulti = new Case(Subject='No Entitlement', Priority='High', Origin='Email', 
                          Status='New', AccountId=aMulti.id, ContactId=cNoEnt.id,
                          EntitlementId=null);
        Insert csMulti;
        
        //Check current entitlement assigned 
        csVerify = [SELECT Id, EntitlementId FROM Case WHERE Id = :csMulti.Id];
        System.assertEquals(entMulti2.Id, csVerify.EntitlementId);
        
        // Case with a Contact added but no Account
        Case csConOnly = new Case(Subject='Implicit Account', Priority='High', Origin='Email', 
                          Status='New', AccountId=null, ContactId=cGood.id,
                          EntitlementId=null);
        Insert csConOnly;
        csVerify = [SELECT Id, EntitlementId FROM Case WHERE Id = :csConOnly.Id];
        System.assertEquals(entGood.Id, csVerify.EntitlementId);
        
        // Case with a Contact which does not have an Account
        Case csConOrphan = new Case(Subject='Implicit Account', Priority='High', Origin='Email', 
                          Status='New', AccountId=null, ContactId=cOrphan.id,
                          EntitlementId=null);
        Insert csConOrphan;
        
        // No entitlement should be assigned
        csVerify = [SELECT Id, EntitlementId FROM Case WHERE Id = :csConOrphan.Id];
        System.assertEquals(null, csVerify.EntitlementId);        

        // Create multiple cases
        Case[] cList = (Case[])TestFactory.createSobjectList(new Case(), 20);
        // Check the correct Entitlements are set
        Test.stopTest();
    }
    
    // Test entitlement automation when Email to case used.. Hmmm how?
    static testMethod void testCaseEntitlementsViaAPI() {
        // Create the Test Accounts
        // 
        // Create the Account Entitlements
        // 
    }
    
    static testMethod void negativeTestEntitlements() {
        // Create the Test Accounts
        // 
        // Create some of the Account Entitlements
        // 
        Test.startTest();
        //Create case for an Account with no Entitlement
        //Already covered above
        
        //Create case without an Account
        //Already covered above
        
        //Check no Entitlement is selected
        Case csNoAcc = new Case(Subject='No Account', Priority='Low', Origin='Email', 
                          Status='New');
        Insert csNoAcc;
        //Check no entitlement assigned 
        csNoAcc = [SELECT Id, EntitlementId FROM Case WHERE Id = :csNoAcc.Id];
        System.assertEquals(null, csNoAcc.EntitlementId);
        
        Test.stopTest();
    }
    
    static testMethod void testAutoCreateAccountEntitlements() {
        List<Account> accList = new List<Account>();
        List<Account> accListFail = new List<Account>();
        
        accList.add((Account)TestFactory.createSObject(new Account(Customer_Status__c='Active'), true));
        accList.add((Account)TestFactory.createSObject(new Account(Customer_Status__c='Active'), true));
        
        accListFail.add((Account)TestFactory.createSObject(new Account(Customer_Status__c='Prospect'), true));
        accListFail.add((Account)TestFactory.createSObject(new Account(Customer_Status__c='Lapsed'), true));
        
        SlaProcess sla = [SELECT Id 
                          FROM	 SlaProcess 
                          WHERE  Name LIKE '%Standard%' 
                          LIMIT 1];
        
        Test.startTest();
        EntitlementsHelper.autoCreateAccountEntitlements(accList, 'Standard');
        
        // Check results
        List<Entitlement> entVerify = [SELECT Id FROM Entitlement WHERE AccountId IN :accList];
        System.assert(entVerify.size() == 2);
        
        /* Negative tests */
        
		//Invalid SLA
        EntitlementsHelper.autoCreateAccountEntitlements(accList, 'NoSuchSla');
        
        //Empty Account List
        EntitlementsHelper.autoCreateAccountEntitlements(new List<Account>(), 'Standard');
        
        //List of Accounts with ineligible types 
        EntitlementsHelper.autoCreateAccountEntitlements(accListFail, 'Standard');

        // Check results
        entVerify = [SELECT Id FROM Entitlement WHERE AccountId IN :accListFail];
        System.assert(entVerify.size() == 0);
        
        Test.stopTest();
    }
    
    static testMethod void testInvocableEntitlement() {

        List<EntitlementsHelper.EntitlementRequest> ents = new List<EntitlementsHelper.EntitlementRequest>();
        EntitlementsHelper.EntitlementRequest er = new EntitlementsHelper.EntitlementRequest();
        er.AccountRecord = (Account)TestFactory.createSObject(new Account(Customer_Status__c='Active'), true);
        er.SlaProcessName = 'Standard';
        er.deactivate = false;
        ents.add(er);
        EntitlementsHelper.manageEntitlement(ents);

        // Deactivate
        er.deactivate = true;
        EntitlementsHelper.manageEntitlement(ents);

       	// Check we have an expired entitlement
        List<Entitlement> entVerify = [SELECT Id, StartDate, EndDate FROM Entitlement WHERE AccountId = :er.AccountRecord.Id];
        System.assertEquals(System.today(), entVerify[0].StartDate);
        System.assertEquals(System.today(), entVerify[0].EndDate);
       	
    }
    
    static testMethod void testTerminateEntitlement() {
        List<Account> accList = new List<Account>(); 
        
        accList.add((Account)TestFactory.createSObject(new Account(Customer_Status__c='Active'), true));
        accList.add((Account)TestFactory.createSObject(new Account(Customer_Status__c='Prospect'), true));
        accList.add((Account)TestFactory.createSObject(new Account(Customer_Status__c='Lapsed'), true));

        // Ensure we have some Entitlements first
        EntitlementsHelper.autoCreateAccountEntitlements(accList, 'Standard');
        
        // Now lets terminate them
        EntitlementsHelper.terminateAccountEntitlements(accList);

        // Check results
        Set<Id> accSet = new Map<Id, Account>(accList).keySet();
        List<Entitlement> entVerify = [SELECT Id, EndDate FROM Entitlement WHERE AccountId IN :accList];
        System.assertEquals(System.today(), entVerify[0].EndDate);        
    }
    
}