onerror {resume}
quietly WaveActivateNextPane {} 0
radix -hexadecimal -showbase

add wave -noupdate -group Test_Bench_Signals /ADC0808_tb/*
#add wave -noupdate -group ADC_signals /ADC0808_tb/DUT/*

add wave -noupdate -group Analog_waveforms -divider Sine_wave_input_0_30Hz
add wave -noupdate -group Analog_waveforms -format analog-step -height 50 -min 0 -max 1024 -label in_0 -color #FFFFFF -radix hexadecimal  /ADC0808_tb/in_0

add wave -noupdate -group Analog_waveforms -divider Sine_wave_input_1_300Hz
add wave -noupdate -group Analog_waveforms -format analog-step -height 50 -min 0 -max 1024 -label in_1 -color #00FF00 -radix hexadecimal  /ADC0808_tb/in_1

add wave -noupdate -group Analog_waveforms -divider Sine_wave_input_2_3KHz
add wave -noupdate -group Analog_waveforms -format analog-step -height 50 -min 0 -max 1024 -label in_2 -color #0000FF -radix hexadecimal  /ADC0808_tb/in_2

add wave -noupdate -group Analog_waveforms -divider Selected_Channel																										 
add wave -noupdate -group Analog_waveforms -label Analog_Channel -color #00FFFF /ADC0808_tb/add

add wave -noupdate -group Analog_waveforms -divider ADC_output																											 
add wave -noupdate -group Analog_waveforms -format analog-step -height 50 -min 0 -max 255 -label Salida_ADC -color #FF00FF -radix hexadecimal /ADC0808_tb/output
