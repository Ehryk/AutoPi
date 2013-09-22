require 'Sinatra'

class AutoPi < Sinatra::Base
  def initialize
    super
    @io = WiringPi::GPIO.new
    @serial = WiringPi::Serial.new('/dev/ttyAMA0',9600)

    mode_in  = ['in', 'input', '0', 'read']
    mode_out = ['out', 'output', '1', 'write']
  end
 
  get "/" do
    body "Usage: turn items on or off: /[on|off]/:room/:device to dim /dim/:room/:device/:level. Level should be between 0 and 100."
  end

  get "/gpio/readall" do
    output = `gpio readall`
    result = $?.success?
    body = output
  end
 
  get "/gpio/:action/:pin" do
    case action
      when /on/i
        @io.write(pin, 1)
      when /off/i
        @io.write(pin, 0)
      when /toggle/i
        @io.write(pin, !@io.read(pin))
      when /status/i
        @io.read(pin)
      when /blink/i
        @io.mode(pin, OUTPUT)
        @io.write(pin, 1)
        sleep(1)
        @io.write(pin, 0)
      when /input/i
        @io.mode(pin, INPUT)
      when /output/i
        @io.mode(pin, OUTPUT)
    end
    body "Usage: Interact with GPIO Pins: 
    /gpio/on/:pin - Pulls :pin High
    /gpio/off/:pin - Pulls :pin Low
    /gpio/toggle/:pin - Toggles :pin
    /gpio/status/:pin - Reads Status of :pin (0 = low, 1 = high)
    /gpio/input/:pin - Puts :pin in Input mode
    /gpio/output/:pin - Puts :pin in Output mode 
    Pins are [0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25]"
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