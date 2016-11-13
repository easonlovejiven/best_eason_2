require 'will_paginate/core_ext'
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'

module WillPaginate
  class ThrustLinkRenderer < ViewHelpers::LinkRenderer
    def to_html
      html = pagination.map do |item|
        item.is_a?(Fixnum) ? page_number(item) : send(item)
      end.join(@options[:link_separator]) + '<span class="page-jump">共<b class="js_pageLength">'+total_pages.to_s+'</b>页&nbsp;&nbsp;到第&nbsp;<input class="js_pageVal" value="1" name="page" size="2"/>&nbsp;页&nbsp;<a href="javascript:;" class="btn btn-default btn-sm js_pageJump">
      确定</a></span>'
      @options[:container] ? html_container(html) : html
    end

    protected

    def page_number(page)
      unless page == current_page
        link(page, page, :rel => rel_value(page))
      else
        tag(:em, page, :class => 'current')
      end
    end

    def gap
      text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
      %(<span class="gap">#{text}</span>)
    end

    def previous_page
      num = @collection.current_page > 1 && @collection.current_page - 1
      previous_or_next_page(num, @options[:previous_label], 'previous_page')
    end

    def next_page
      num = @collection.current_page < total_pages && @collection.current_page + 1
      previous_or_next_page(num, @options[:next_label], 'next_page')
    end

    def previous_or_next_page(page, text, classname)
      if page
        link(text, page, :class => classname)
      else
        tag(:span, text, :class => classname + ' disabled')
      end
    end

    def html_container(html)
      tag(:div, html, container_attributes)
    end

    # Returns URL params for +page_link_or_span+, taking the current GET params
    # and <tt>:params</tt> option into account.
    def default_url_params
        {}
      end

      def url(page)
        @base_url_params ||= begin
          url_params = merge_get_params(default_url_params)
          url_params[:only_path] = true
          merge_optional_params(url_params)
        end

        url_params = @base_url_params.dup
        add_current_page_param(url_params, page)

        @template.url_for(url_params)
      end

      def merge_get_params(url_params)
        if @template.respond_to? :request and @template.request and @template.request.get?
          symbolized_update(url_params, @template.params)
        end
        url_params
      end

      def merge_optional_params(url_params)
        symbolized_update(url_params, @options[:params]) if @options[:params]
        url_params
      end

      def add_current_page_param(url_params, page)
        unless param_name.index(/[^\w-]/)
          url_params[param_name.to_sym] = page
        else
          page_param = parse_query_parameters("#{param_name}=#{page}")
          symbolized_update(url_params, page_param)
        end
      end


  private
    def parse_query_parameters(params)
      Rack::Utils.parse_nested_query(params)
    end

    def param_name
      @options[:param_name].to_s
    end

    def link(text, target, attributes = {})
      if target.is_a? Fixnum
        attributes[:rel] = rel_value(target)
        target = url(target)
      end
      attributes[:href] = target
      tag(:a, text, attributes)
    end

    def tag(name, value, attributes = {})
      string_attributes = attributes.inject('') do |attrs, pair|
        unless pair.last.nil?
          attrs << %( #{pair.first}="#{CGI::escapeHTML(pair.last.to_s)}")
        end
        attrs
      end
      "<#{name}#{string_attributes}>#{value}</#{name}>"
    end

    def rel_value(page)
      case page
      when @collection.current_page - 1; 'prev' + (page == 1 ? ' start' : '')
      when @collection.current_page + 1; 'next'
      when 1; 'start'
      end
    end

    def symbolized_update(target, other)
      other.each do |key, value|
        key = key.to_sym
        existing = target[key]

        if value.is_a?(Hash) and (existing.is_a?(Hash) or existing.nil?)
          symbolized_update(existing || (target[key] = {}), value)
        else
          target[key] = value
        end
      end
    end
  end
end
