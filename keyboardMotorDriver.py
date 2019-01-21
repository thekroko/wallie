#!/usr/bin/python
import time
import RPi.GPIO as GPIO
import math
import pygame, sys
from pygame.locals import *

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
pygame.init()
windowSurface = pygame.display.set_mode((100, 100), 0, 32)

keyLeft = False
keyUp = False
keyDown = False
keyRight = False

try:
    while 1:
        for event in pygame.event.get():
            if event.type == QUIT:
                pygame.quit()
                sys.exit()
            if event.type == KEYDOWN:
                key = event.key
                print 'KeyDn: %s' % key
                if key == pygame.K_LEFT:
                    keyLeft = True
                if key == pygame.K_UP:
                    keyUp = True
                if key == pygame.K_DOWN:
                    keyDown = True
                if key == pygame.K_RIGHT:
                    keyRight = True
            if event.type == KEYUP:
                key = event.key
                print 'KeyUp: %s' % key
                if key == pygame.K_LEFT:
                    keyLeft = False
                if key == pygame.K_UP:
                    keyUp = False
                if key == pygame.K_DOWN:
                    keyDown = False
                if key == pygame.K_RIGHT:
                    keyRight = False

        speedX = 0
        speedY = 0
        if keyUp:
            speedX = 0
            speedY = 1
        elif keyDown:
            speedX = 0
            speedY = -1
        elif keyLeft:
            speedX = -0.5
            speedY = 0
        elif keyRight:
            speedX = 0.5
            speedY = 0;

        delta = 0

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
