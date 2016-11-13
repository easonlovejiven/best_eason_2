module Rongcloud
  class Client
    HOST = "http://api.cn.rong.io"
    def initialize(options={})
      @path = options[:path]
      raise "Missing app_key"    if Rongcloud.config.app_key.nil?
      raise "Missing app_secret" if Rongcloud.config.app_secret.nil?
    end

    def request(method, path=@path, params={})
      HTTParty.send(method, URI.join(HOST, path), headers: headers.merge(params[:headers] || {}), body: params[:body])
    end

    def signature
      @signature = Digest::SHA1.hexdigest([Rongcloud.config.app_secret,random,timestamp].join)
    end

    def timestamp
      @timestamp = Time.now.strftime("%s")
    end

    def random
      ary = (0..9).to_a
      @random = ary.reduce([]) { |x,y| x  << ary.sample }.join
    end

    def post(url, params)
      request(:post, url, params)
    end

    def get(url, params)
      request(:get, params)
    end

    def put(url, params)
      request(:put, params)
    end

    def delete(url, params)
      request(:delete, url, params)
    end

    def headers
      {
        "Signature" => signature,
        "App-Key"   => Rongcloud.config.app_key,
        "Nonce"     => @random,
        "Timestamp" => @timestamp
      } 
    end
  end
end