module ApplicationHelper
  def bootstrap_flash
    flash_messages = []
    flash.each do |type, message|
      next if type == :timeout
      next if type == :timedout
      type = :success if type == :notice
      type = :error   if type == :alert
      text = content_tag(:div,
                         content_tag(:button, raw("&times;"), :class => "close", "data-dismiss" => "alert") +
                             message, :class => "alert alert-#{type}")
      flash_messages << text if message
    end
    flash_messages.join("\n").html_safe
  end

  def private_params params_hash={}, arr=[]
    h = {}
    params_hash.each do |k, v|
      if arr.include? k
        h.merge!({ k => v.to_i })
      else
        h.merge!({ k => v })
      end
    end
    return h
  end

  def manage_model
    @_model ||= controller_path.classify.gsub('Manage','').constantize
  end

  def model
    @model ||= self.controller.model
  end

  def can?(*argv)
    @current_user && @current_user.respond_to?(:can?) && @current_user.can?(*argv)
  end

  def home_task_mark(category)
    hash = {
      'Shop::Event' => 'shop',
      'Shop::Product' => 'shop',
      'Shop::Funding' => 'funding',
      'Qa::Poster' => 'FAQ',
      'Shop::Media' => 'media',
      'Shop::Topic' => 'news',
      'Shop::Subject' => 'topic',
      'Welfare::Letter' => 'letter',
      "Welfare::Voice" => 'voice',
      "Welfare::Event" => 'event',
      "Welfare::Product" => 'product'
    }
    hash[category.to_s]
  end

  def t(key, options = {})
    # If the user has specified rescue_format then pass it all through, otherwise use
    # raise and do the work ourselves
    options[:raise] = true unless options.key?(:raise) || options.key?(:rescue_format)
    if html_safe_translation_key?(key)
      html_safe_options = options.dup
      options.except(*I18n::RESERVED_KEYS).each do |name, value|
        unless name == :count && value.is_a?(Numeric)
          html_safe_options[name] = ERB::Util.html_escape(value.to_s)
        end
      end
      translation = I18n.translate(scope_key_by_partial(key), html_safe_options)

      translation.respond_to?(:html_safe) ? translation.html_safe : translation
    else
      I18n.translate(scope_key_by_partial(key), options)
    end
  rescue I18n::MissingTranslationData => e
    keys = I18n.normalize_keys(e.locale, e.key, e.options[:scope])
    keys.last.to_s.titleize
  end

  def extlink(link)
   if link.include?("http://")
    link
   else
    link.insert(0, "http://")
    link
   end
  end

  def user_identity_style(user)
    style = if user.is_a?(Core::Star)
      "<i class=\"icons v-icon v-star\">&#xe609;</i>"
    else
      case user.identity
      when 'organization'
        "<i class=\"icons v-icon v-organ\">&#xe609;</i>"
      when 'expert'
        "<i class=\"icons v-icon v-expert\">&#xe609;</i>"
      else
        "<i class=\"v-lv badge badge-yellow-light\">Lv.#{user.level.to_i}</i>"
      end
    end
    style.html_safe
  end

  def user_home_identity_style(user)
    style = case user.identity
    when 'organization'
      "<i class=\"icons v-icon v-organ\">&#xe609;</i>"
    when 'expert'
      "<i class=\"icons v-icon v-expert\">&#xe609;</i>"
    else
      "<i class=\"v-lv badge badge-yellow-light\">Lv.#{user.level.to_i}</i>"
    end
    style.html_safe
  end

  def link_to_remote(name, options = {}, html_options = nil)
    id = "link_to_remote_#{Random.rand(2**32)}"
    url = options.delete(:url)
    before = options.delete(:before)
    success = options.delete(:success)
    error = options.delete(:error)
    complete = options.delete(:complete)
    _link_to = link_to name, url, options.merge(html_options || {}).merge(:remote => true, :id => id)
    _before = content_tag(:script, raw("\$('##{id}').on('ajax:beforeSend', function(){ #{before} })")) if before
    _success = content_tag(:script, raw("\$('##{id}').on('ajax:success', function(){ #{success} })")) if success
    _error = content_tag(:script, raw("\$('##{id}').on('ajax:error', function(){ #{error} })")) if error
    _complete = content_tag(:script, raw("\$('##{id}').on('ajax:complete', function(){ #{complete} })")) if complete
    _link_to + _before + _success + _error + _complete
  end

  def follow_links(user, options={})
    return unless @current_user && @current_user != user
    followed = @current_user && user.is_a?(Core::User) ? @current_user.follow_status(user) : @current_user.following?(user)
    omei = user.is_a?(Core::Star) && user.id == 423
    follow_class = options[:follow_class] ||= "btn btn-r-outline btn-rounded-x"
    unfollow_class = options[:unfollow_class] ||= "btn btn-r-outline btn-rounded-x"
    link_to("关注", follow_home_star_path(user, role: user.is_a?(Core::User) ? 'user' : 'star'), method: :put, remote: true, class: "#{follow_class} follow #{'hide' if followed}") +
    if omei
      link_to("已关注", 'javascript:;', class: "#{unfollow_class} unfollow #{'hide' if not followed }")
    else
      link_to("已关注", unfollow_home_star_path(user, role: user.is_a?(Core::User) ? 'user' : 'star'), method: :put, remote: true, class: "#{unfollow_class} unfollow #{'hide' if not followed }")
    end
  end

  def follow_links_index_page_star(star_id, options={})
    return unless @current_user
    followed = @current_user.following?(Core::Star.new(id: star_id))
    omei = star_id == 423
    follow_class = options[:follow_class] ||= "btn btn-r-outline btn-rounded-x"
    unfollow_class = options[:unfollow_class] ||= "btn btn-r-outline btn-rounded-x"
    link_to("关注", follow_home_star_path(star_id, role: 'star'), method: :put, remote: true, class: "#{follow_class} follow #{'hide' if followed}") +
    if omei
      link_to("已关注", 'javascript:;', class: "#{unfollow_class} unfollow #{'hide' if not followed }")
    else
      link_to("已关注", unfollow_home_star_path(star_id, role: 'star'), method: :put, remote: true, class: "#{unfollow_class} unfollow #{'hide' if not followed }")
    end
  end

  def self.upload_image_to_qiniu environment, key
    put_policy = Qiniu::Auth::PutPolicy.new(
      "#{environment}",
      "#{key}",
      1200,
    )
    code, result, response_headers = Qiniu::Storage.upload_with_put_policy(
      put_policy,
      "public/uploads/tmp/#{key}.png",
    )
  end

  def kindeditor_option
    {
      items: ['fontname', 'fontsize', '|', 'forecolor', 'hilitecolor', 'bold', 'italic', 'underline', 'strikethrough', 'lineheight', 'removeformat', '|', 'image', 'multiimage','table', 'hr', 'emoticons','anchor', 'link', 'unlink', 'clearhtml', '|', 'quickformat', 'justifyleft', 'justifycenter', 'justifyright',
        'justifyfull', 'insertorderedlist', 'insertunorderedlist', 'indent', 'outdent', 'subscript']
    }
  end

end
