module NestedSet
  module Paranoia
    SKIP_MODELS = [CollectiveIdea::Acts::NestedSet::Model, Paranoia]

    def self.included(klass)
      klass.class_eval do
        skip_callback :destroy, :before, :destroy_descendants, if: -> { SKIP_MODELS.all?{|model| klass.included_modules.include?(model)} }
      end
    end
  end
end
ActiveRecord::Base.send :include, NestedSet::Paranoia