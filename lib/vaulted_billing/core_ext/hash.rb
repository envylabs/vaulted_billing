require 'cgi'

module VaultedBilling
  module CoreExt
    module Hash
      def to_querystring
        to_a.reject { |pair| pair.last.nil? }.
          sort_by { |item| item.first.to_s }.
          collect { |key, value| "#{key}=#{value}" }.join('&')
      end

      module ClassMethods
        def from_querystring(string)
          return {} if string.nil?
          ::Hash[*(string.split(/&/).
            collect { |i| i.split(/=/) }.
            collect { |e| e.size == 1 ? (e << '') : e }.flatten.
            collect { |e| CGI.unescape(e) })]
        end
      end
    end
  end
end

::Hash.send :include, VaultedBilling::CoreExt::Hash
::Hash.extend(VaultedBilling::CoreExt::Hash::ClassMethods)
