module ActAsActivable
  extend ActiveSupport::Concern

  included do |base|
    scope :active, -> {where(active: true)}
  end

  module ClassMethods
    def all_active(reload = false)
      @all_active = nil if reload
      @all_active ||= active.all
    end
  end

  # instance methods
  def active?
    active
  end
end
