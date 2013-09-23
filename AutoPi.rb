require 'sinatra/base'
require 'sinatra/reloader'
require 'wiringpi'
require 'json'

class AutoPi < Sinatra::Base
  def initialize
    super
    @io = WiringPi::GPIO.new
    @serial = WiringPi::Serial.new('/dev/ttyAMA0',9600)

    mode_in  = ['in', 'input', '0', 'read']
    mode_out = ['out', 'output', '1', 'write']
  end

  configure :development do
    register Sinatra::Reloader
  end
 
  get "/" do
    body "<div>Garage<br/>
    Lights<br/> 
    GPIO</div>"
  end

  get "/gpio/readall" do
    output = `gpio readall`
    result = $?.success?
    lines = output.split( /\r?\n/ )
    lines.delete_at(20)
    lines.delete_at(2)
    lines.delete_at(0)
    lines[0].sub! "|", ""
    lines[0].gsub! "|", "</th><th>"
    lines[0] = "<th>" + lines[0] + "</th>"
    table = lines.join("\n")
    table.gsub! "\n|", "\n<tr><td>"
    table.gsub! "\n", "</td></tr>"
    table.gsub! "|", "</td><td>"
    table = "<table><tr>" + table + "</tr></table>"
    
    body = table
  end
 
  post "/gpio/?:action?/?:pin?*" do
    content_type :json
    action = params[:action]
    pin = params[:pin].to_i
    case action
      when /on|high|1/i
        @io.write(pin, 1)
        result = @io.read(pin)
      when /off|low|0/i
        @io.write(pin, 0)
        result = @io.read(pin)
      when /toggle|flip/i
        @io.write(pin, 1 - @io.read(pin))
        result = @io.read(pin)
      when /status/i
        result = @io.read(pin)
      when /read/i
        result = @io.read(pin)
      when /blink/i
        @io.mode(pin, OUTPUT)
        @io.write(pin, 1)
        sleep(1)
        @io.write(pin, 0)
        result = @io.read(pin)
      when /input/i
        @io.mode(pin, INPUT)
        result_text = "in Input mode"
      when /output/i
        @io.mode(pin, OUTPUT)
        result_text = "in Output mode"
      when /pwm/i
        `gpio pwm 18 500`
        result = @io.read(pin)
      else
        result = nil
    end
    if result_text.nil?
      result_text = result == 1 ? "High" : "Low"
    end
    { :pin => pin, :value => result, :text => result_text, :success => !result.nil?, :result => !result.nil? ? "success" : "failed" }.to_json
  end

  get "/gpio/:action/:pin" do
    action = params[:action]
    pin = params[:pin].to_i
    case action
      when /on|high|1/i
        @io.write(pin, 1)
        result = @io.read(pin)
      when /off|low|0/i
        @io.write(pin, 0)
        result = @io.read(pin)
      when /toggle|flip/i
        @io.write(pin, 1 - @io.read(pin))
        result = @io.read(pin)
      when /status/i
        result = @io.read(pin)
      when /read/i
        result = @io.read(pin)
      when /blink/i
        @io.mode(pin, OUTPUT)
        @io.write(pin, 1)
        sleep(1)
        @io.write(pin, 0)
        result = @io.read(pin)
      when /input/i
        @io.mode(pin, INPUT)
        result_text = "in Input mode"
      when /output/i
        @io.mode(pin, OUTPUT)
        result_text = "in Output mode"
      when /pwm/i
        `gpio pwm 18 500`
        result = @io.read(pin)
    end
    if result_text.nil?
      result_text = result == 1 ? "High" : "Low"
    end
    body = "Pin #{pin} is #{result_text}"
  end

  get "/gpio*" do
    help = "<div>Usage: Interact with GPIO Pins:<br/> 
    /gpio/on/:pin - Pulls :pin High<br/>
    /gpio/off/:pin - Pulls :pin Low<br/>
    /gpio/toggle/:pin - Toggles :pin<br/>
    /gpio/status/:pin - Reads Status of :pin (0 = low, 1 = high)<br/>
    /gpio/read/:pin - Same as Status<br/>
    /gpio/input/:pin - Puts :pin in Input mode<br/>
    /gpio/output/:pin - Puts :pin in Output mode<br/>
    Pins are [0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25]</div>"
  end

  get "/gpio/set/:pin/:mode" do
    case mode
      when *mode_in
        @io.mode(pin, INPUT)
      when *mode_out
        @io.mode(pin, OUTPUT)
    end
  end

  get "/:room/:device/:action/?:level?" do |room, device, action, level|
    return [422, "Level required for dim"] if action == "dim" && !level
    case action
    when /on/i
      @lightwave.turn_on(room, device)
    when /off/i
      @lightwave.turn_off(room, device)
    when /dim/i
      puts level
      @lightwave.dim(room, device, level.to_i)
    else
      return [422, "Unknown action #{action}"]
    end
    body "Room #{room} Device #{device} #{action}#{" to #{level}%" if level}."
  end
end
