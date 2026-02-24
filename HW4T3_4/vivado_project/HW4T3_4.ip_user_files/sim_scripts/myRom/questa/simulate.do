onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib myRom_opt

do {wave.do}

view wave
view structure
view signals

do {myRom.udo}

run -all

quit -force
