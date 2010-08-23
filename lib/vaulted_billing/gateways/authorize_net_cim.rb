module VaultedBilling
  module Gateways

    ##
    # An interface to Authorize.net's CIM.
    #
    class AuthorizeNetCim
      include VaultedBilling::Gateway
      include VaultedBilling::HttpsInterface

      def initialize(options = {})
        self.test_uri = 'https://apitest.authorize.net/xml/v1/request.api'
        self.live_uri = 'https://api.authorize.net/xml/v1/request.api'
        self.ssl_pem = File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'certificate_authorities', 'entrust.pem')))

        options = HashWithIndifferentAccess.new(options)
        @login = options[:username]
        @password = options[:password]
      end

      def add_customer(customer)
        data = build_request('createCustomerProfileRequest') do |xml|
          xml.tag!('profile') do
            xml.merchantCustomerId customer.id if customer.id
            xml.email customer.email if customer.email
          end
        end
        result = post_data(data)
        respond_with(customer, :success => result.success?) { |c| c.id = (result.body['createCustomerProfileResponse'] || {})['customerProfileId'] }
      end

      def update_customer(customer)
        result = post_data(build_request('updateCustomerProfileRequest') { |xml|
          xml.tag!('profile') {
            xml.merchantCustomerId customer.id
            xml.email customer.email
          }
        })
        respond_with(customer, :success => result.success?)
      end

      def remove_customer(customer)
        result = post_data(build_request('deleteCustomerProfileRequest') { |xml|
          xml.customerProfileId customer.id
        })
        respond_with(customer, :success => result.success?)
      end

      def add_customer_credit_card(customer, credit_card)
        result = post_data(build_request('createCustomerPaymentProfileRequest') { |xml|
          xml.customerProfileId customer.id
          xml.paymentProfile do
            billing_info!(xml, customer, credit_card)
            credit_card_info!(xml, customer, credit_card)
          end
        })
        respond_with(credit_card, :success => result.success?) { |c| c.id = (result.body['createCustomerPaymentProfileResponse'] || {})['customerPaymentProfileId'] }
      end

      def update_customer_credit_card(customer, credit_card)
        result = post_data(build_request('updateCustomerPaymentProfileRequest') { |xml|
          xml.customerProfileId customer.id
          xml.paymentProfile do
            billing_info!(xml, customer, credit_card)
            credit_card_info!(xml, customer, credit_card)
            xml.customerPaymentProfileId credit_card.id
          end
        })
        respond_with(credit_card, :success => result.success?)
      end

      def remove_customer_credit_card(customer, credit_card)
        result = post_data(build_request('deleteCustomerPaymentProfileRequest') { |xml|
          xml.customerProfileId customer.id
          xml.customerPaymentProfileId credit_card.id
        })
        respond_with(credit_card, :success => result.success?)
      end

      def authorize(customer, credit_card, amount)
        result = post_data(build_request('createCustomerProfileTransactionRequest') { |xml|
          xml.transaction do
            xml.profileTransAuthOnly do
              xml.amount amount
              xml.customerProfileId customer.id
              xml.customerPaymentProfileId credit_card.id
            end
          end
        })
        respond_with(new_transaction_from_response(result.body), :success => result.success?)
      end

      def capture(transaction_id, amount)
        result = post_data(build_request('createCustomerProfileTransactionRequest') { |xml|
          xml.transaction do
            xml.profileTransPriorAuthCapture do
              xml.amount amount
              xml.transId transaction_id
            end
          end
        })
        respond_with(new_transaction_from_response(result.body), :success => result.success?)
      end

      def refund(transaction_id, amount)
        result = post_data(build_request('createCustomerProfileTransactionRequest') { |xml|
          xml.transaction do
            xml.profileTransRefund do
              xml.amount amount
              xml.transId transaction_id
            end
          end
        })
        respond_with(new_transaction_from_response(result.body), :success => result.success?)
      end

      def void(transaction_id)
        result = post_data(build_request('createCustomerProfileTransactionRequest') { |xml|
          xml.transaction do
            xml.profileTransVoid do
              xml.transId transaction_id
            end
          end
        })
        respond_with(new_transaction_from_response(result.body), :success => result.success?)
      end


      protected


      def post_data(data, headers = {})
        super(data, {'Content-Type' => 'text/xml'}.merge(headers))
      end

      def before_post(data)
        VaultedBilling.logger.debug { "Posting: %s to %s" % [data.inspect, uri.inspect] } if VaultedBilling.logger?
      end

      def after_post(response)
        VaultedBilling.logger.debug { "Response code %s (HTTP %d), %s" % [response.message, response.code, response.body.inspect] } if VaultedBilling.logger?
        response.body = Hash.from_xml(response.body)
        response.success = response.body[response.body.keys.first]['messages']['resultCode'] == 'Ok'
      end

      def build_request(request, xml = Builder::XmlMarkup.new(:indent => 2))
        xml.instruct!
        xml.tag!(request, :xmlns => 'AnetApi/xml/v1/schema/AnetApiSchema.xsd') do
          xml.tag!('merchantAuthentication') do
            xml.name @login
            xml.transactionKey @password
          end
          yield(xml)
        end
        xml.target!
      end


      private


      def billing_info!(xml, customer, credit_card)
        xml.billTo do
          xml.firstName credit_card.first_name if credit_card.first_name.present?
          xml.lastName credit_card.last_name if credit_card.last_name.present?
          xml.address credit_card.street_address if credit_card.street_address.present?
          xml.city credit_card.locality if credit_card.locality.present?
          xml.state credit_card.region if credit_card.region.present?
          xml.zip credit_card.postal_code if credit_card.postal_code.present?
          xml.country credit_card.country if credit_card.country.present?
          xml.phoneNumber credit_card.phone if credit_card.phone.present?
        end
      end

      def credit_card_info!(xml, customer, credit_card)
        xml.payment do
          xml.creditCard do
            xml.cardNumber credit_card.card_number if credit_card.card_number.present?
            xml.expirationDate credit_card.expires_on.strftime("%Y-%m") if credit_card.expires_on.present?
            xml.cardCode credit_card.cvv_number if credit_card.cvv_number.present?
          end
        end
      end

      def new_transaction_from_response(response)
        root = response.keys.first
        if root == 'ErrorResponse'
          Transaction.new
        else
          direct_response = parse_direct_response(response[root]['directResponse'])
          Transaction.new({
            :id => direct_response['transaction_id'],
            :avs_response => direct_response['avs_response'],
            :cvv_response => direct_response['cvv_response'],
            :authcode => direct_response['approval_code'],
            :message => response[root]['messages']['text'],
            :code => response[root]['messages']['code']
          })
        end
      end

      def parse_direct_response(string)
        fields = string.split(',')
        {
          'message' => fields[3],
          'approval_code' => fields[4],
          'avs_response' => fields[5],
          'transaction_id' => fields[6],
          'cvv_response' => fields[39]
        }
      end

    end

  end
end