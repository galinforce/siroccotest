public with sharing class ExchangeTriggerHandler implements IExchangeTriggerHandler{

	@TestVisible
	private static IExchangeTriggerHandler ExchangeTriggerInstance;

    private static List<Currency_Cache__c> currencyCacheList;
    private static Boolean isCacheRateUpToDate = false;
	
    public interface IExchangeTriggerHandler {
        void onBeforeInsertOrUpdate(List<Exchange__c> newExchangeList);
    }

	public static IExchangeTriggerHandler getInstance() {
		if (ExchangeTriggerInstance == null) {
			ExchangeTriggerInstance = new ExchangeTriggerHandler();
		}
		return ExchangeTriggerInstance;
	}

	public void onBeforeInsertOrUpdate(List<Exchange__c> newExchangeList){
        currencyCacheList = [Select Id, Iso_Code__c, rate__c, TimeStamp_Last_Update__c From Currency_Cache__c];
        isCacheRateUpToDate = isCacheUptodate();
        prepopulateExchangeCache();
        getExchange(newExchangeList);
	}

    private static void getExchange(List<Exchange__c> newExchangeList){
        if(isCacheRateUpToDate){
            Map<String, Currency_Cache__c> currencyCacheByIso = new Map<String, Currency_Cache__c>();
            For(Currency_Cache__c cache : currencyCacheList){
                currencyCacheByIso.put(cache.Iso_Code__c, cache);
            }

            for(Exchange__c change : newExchangeList){
                change.exchange_rate__c = currencyCacheByIso.get(change.Currency__c).rate__c;
            }
        }else{
            for(Exchange__c change : newExchangeList){
                //change.AddError('We are updating the rates, please try to save again in 10 seconds');
                //I wanted to display a message to the user to save again after the cache is refreshed, although AddError stops the future method
            }
        }
    }

    private static void prepopulateExchangeCache(){
        if(!isCacheRateUpToDate){
            retrieveRates();
        }
    }

    @Future(callout=true)
    private static void retrieveRates(){
        Set<String> isoCodesCurrenciesSet = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Exchange__c.Currency__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntryList = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry picklistValue : picklistEntryList){
            isoCodesCurrenciesSet.add(picklistValue.getValue());
        }

        currencyCacheList = [Select Id, rate__c, Iso_Code__c, TimeStamp_Last_Update__c From Currency_Cache__c];
        Map<String, Currency_Cache__c> currencyCacheByIso = new Map<String, Currency_Cache__c>();
        For(Currency_Cache__c cache : currencyCacheList){
            currencyCacheByIso.put(cache.Iso_Code__c, cache);
        }

        // If the cache is empty OR the difference between now and the last time I updated the cache is bigger than the settings we need to refresh the cache
        if(!isoCodesCurrenciesSet.isEmpty() && !isCacheUptodate()){
            ExchangeRatesConnection.ExchangeRateResult exchangeResult = ExchangeRatesConnection.getInstance().retrieveLatestExchangeRate(isoCodesCurrenciesSet);
            for(String currencyKey : exchangeResult.rates.keySet()){
                Currency_Cache__c currencyCache = new Currency_Cache__c();
                if(currencyCacheByIso.containsKey(currencyKey)){
                    currencyCache = currencyCacheByIso.get(currencyKey);
                    currencyCache.rate__c = exchangeResult.rates.get(currencyKey);
                }else{
                    currencyCache = new Currency_Cache__c();
                    currencyCache.Iso_Code__c = currencyKey;
                    currencyCache.rate__c = exchangeResult.rates.get(currencyKey);
                }
                currencyCache.TimeStamp_Last_Update__c = exchangeResult.timestamp;
                currencyCacheByIso.put(currencyKey, currencyCache);
            }
            upsert currencyCacheByIso.values();
        }
    }

    private static Boolean isCacheUptodate(){
        // Method to retrieve the custom Metadata so we don't need queries.
        Settings__mdt setting = Settings__mdt.getInstance('ExpireCache');

        //If the cache list is empty or the time has lapsed enought time we retrieve new values for the cache.
        if(currencyCacheList == null || currencyCacheList.isEmpty() ||
            (setting.Timestamp__c < System.currentTimeMillis() - currencyCacheList.get(0).TimeStamp_Last_Update__c)){
            return false;
        }
        return true;
    }
}