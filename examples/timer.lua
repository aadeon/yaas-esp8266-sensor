--local timer = require 'timer'
local LED_PIN1 = 4
gpio.mode(LED_PIN1, gpio.OUTPUT)
local sw1 = true
tmr.alarm(0, 1000, tmr.ALARM_AUTO, function ()
    print "Interval"
    if (sw1) then
        gpio.write(LED_PIN1, gpio.LOW)
    else
        gpio.write(LED_PIN1, gpio.HIGH)
    end
    sw1 = not sw1
end)
