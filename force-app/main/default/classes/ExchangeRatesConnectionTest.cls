@IsTest
private class ExchangeRatesConnectionTest {

    private class getExchangeSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"success": true,"timestamp": 1674683463,"base": "EUR","date": "2023-01-25","rates": {"GBP": 0.80}}');
            return response;
        }
    }

    private class getExchangeFail implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"error": {"code": "invalid_currency_codes","message": "You have provided one or more invalid Currency Codes. [Required format: currencies=EUR,USD,GBP,...]"}}');
            return response;
        }
    }

    @IsTest
    private static void getExchangeRate_success(){
        //Given
        Test.setMock(HttpCalloutMock.class, new getExchangeSuccess());

        //When
        Test.startTest();
        ExchangeRatesConnection.ExchangeRateResult exchangeResult = ExchangeRatesConnection.getInstance().retrieveLatestExchangeRate(new Set<String>{'GBP'});
        Test.stopTest();

        //Then
        System.Assert(exchangeResult.success, 'success should have been true and is not');
        System.AssertEquals('EUR', exchangeResult.base, 'The base currency should have been EUR and is not');
        System.AssertEquals(1, exchangeResult.rates.size(), 'One Rate should have been returned');
        System.Assert(exchangeResult.rates.keySet().contains('GBP'), 'Rate should have been GBP currency');
        System.AssertEquals(0.80, exchangeResult.rates.get('GBP'), 'Rate should have been 0.80');
        List<API_Logs__c> apilogsList = [Select Id, status_code__c, Success__c, Endpoint__c, Body_Result__c From API_Logs__c];
        System.AssertEquals(1, apilogsList.size(), 'There should be one api log inserted');
        System.Assert(apilogsList.get(0).Success__c, 'The success field should be true');
        System.AssertEquals(200, apilogsList.get(0).status_code__c, 'The status code should be 200');
        System.Assert(apilogsList.get(0).Endpoint__c.contains('GBP'), 'The endpoint should contain the fake currency GBP');
        System.AssertEquals('{"success": true,"timestamp": 1674683463,"base": "EUR","date": "2023-01-25","rates": {"GBP": 0.80}}',
                            apilogsList.get(0).Body_Result__c, 'The body is not the correct');
    }

    @IsTest
    private static void getExchangeRate_fail(){
        //Given
        Test.setMock(HttpCalloutMock.class, new getExchangeFail());

        //When
        Test.startTest();
        ExchangeRatesConnection.ExchangeRateResult exchangeResult = ExchangeRatesConnection.getInstance().retrieveLatestExchangeRate(new Set<String>{'GDPR'});
        Test.stopTest();

        //Then
        System.Assert(!exchangeResult.success, 'success should have been false and is not');
        System.Assert(!exchangeResult.error.isEmpty(), 'error maps should not been empty');
        System.AssertEquals(null, exchangeResult.base, 'The base currency should have been empty');
        System.AssertEquals(null, exchangeResult.rates, 'Rates map should have been empty');
        List<API_Logs__c> apilogsList = [Select Id, status_code__c, Success__c, Endpoint__c, Body_Result__c From API_Logs__c];
        System.AssertEquals(1, apilogsList.size(), 'There should be one api log inserted');
        System.Assert(!apilogsList.get(0).Success__c, 'The success field should be false');
        System.AssertEquals(200, apilogsList.get(0).status_code__c, 'The status code should be 200');
        System.Assert(apilogsList.get(0).Endpoint__c.contains('GDPR'), 'The endpoint should contain the fake currency GDPR');
        System.AssertEquals('{"error": {"code": "invalid_currency_codes","message": "You have provided one or more invalid Currency Codes. [Required format: currencies=EUR,USD,GBP,...]"}}',
                            apilogsList.get(0).Body_Result__c, 'The body is not the correct');
    }
}