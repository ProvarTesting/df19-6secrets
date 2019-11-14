trigger CaseTrigger on Case (before insert, before update) {
    
	// Before insert
    if (trigger.isInsert && trigger.isBefore) {
      EntitlementsHelper.updateCaseEntitlements(trigger.new);
    } 
    
    // Before update
    if (trigger.isUpdate && trigger.isBefore) {
        EntitlementsHelper.updateCaseEntitlements(trigger.new);
    }
    

}