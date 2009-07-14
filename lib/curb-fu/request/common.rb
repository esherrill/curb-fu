module CurbFu
  class Request
    module Common
      def timeout=(val)
        @timeout = val
      end

      def timeout
        @timeout.nil? ? 60 : @timeout
      end

      def build_url(url_params, query_params = {})
        if url_params.is_a? String
          built_url = url_params
        else
          built_url = "http://#{url_params[:host]}"
          built_url += ":" + url_params[:port].to_s if url_params[:port]
          built_url += url_params[:path] if url_params[:path]
        end
        if query_params.is_a? String
          built_url += query_params
        elsif !query_params.empty?
          built_url += "?"
          built_url += query_params.collect do |name, value|
            CurbFu::Request::Parameter.new(name, value).to_uri_param
          end.join('&')
        end
        built_url
      end
    end
  end
end