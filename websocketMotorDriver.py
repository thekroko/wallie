#!/usr/bin/python3
import time
import RPi.GPIO as GPIO
import math
import asyncio
import websockets
import concurrent

PIN_STBY=15
PIN_AIN1=11
PIN_AIN2=13
PIN_PWMA=32
PIN_BIN1=18
PIN_BIN2=16
PIN_PWMB=12

SPEED_FILE="/tmp/wallie/speed"

def millis():
    return int(round(time.time() * 1000))

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BOARD)
GPIO.setup(PIN_STBY, GPIO.OUT)
GPIO.setup(PIN_AIN1, GPIO.OUT)
GPIO.setup(PIN_AIN2, GPIO.OUT)
GPIO.setup(PIN_PWMA, GPIO.OUT)
GPIO.setup(PIN_BIN1, GPIO.OUT)
GPIO.setup(PIN_BIN2, GPIO.OUT)
GPIO.setup(PIN_PWMB, GPIO.OUT)

pwmA = GPIO.PWM(PIN_PWMA, 100)  #  freq
pwmB = GPIO.PWM(PIN_PWMB, 100)  # freq

global lastMessage, lastUpdated, lastMessageWasZero
lastMessage = '0;0'
lastUpdated = millis()
lastMessageWasZero = False

async def echo(websocket, path):
    #async for message in websocket:
    global lastMessage, lastUpdated
    while True:
        message = await websocket.recv()
        lastMessage, lastUpdated = message, millis()
        #print("WebMessage received: %s" % message)
        updateSpeeds(message)

def updateSpeeds(message):
    split = message.split(';')
    speedX = float(split[0])
    speedY = float(split[1])

    global lastMessageWasZero
    lastMessageWasZero = (speedX == 0 and speedY == 0)

    angle = math.atan2(speedY, speedX)
    speed = math.sqrt(speedX*speedX + speedY*speedY)

    leftMotorSpeed = (-math.sin(angle) + math.cos(angle));
    rightMotorSpeed = (-math.sin(angle) - math.cos(angle));

    print('sX: %.2f sY: %.2f l=%.2f r=%.2f lm=%s' % (speedX, speedY, leftMotorSpeed, rightMotorSpeed, lastMessageWasZero))

    GPIO.output(PIN_AIN1, leftMotorSpeed > 0.1)  
    GPIO.output(PIN_AIN2, leftMotorSpeed < 0.1)  
    GPIO.output(PIN_BIN1, rightMotorSpeed > 0.1)  
    GPIO.output(PIN_BIN2, rightMotorSpeed < 0.1)  
    GPIO.output(PIN_STBY, leftMotorSpeed != 0 or  rightMotorSpeed != 0)  

    #pwmAval = min(100.0, math.fabs(leftMotorSpeed) * 100.0);
    #pwmBval = min(100.0, math.fabs(rightMotorSpeed) * 100.0);
    #pwmA.ChangeDutyCycle(pwmAval);
    #pwmB.ChangeDutyCycle(pwmBval);
    pwmB.ChangeDutyCycle(min(100.0, speed * 100.0));
 

async def motorDriverLoop():
    global lastMessageWasZero, lastUpdated

    print("GPIO Motor Driver running..")
    #pwmA.start(0)
    pwmB.start(0)

    while 1:
       if millis() - lastUpdated > 1000 and not lastMessageWasZero:
         updateSpeeds("0;0")
       await asyncio.sleep(1) #time.sleep(1)

async def main():
    print("Setting up webchannel ..")
    await websockets.serve(echo, port=7991)
    await motorDriverLoop()
    print("Main loop finished")

# Main loop
print("Spinning up mainloop")
try: 
  result = asyncio.get_event_loop().run_until_complete(main())
except KeyboardInterrupt:
  print("Keyboard interrupt detected...")
  pass

print("Cleaning up GPIOs")
pwmA.stop()
pwmB.stop()
GPIO.cleanup()
