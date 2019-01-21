#!/usr/bin/env python
from ina219 import INA219
from ina219 import DeviceRangeError
import time

SHUNT_OHMS = 0.1
MAX_EXPECTED_AMPS = 3.3
SAMPLING_DELAY_SECS=5
SAMPLES_TO_KEEP = 60*60*3/SAMPLING_DELAY_SECS
LOG="/tmp/wallie/power.csv"
CUR="/tmp/wallie/power.txt"

ina = INA219(SHUNT_OHMS)
ina.configure(ina.RANGE_16V, shunt_adc=ina.ADC_128SAMP)

lastEntries = []
samplesToDrop = 10

while True:
    try:
        line = "%i,%.3f,%.3f,%.3f\n" % (int(time.time()), ina.voltage(), ina.current(), ina.power())
        lastEntries = lastEntries[-SAMPLES_TO_KEEP:] + [line]
        print line
        if samplesToDrop > 0:
            samplesToDrop = samplesToDrop - 1
        else:
          with open(LOG, "w") as logFile:
              logFile.writelines(lastEntries)
        with open(CUR, "w") as curFile:
          curFile.write(line)
    except DeviceRangeError as e:
        # Current out of device range with specified shunt resister
        print(e)

    time.sleep(SAMPLING_DELAY_SECS)
