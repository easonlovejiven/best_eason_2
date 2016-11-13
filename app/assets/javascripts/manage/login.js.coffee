#= require jquery-2.1.4.min
#= require jquery.cookie
#= require jquery.csrf

$ ->
  $('#new_session_form').on 'submit', ->
    $.ajax
      url: $('#new_session_form').attr('action') + '.json'
      type: 'post'
      data: $('#new_session_form').serialize()
      dataType: 'json'
      success: (data) ->
        if data.url
          window.location.href = data.url
        else
          alert data.error
          return
        return
      error: ->
        alert '请稍候重试'
        return
    false
  return
