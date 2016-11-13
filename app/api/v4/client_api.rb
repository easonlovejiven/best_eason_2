# encoding:utf-8
module V4
  class ClientApi < Grape::API
    format :json
    helpers APIHelper

    mount BannersApi
    mount FeedsApi
    mount ConnectionApi
    mount WelfareTaskApi
    mount WelfareLettersApi
    mount PayApi
    mount WebApi
    mount ShopTopicsApi
  end
end
