class Core::Keyword < ActiveRecord::Base
	scope :active, -> { where(active: true) }

	private
	
	def after_save
	 	$redis.del("core-keywords")
	 	$redis.set("core-keywords",Core::Keyword.active.map(&:name).map{|n|Regexp.escape(n)}.join('|'))
	end
end
