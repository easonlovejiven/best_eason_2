class ActiveRecord::Base
	# cattr_accessor :manage_fields

	def read(options={})
		self.readings.create(options)
	end

	def updated(options={})
		self.updatings.create(options)
	end

	def updated!(options={})
		self.updatings.create!(options)
	end

	def destroy_softly
		self.active = false
		# self.destroyed_at = Time.now
		self.save#_without_validation#_and_timestamping
	end

	def self.f(id)
		record = where(id: id)
		record = record.where(active: true) if record.first.respond_to?(:active?)
		record.first
	end

	def self.acquire(id)
		f(id)
	end

	def self.default(params, options = {})
		active
			._where(params[:where])
			._order(params[:order])
			.paginate(page: params[:page] || 1, per_page: params[:per_page] || 15)
	end

	def self.find_by(options)
		where(options).first
	end

	# def self.where(options)
	# 	super
	# end

	def self.pagi(params)
		paginate(page: params[:page], per_page: params[:per_page])
	end

end

module ActiveRecord::QueryMethods
	def _where params
		relation = clone
		case
		when params.is_a?(String); return relation
		when params.is_a?(Array); return relation
		when params.is_a?(Hash)
			params = params.map do |field, condition|
				condition = case
				when condition.is_a?(Hash); condition
				when condition.is_a?(Range); { '>=' => condition.begin, '<=' => condition.end }
				when condition.is_a?(Array); { 'in' => condition }
				else; { '=' => condition }
				end
				condition.each do |operator, value|
					{ %[''] => '', %[""] => '', 'true' => true, 'false' => false, 'nil' => nil, 'null' => nil }.each{|x,y| value = y if value == x }
					operator = operator.to_s.downcase
					operator = { 'eq' => '=', 'lt' => '<', 'gt' => '>', 'gteq' => '>=', 'lteq' => '<=', 'noteq' => '!=' }[operator] || operator
					operator = { '=' => 'is', '!=' => 'is not' }[operator] if value === nil
					raise unless field.to_s =~ /^(?:[`'"]?(\w+)[`'"]?\.)?[`'"]?(\w+)[`'"]?$/ && (%w[* & = > < >= <= != in like is]+['is not']+['join']).include?(operator)
					case operator
					when 'like'
						relation = relation.where("#{self.table_name}.#{field} LIKE '%#{value}%'") if value.present?
					when 'join'
						table_field = field.split('__')[1]
						field = field.split('__')[0]
						relation = relation.joins("LEFT JOIN #{table_field} ON #{table_field}.id = #{self.table_name}.id").where("#{table_field}.#{field} = ?", value) if value.present?
					else
						relation = relation.where("#{self.table_name}.#{field} #{operator} #{ operator == 'in' ? '(?)' : '?'}", value) if value.present?
					end
				end
			end
		end
		relation
	end

	def _order params
		params = case
		when params.blank?; "id DESC"
		when params.is_a?(Hash); params.map{ |field, order| "#{field} #{order}" }.join(',')
		when params.is_a?(Array); params.join(',')
		else; params
		end
		raise unless "#{params},".match(/^(?:\s*(?:[`'"]?(\w+)[`'"]?\.)?[`'"]?(\w+)[`'"]?\s*(\sasc|\sdesc)?\s*,\s*)*$/i)
		order params
	end
end
