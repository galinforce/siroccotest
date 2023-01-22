# siroccotest

## Salesforce CRM Developer Test
Purpose
The purpose of the test is to evaluate the ability to use APEX and callouts to retrieve data from an
external source into Salesforce. This is a common task for a developer working at Sirocco.
The test is done individually and should be completed within three days
Test
1. Get a trial version of Salesforce
2. Go to https://exchangeratesapi.io and get an API-key
(https://apilayer.com/marketplace/exchangerates_data-api?preview=true#pricing )
You can test the API using e.g. https://reqbin.com/
3. Create a custom object and add a field for currency and one for exchange rate
4. Create a callout to e.g., https://api.exchangeratesapi.io/latest?symbols=SEK, where SEK is
entered in the currency field
5. Create an object of the custom type and enter a currency. Save the record and display the
exchange rate in the exchange rate field
6. If you get stuck, most of what you need to go forward can be googled.
7. Ask questions early.
8. When you’re ready, send the APEX-code for the callout and user credentials for us to verify
the result in your Salesforce trial
