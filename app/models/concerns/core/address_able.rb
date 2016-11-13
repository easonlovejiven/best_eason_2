module Core
  module AddressAble
    VALID_MOBILE_REGEX = /(?:\+?|\b)[0-9]{10}\b/i
    extend ActiveSupport::Concern

    def has_valid_mobile?
        mobile && ((mobile =~ VALID_MOBILE_REGEX) != nil)
    end

    def province_name
      ADDRESS_DATA[province_id]
    end

    def city_name
      ADDRESS_DATA[city_id]
    end

    def district_name
      ADDRESS_DATA[district_id]
    end

    def full_address(str=" ")
      [province_name, city_name, district_name, address].join(str)
    end

    def city
      [province_name, city_name, district_name].uniq.join(' ')
    end
  end
end
