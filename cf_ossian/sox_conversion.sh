#!/bin/bash

DIR=$(pwd)
cd $OSSIAN/corpus/oji_bl/speakers/nancy_jones/wav/temp

for file in *; do sox "$file" -c 1 -b16 -r 44100 "../new/$file"; done

cd $DIR
sfinfo $OSSIAN/corpus/oji_bl/speakers/nancy_jones/wav/new/Comprehension-1A.wav > wav_info
echo "" >> wav_info
sfinfo $OSSIAN/corpus/rm/speakers/rss_toy_demo/wav/adr_diph1_001.wav >> wav_info
