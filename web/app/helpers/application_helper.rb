# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def spinner(id)
    image_tag "spinner.gif", :id => id, :style => "display:none"
  end
  
  def format_date(time, options = {})
    time.to_time.strftime("%Y-%m-%d")
  end

  def format_time(time, options = {})
    time.to_time.strftime("%I:%m#{options[:include_seconds] ? ':%S' : ''} %p")
  end
  
  def format_datetime(time, options = {})
    format_date(time.to_time, options) + ' ' + format_time(time.to_time, options)
  end
  
  def graph(events, container_name)
    data_sets = {}

    events.each do |e|
      data_sets[e.sensor] ||= []
      data_sets[e.sensor] << [e.created_at.to_i, e.temp]
    end

    data_set_count = 0
    data_set_js = ""
    data_set_names = []

    data_sets.each do |sensor,temps|
      temps_js = ""
      temp_strings = []

      temps.each do |temp|
        temp_strings << "[#{temp[0]}, #{temp[1]}]"
      end

      temps_js = temp_strings.join(", ")
      data_set_js << "d#{data_set_count} = [#{temps_js}];\n    "

      data_parts_js = []
      data_parts_js << "data: d#{data_set_count}"
      data_parts_js << "label: '#{sensor.name} #{sensor.temp}F'"

      # data_parts_js << "lines: {fill: true}" if sensor.alarm == "Fire"

      data_set_names << "{#{data_parts_js.join(", ")}}"

      data_set_count += 1
    end
    
    options = {
      :container_name => container_name,
      :data_set_js => data_set_js,
      :data_set_names => data_set_names
    }
    
    render :partial => "/shared/graph", :locals => {:options => options}
  end

end
