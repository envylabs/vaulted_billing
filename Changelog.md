### 1.1.1 / 2011-08-30

[full changelog](http://github.com/envylabs/vaulted_billing/compare/v1.1.0...v1.1.1)

* Enhancements
  * IP Commerce
    * Added country to AVS data sent with credit cards
    * Implement add_customer_credit_card via $1.00 auth/void
    * Implement AVS / CVV checking
    * Add certification tests

* Bug Fixes
  * IP Commerce
    * Handle session key non-renewals
  
### 1.1.0 / 2011-08-17

[full changelog](http://github.com/envylabs/vaulted_billing/compare/v1.0.2...v1.1.0)

* Enhancements
  * Add IP Commerce gateway
  * Added HTTP endpoint failover support
  * Added VaultedBilling::Error to collect exceptions raised
  * Added optional options hash to gateway transaction calls
  * Add MultiJson and MultiXml dependencies
  * Allow development dependencies to be more flexible
