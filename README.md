# VaultedBilling [![Build status][ci-image]][ci] [![Dependency Status][gemnasium-image]][gemnasium] [![Code Climate][codeclimate-image]][codeclimate]

VaultedBilling is an abstraction library for use when working with "vaulted" payment processors.  These processors store your customer's data - being their credit card number, verification number, name, address, and more - on their systems to alleviate your need for expensive software auditing, hardware security, and more.  In nearly all cases, these processors provide you a unique customer and/or payment token in exchange for your actual customer payment information.  Then, all current and future interactions with the payment processor on behalf of the customer are made using their identifiers, rather than credit card details.

Since you only store identifiers on your end, you are only responsible for: 1) the responsible reception, 2) responsible retransmission, and 3) no local storage of card details, when it comes to PCI compliance.  Those items are solved with the following:

1. Get an SSL certificate from a trusted provider and use HTTPS when collecting card information,
2. Use a verified SSL connection when contacting your payment processor for storage or queries, and
3. Do not log a full credit card number or verification code (CVV) to your application or server log files, your database (even temporarily), or anywhere else.  Instead, collect and immediately re-transmit to your processor for storage.

## Supported Services

VaultedBilling supports the following payment providers:

* [Authorize.net Customer Information Manager][authorize-net-cim]
* [IP Commerce Tokenization][ipcommerce-tokenization]
* [Network Merchant Inc. Customer Vault][nmi-vault]

VaultedBilling also supports the following fictitious payment provider for testing purposes:

* Bogus

## Installation

VaultedBilling should be installed as a RubyGem dependency:

    gem install vaulted_billing

If your application uses [Bundler][bundler], then add the following to your Gemfile:

    gem 'vaulted_billing'

## Usage

Simple (not particularly clean or recommended) example:

```ruby
require 'vaulted_billing'

bogus = VaultedBilling::Gateways::Bogus.new(:username => 'Foo', :password => 'Bar')
customer = VaultedBilling::Customer.new(:email => "foo@example.com")
credit_card = VaultedBilling::CreditCard.new({
  :card_number => '4111111111111111',
  :cvv_number => '123',
  :expires_on => Date.today + 1.year
})

bogus.add_customer(customer).tap do |customer_response|
  if customer_response.success?
    # normally, you'd store the vault_id on your local customer object,
    # because you use this when referencing that customer in the future.
    # But, for now, we'll just:
    customer.vault_id = customer_response.vault_id

    bogus.add_customer_credit_card(customer, credit_card).tap do |credit_response|
      if response.success?
        # Again, same as above, but for the credit card information:
        credit_card.vault_id = credit_response.vault_id

        puts "Wow! We stored a the payment credentials successfully!"

        if bogus.purchase(customer, credit_card, 10.00).success?
          puts "OMG WE'RE RICH!"
        end
      end
    end
  end
end
```

## Testing

When you're manually testing your application - meaning Development mode - it is often best to actually have a "sandbox" or "test" account with your payment processor.  In this mode, you should use those credentials with VaultedBilling and indicate to VaultedBilling that the processor is in test mode, either by setting it in the VaultedBilling::Configuration (see Configuration) or when you instantiate your Gateway.  You should note that all gateways, except for the Bogus gateway, attempt to open network connections when in use.  So, if you are testing with them (which is suggested), you should look into an HTTP mocking library like [VCR][vcr] with [WebMock][webmock].

Strictly for testing interaction with the VaultedBilling library, there is a "Bogus" gateway provided.  This processor will always successfully store customer and credit card information and return their identifiers.  It will also always respond successfully to transaction (authorize, capture, refund, void, etc.) requests.  This processor does not attempt to make network requests to any 3rd parties.  It is not recommended that you solely test against this gateway, as you will find that your actual payment processor may have quirks which are unique and cannot be easily replicated.

[ci]: http://travis-ci.org/envylabs/vaulted_billing
[ci-image]: https://secure.travis-ci.org/envylabs/vaulted_billing.png
[gemnasium]: https://gemnasium.com/envylabs/vaulted_billing
[gemnasium-image]: https://gemnasium.com/envylabs/vaulted_billing.png
[codeclimate]: https://codeclimate.com/github/envylabs/vaulted_billing
[codeclimate-image]: https://codeclimate.com/github/envylabs/vaulted_billing.png
[authorize-net-cim]: http://www.authorize.net/solutions/merchantsolutions/merchantservices/cim/
[ipcommerce-tokenization]: http://developer.ipcommerce.com/developer/integration/value_added_capabilities.aspx
[nmi-vault]: https://www.nmi.com/newsmedia/index.php?ann_id=14
[bundler]: http://gembundler.com/
[vcr]: https://github.com/myronmarston/vcr
[webmock]: https://github.com/bblimke/webmock
