@IsTest
private class ExchangeTriggerHandlerTest {
    
    @IsTest
    private static void retrieveRate_success(){
        //Given
        List<Exchange__c> newExchangeList = new List<Exchange__c>();
        Exchange__c exchange = new Exchange__c();
        exchange.Currency__c = 'GBP';
        newExchangeList.add(exchange);

        Currency_Cache__c cache = new Currency_Cache__c();
        cache.TimeStamp_Last_Update__c = System.currentTimeMillis();
        cache.Iso_Code__c = 'GBP';
        cache.rate__c = 1.1;
        insert cache;

        Settings__mdt setting = new Settings__mdt();
        setting.Timestamp__c = 86400000;

        //When
        Test.startTest();
        insert newExchangeList;
        Test.stopTest();

        //Then
        List<Exchange__c> exchangeList = [Select Id, exchange_rate__c, Currency__c from Exchange__c];
        System.AssertEquals(1, exchangeList.size(), 'There should be one exchange record inserted');
        System.AssertEquals('GBP', exchangeList.get(0).Currency__c, 'There currency should be GBP');
        System.AssertEquals(1.1, exchangeList.get(0).exchange_rate__c, 'There rate should be 1.1');
    }

    @IsTest
    private static void retrieveRate_Fail_loadingRates(){
        //Given
        Test.setMock(HttpCalloutMock.class, new getExchangeSuccess());
        List<Exchange__c> newExchangeList = new List<Exchange__c>();
        Exchange__c exchange = new Exchange__c();
        exchange.Currency__c = 'GBP';
        newExchangeList.add(exchange);

        Currency_Cache__c cache = new Currency_Cache__c();
        cache.TimeStamp_Last_Update__c = 10;
        cache.Iso_Code__c = 'GBP';
        cache.rate__c = 1.1;
        insert cache;

        Settings__mdt setting = new Settings__mdt();
        setting.Timestamp__c = 1;

        //When
        Test.startTest();
        insert newExchangeList;
        Test.stopTest();

        //Then
        List<Exchange__c> exchangeList = [Select Id, exchange_rate__c, Currency__c from Exchange__c];
        System.AssertEquals(1, exchangeList.size(), 'There should be one exchange record inserted');
        System.AssertEquals('GBP', exchangeList.get(0).Currency__c, 'There currency should be GBP');
        System.AssertEquals(null, exchangeList.get(0).exchange_rate__c, 'There rate should be 1.1');
    }

    private class getExchangeSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"success": true,"timestamp": 1674683463,"base": "EUR","date": "2023-01-25","rates": {"GBP": 1.10}}');
            return response;
        }
    }

}