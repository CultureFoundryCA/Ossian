#!/bin/bash

# CultureFoundry
# This file takes two parameters, first is path to the utterance file to split, second is the path to where to save the broke up utterances.
# For example: ./utts_conversion.sh $TTS/festival/lib/voices/oji/utts.data $TTS/ossian/corpus/oji/speakers/nancy_jones/txt/

if [ $# -ne 2 ] ; then
    echo "Wrong number of input parameters."
    echo "First parameter should be the path to the utts file, second parameter be the path where you want to save the broken up text files."
    exit 1
fi

# path to the utterance file to break up
utts_file="$1"
# path to where to save the broken up utterances
utts_save="$2"

while IFS= read -r line; do

    # $line is of the format '( file_name "utterance spoken" )'
    # this script creates a file called file_name that has the text 'utterance spoken' in it

    # capture '( file_name'
    temp_name="${line% \"*}"
    # capture 'file_name'    
    name="${temp_name#( }"
    
    # capture 'utterance spoken" )'
    temp_utt="${line#( * \"}"
    # capture 'utterance spoken'
    utt="${temp_utt%\"*}"
    
    output="$utts_save$name".txt
    
    # echo 'utterance spoken' to a file named 'file_name'
    echo "$utt" > "$output"
    
done < "$utts_file"
