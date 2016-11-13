require 'rongcloud/client'
module Rongcloud
  class AccessToken
    GET_TOKEN_URL = "/user/getToken.json"
    def initialize(options={})
    end

    def self.get_token(params={})
      new.get_token(params)
    end

    # *params*
    #   *user_id*
    #   *name*
    #   *avatar_url*
    def get_token(params={})
      client.post( GET_TOKEN_URL, body: parse_request_body(params) )
    end

    def parse_request_body(params={})
      { userId: params[:user_id], name: params[:name],portraitUri: params[:avatar_url] }
    end

    def client
      @client ||= Client.new
    end
  end
end