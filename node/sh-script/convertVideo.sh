#!/bin/bash
vBitrate="1550k"
aBitrate="128k"
overlay="overlay=main_w-overlay_w-20:main_h-overlay_h-20"
rate="30"
logo="./logo.png"
output="output.mp4"
libxopts="-preset veryfast -profile:v main -x264opts level=4.0:ref=1:8x8dct=0:weightp=1:subme=2:mixed-refs=0:trellis=0:vbv-bufsize=25000:vbv-maxrate=20000:rc-lookahead=10"
ffmpeg -f concat -i "list.txt" -i $logo -filter_complex $overlay -c:a ac3 -c:v libx264 $libxopts -b:v $vBitrate -r $rate -b:a $aBitrate $output
