class IpcommerceTransaction
  def print
    
    "'%s', '%s', '%s', '%s', '%s'" % [
      @code,
      parsed_response["StatusCode"],
      parsed_response["ApprovalCode"],
      parsed_response["StatusMessage"],
      parsed_response["TransactionId"]
    ]
  end
  
  attr_accessor
  
  def initialize(code, transaction)
    @code = code
    @transaction = transaction
  end
  
  def parsed_response
    @response ||= begin
      response = MultiJson.decode(@transaction.raw_response)
      response.is_a?(Array) ? response.first : response
    rescue 
      "Error response"
    end
  end
end