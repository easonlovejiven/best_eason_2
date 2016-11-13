module Rongcloud
  class Configuration
    include Singleton
    attr_accessor :options
    def initialize(options={})
      options.each {|key, value| options[key.to_sym] = options.delete(key) if !k.is_a?(Symbol)}
      @options = options
    end

    def respond_to?(method)
      options.key?(method.to_sym) || super
    end

    def method_missing(method, *args, &block)
      if method.to_s.match(/(.+)=$/)
        options[$1.to_sym] = args.first
      elsif respond_to?(method)
        options[method.to_sym]
      else
        super
      end
    end
  end
end