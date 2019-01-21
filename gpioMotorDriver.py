#!/usr/bin/python
import time
import RPi.GPIO as GPIO
import math

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

pwmA.start(0)
pwmB.start(0)

print "GPIO Motor Driver running.."
try:
    while 1:
        _ = open(SPEED_FILE, 'r'); txt = _.read(); _.close()
        split = txt.split(';')

        speedX = float(split[0])
        speedY = float(split[1])
        lastUpdate = int(split[2])
        delta = millis() - lastUpdate

        if delta > 1000:
          speedX = speedY = 0.0

        angle = math.atan2(speedY, speedX)
        speed = math.sqrt(speedX*speedX + speedY*speedY)

        #leftMotorSpeed = (math.sin(angle) - math.cos(angle)) * speed;
        #rightMotorSpeed = (math.sin(angle) + math.cos(angle)) * speed;
        
        leftMotorSpeed = (-math.sin(angle) + math.cos(angle));
        rightMotorSpeed = (-math.sin(angle) - math.cos(angle));

        print 'sX: %.2f sY: %.2f d: %i  l=%.2f  r=%.2f' % (speedX, speedY, delta, leftMotorSpeed, rightMotorSpeed)

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
        time.sleep(0.1)
except KeyboardInterrupt:
    pass

pwmA.stop()
pwmB.stop()
GPIO.cleanup()
