#!/usr/bin/tclsh
quit -sim

set ADC_ROOT "."

exec vlib work


set adc_vhdls [list \
	"$ADC_ROOT/ADC0808.vhd" \
	"$ADC_ROOT/ADC0808_tb.vhd" \
	]
	
foreach src $adc_vhdls {
	if [expr {[string first # $src] eq 0}] {puts $src} else {
		vcom -64 -2008 -work work $src
	}
}

vsim -voptargs=+acc work.ADC0808_tb
do wave.do
run 99 ms
