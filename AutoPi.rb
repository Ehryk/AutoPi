require 'sinatra/base'
require 'sinatra/reloader'
require 'wiringpi'

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
    body "Usage: turn items on or off: /[on|off]/:room/:device to dim /dim/:room/:device/:level. Level should be between 0 and 100."
  end

  get "/gpio/readall" do
    output = `gpio readall`
    result = $?.success?
    body = output.gsub! "\n", "<br/>"
  end
 
  get "/gpio/:action/:pin" do
    action = params[:action]
    pin = params[:pin].to_i
    case action
      when /on/i
        body = @io.write(pin, 1)
      when /off/i
        body = @io.write(pin, 0)
      when /toggle/i
        body = @io.write(pin, 1 - @io.read(pin))
      when /status/i
        body = @io.read(pin)
      when /read/i
        body = @io.read(pin)
      when /blink/i
        @io.mode(pin, OUTPUT)
        @io.write(pin, 1)
        sleep(1)
        @io.write(pin, 0)
      when /input/i
        body = @io.mode(pin, INPUT)
      when /output/i
        body = @io.mode(pin, OUTPUT)
      when /pwm/i
        body = `gpio pwm 18 500`
    end
  end

  get "/gpio/help" do
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
