module Net
  class Sensor
    attr_accessor :name, :serial_number, :temp, :target, :alarm, :low, :high, :blower_serial_number, :blower

    attr_reader :stoker

    FORM_PREFIXES = {
      "name"    => "n1",
      "alarm"   => "al",
      "target"  => "ta",
      "high"    => "th",
      "low"     => "tl",
      "blower"  => "sw",
      "blower_serial_number" => "sw"
    }

    def initialize(stoker, options = {})
      @stoker         = stoker
      options.each do |k,v|
        eval("@#{k} = options[:#{k}]")
      end
    end

    def form_variable(type)
      "#{FORM_PREFIXES[type]}#{self.serial_number}"
    end

    def name=(str)
      @name = str
      @stoker.post(self.form_variable("name") => str)
    end

    def target=(num)
      @target = num.to_i
      @stoker.post(self.form_variable("target") => num.to_i)
    end

    def alarm=(str)
      if alarm_id = Net::Stoker::ALARMS.index(str.capitalize)
        @alarm = str.capitalize
        @stoker.post(self.form_variable("alarm") => alarm_id)
      else
        raise "Invalid alarm #{str}"
      end
    end

    def low=(num)
      if @alarm == "Fire"
        @low = num.to_i
        @stoker.post(self.form_variable("low") => num.to_i)
      else
        raise "You can only set low temp target when alarm is set to Fire"
      end
    end

    def high=(num)
      if @alarm == "Fire"
        @high = num.to_i
        @stoker.post(self.form_variable("high") => num.to_i)
      else
        raise "You can only set high temp target when alarm is set to Fire"
      end
    end

    def blower_serial_number=(str)
      if str.to_s == "" or str == "None"
        @blower_serial_number = nil
        @stoker.post(self.form_variable("blower") => "None")
      else
        blower = @stoker.blower(str)
        if blower
          @blower_serial_number = blower.serial_number
          @stoker.sensors.each do |s|
            if s.blower_serial_number == @blower_serial_number
              s.change_without_update("blower_serial_number", nil) unless s == self
            end
          end
          @stoker.post(self.form_variable("blower_serial_number") => @blower_serial_number)
        else
          raise "Blower not found"
        end
      end
    end

    def blower=(b)
      self.blower_serial_number = b.serial_number rescue nil
    end

    def blower
      raise "Sensor not associated with a blower" if self.blower_serial_number.nil?
      @stoker.blower(self.blower_serial_number)
    end

    # updates internal state of object variable without posting an update to the stoker
    def change_without_update(var, val)
      eval("@#{var} = val")
    end
    
    def update_attributes(params)
      variables = {}

      tp = params
      params = {}
      tp.each{|name,value| params[name.to_s] = value}

      params.each do |name, value|
        case name
        when "blower"
          name = "blower_serial_number"
          if value.to_s == ""
            value = "None"
          else
            value = value.serial_number
          end
        when "blower_serial_number"
          if value.to_s == ""
            value = "None"
          end
        when "alarm"
          value = Net::Stoker::ALARMS.index(value.capitalize)
        end        

        if name == "blower_serial_number"          
          if value != "None"
            # update internal state of any other sensors that have this blower
            @stoker.sensors.each do |s|
              s.change_without_update("blower_serial_number", nil) if s.blower_serial_number == value
            end
          end
        end
        
        variables[name] = value unless name == "serial_number"
      end

      # update this sensor's internal state
      variables.each do |name, value|
        self.change_without_update(name, value)
      end
      
      params = {}
      variables.each do |name, value|
        params[self.form_variable(name)] = value
      end
      
      @stoker.post(params)
    end
    
    def to_s
      @name || @serial_number
    end    
  end
end