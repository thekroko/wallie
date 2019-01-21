#!/usr/bin/env python
from ina219 import INA219
from ina219 import DeviceRangeError
import time

SHUNT_OHMS = 0.1
MAX_EXPECTED_AMPS = 3.3

ina = INA219(SHUNT_OHMS)
ina.configure(ina.RANGE_16V, shunt_adc=ina.ADC_128SAMP)

try:
    print("vBus=%.3fV	iBus=%.3fmA	p=%.3fmW	vShunt=%.3fmV" % (ina.voltage(), ina.current(), ina.power(), ina.shunt_voltage()))
except DeviceRangeError as e:
    print(e)
