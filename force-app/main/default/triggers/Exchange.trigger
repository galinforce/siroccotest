trigger Exchange on Exchange__c (before insert, before update) {
    ExchangeTriggerHandler.getInstance().onBeforeInsertOrUpdate(Trigger.new);
}