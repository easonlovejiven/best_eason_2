# encoding:utf-8
module V3
  class ClientApi < Grape::API
    format :json
    helpers APIHelper

    mount UsersApi
    mount ShopFundingsApi
    mount ShopAddressesApi
    mount ShopTasksApi
    mount ShopTopicsApi
    mount StarsApi
    mount RecordingsApi
    mount AdsApi
    mount NotifyApi
    mount BannersApi
    mount QuestionsApi
    mount SuggestionsApi
    mount ShopMediaApi
    mount AjaxApi
    mount WelfareLettersApi
    mount FeedsApi
    mount RankingsApi
    mount FeedbacksApi
    mount ConnectionsApi
    mount PunchesApi
    mount PayCallbackApi
    mount WxCallbackApi
    mount DilianApi
  end
end
