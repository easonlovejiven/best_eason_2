require 'singleton'
require 'rongcloud/configuration'
require 'rongcloud/access_token'
module Rongcloud
  def self.setup(&block)
    config.instance_exec(&block)
  end

  def self.config
    Configuration.instance
  end
end
