# vaulted_billing changelog

## [HEAD][head] / unreleased

* No significant changes.

## [1.4.0][v1.4.0] / 2013-04-03

* Update multi\_xml dependency due to security vulnerabilities
  (`~> 0.5.3`).
* Remove Watchr development dependency.

## [1.3.1][v1.3.1] / 2012-10-30

* Identified and added MIT License information to the library and gemspec.
* **Bogus:** Force credit\_card.to\_vaulted\_billing for transaction methods.
  (reported and fixed by [@hoverlover][hoverlover])

## [1.3.0][v1.3.0] / 2012-02-29

* **IP Commerce:** Fix an issue where the card number may be received as a
  Numeric, resulting in an ArgumentError. (reported by
  [@pivotal-evo][pivotal-evo])
* **NMI:** Send correct Content-Type request header (from `text/xml` to
  `application/x-www-form-urlencoded`) correcting the Invalid Username issue.
  (reported by [@hoverlover][hoverlover])

## [1.2.1][v1.2.1] / 2011-10-27

* **Bogus:** Set the response\_message for failed transaction responses.

## [1.2.0][v1.2.0] / 2011-10-27

* **IP Commerce:** Return AVS Response as hash split out with responses for the
  individual responses (No Match, No Response, etc).
* **IP Commerce:** Return CV Response as a string indicating what we receive
  from IP Commerce (Match, No Match, Invalid, etc).
* **IP Commerce:** Fix hash to JSON conversion issue with symbolized key names.
* **Bogus:** Extended to allow for failure case testing with a magic card
  number.

## [1.1.6][v1.1.6] / 2011-09-09

* **IP Commerce:** Strip out non-alphanumeric characters from postal code. IP
  Commerce accepts a 1-9 digit code of only alphanumeric characters.

## [1.1.5][v1.1.5] / 2011-09-06

* **IP Commerce:** Add additional configuration options for transactions.

## [1.1.4][v1.1.4] / 2011-08-31

* **IP Commerce:** Add support for test/production API end points.

## [1.1.3][v1.1.3] / 2011-08-31

* **IP Commerce:** Update the path used for transactions to allow other
  libraries to reuse.
* **IP Commerce:** Update certification scripts and add TMS certification
  scripts.
* **IP Commerce:** Correctly store the session key.

## [1.1.2][v1.1.2] / 2011-08-30

* **IP Commerce:** Fix certification test issues.

## [1.1.1][v1.1.1] / 2011-08-30

* **IP Commerce:** Added country to AVS data sent with credit cards.
* **IP Commerce:** Implement add\_customer\_credit\_card via $1.00 auth/void.
* **IP Commerce:** Implement AVS / CVV checking.
* **IP Commerce:** Add certification tests.
* **IP Commerce:** Handle session key non-renewals.

## [1.1.0][v1.1.0] / 2011-08-17

* Add IP Commerce gateway
* Added HTTP endpoint failover support
* Added VaultedBilling::Error to collect exceptions raised
* Added optional options hash to gateway transaction calls
* Add MultiJson and MultiXml dependencies
* Allow development dependencies to be more flexible


[pivotal-evo]: https://github.com/pivotal-evo
[hoverlover]: https://github.com/hoverlover

[head]: https://github.com/envylabs/vaulted_billing/compare/v1.4.0...master
[v1.4.0]: https://github.com/envylabs/vaulted_billing/compare/v1.3.1...v1.4.0
[v1.3.1]: https://github.com/envylabs/vaulted_billing/compare/v1.3.0...v1.3.1
[v1.3.0]: https://github.com/envylabs/vaulted_billing/compare/v1.2.1...v1.3.0
[v1.2.1]: https://github.com/envylabs/vaulted_billing/compare/v1.2.0...v1.2.1
[v1.2.0]: https://github.com/envylabs/vaulted_billing/compare/v1.1.6...v1.2.0
[v1.1.6]: https://github.com/envylabs/vaulted_billing/compare/v1.1.5...v1.1.6
[v1.1.5]: https://github.com/envylabs/vaulted_billing/compare/v1.1.4...v1.1.5
[v1.1.4]: https://github.com/envylabs/vaulted_billing/compare/v1.1.3...v1.1.4
[v1.1.3]: https://github.com/envylabs/vaulted_billing/compare/v1.1.2...v1.1.3
[v1.1.2]: https://github.com/envylabs/vaulted_billing/compare/v1.1.1...v1.1.2
[v1.1.1]: https://github.com/envylabs/vaulted_billing/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/envylabs/vaulted_billing/compare/v1.0.2...v1.1.0
