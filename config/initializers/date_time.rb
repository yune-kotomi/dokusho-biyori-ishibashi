module IcalDateTimeInit
  def initialize(value, params = {})
    if value.is_a?(String)
      value += 'T000000' unless value =~ /^[0-9]+T[0-9]+$/
    end
    
    super(value, params)
  end
end

class Icalendar::Values::DateTime
  prepend IcalDateTimeInit
end
