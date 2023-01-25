public with sharing class ExchangeRatesConnection implements IExchangeRatesConnector{

    private static IExchangeRatesConnector connectorInstance;
    
    public class ExchangeRateResult{
        public Boolean success {get; set;}
        public Integer timestamp {get; set;}
        public String base {get; set;}
        public Map<String, Double> rates {get; set;}
        public Map<String, String> error {get; set;}
    }


    public interface IExchangeRatesConnector {
        ExchangeRateResult retrieveLatestExchangeRate(Set<String> currenciesISOSet);
    }

    //Singleton patern
    public static IExchangeRatesConnector getInstance() {
        if (connectorInstance == null) {
            connectorInstance = new ExchangeRatesConnection();
        }
        return connectorInstance;
    }

    public ExchangeRateResult retrieveLatestExchangeRate(Set<String> currenciesISOSet){
        ExchangeRateResult result = new ExchangeRateResult();
        result.success = false;

        API_Logs__c apilog = new API_Logs__c();
        HttpRequest req = new HttpRequest();
        try{
            req.setEndpoint('callout:ExchangeRatesNamedCredential/latest?symbols='+String.join(new List<String>(currenciesISOSet),','));
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse httpResponse = http.send(req);
            System.debug(httpResponse);
            if (httpResponse.getStatusCode() == 200) {
                JSONParser parser = JSON.createParser(httpResponse.getBody());
                System.debug('Body: '+httpResponse.getBody());
                result = (ExchangeRateResult) JSON.deserialize(httpResponse.getBody(), ExchangeRateResult.class);
                result.success = result.success == null ? false : result.success;
                System.debug('result: '+result);
                //populating apilog data
                apilog.status_code__c = httpResponse.getStatusCode();
                apilog.Success__c = result.success;
                apilog.Body_Result__c = httpResponse.getBody();
                if(result.error != null && !result.error.isEmpty()){
                    System.debug('result.error: '+result.error);        
                }
            }
        } catch (Exception e) {
            apilog.Success__c = false;
            apilog.Body_Result__c = e.getMessage();
        } finally{
            apilog.Endpoint__c = req.getEndpoint();
            insert apilog;
        }

        return result;
    }
}