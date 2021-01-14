#!/bin/bash

## CultureFoundry Ossian Operation Script

## Commands are: start, duration, duration_gpu, acoustic, acoustic_gpu, synth, all, all_gpu

LANG="$1"
SPEAKER="$2"
RECIPE="$3"
COMMAND="$4"
INPUT="$LANG $SPEAKER $RECIPE"

if [ "$#" -ne 4 ] ; then

    echo "Not enough arguments supplied."
    echo "Should be ./ossian.sh LANG SPEAKER RECIPE COMMAND"
    echo -e "Valid commands are: start, duration, duration_gpu,\nacoustic, acoustic_gpu, synth, all, all_gpu."
    exit 1
    
fi

TRAINDIR="$OSSIAN"/train/"$LANG"/speakers/"$SPEAKER"/"$RECIPE"
VOICESDIR="$OSSIAN"/voices/"$LANG"/"$SPEAKER"/"$RECIPE"

#source "$OSSIAN"/../bin/activate

## Run everything
if [ "$COMMAND" == "all" ] ; then
    
    "$0" $INPUT start
    "$0" $INPUT duration
    "$0" $INPUT acoustic
    "$0" $INPUT synth
    
fi

## Run everything using the GPU (NOTE: not sure if this makes it portable onto non-GPU machines)
if [ "$COMMAND" == "all_gpu" ] ; then
    
    "$0" $INPUT start
    "$0" $INPUT duration_gpu
    "$0" $INPUT acoustic_gpu
    "$0" $INPUT synth
    
fi
    

## Begin the training
if [ "$COMMAND" == "start" ] ; then
    
    ## Remove previous build attempt
    rm -rf "$TRAINDIR" "$VOICESDIR"
    
    ## Start the voice training
    ## Need that env call in order to shut perl up about unrecognized OS language settings
    env LANG=C python "$OSSIAN"/scripts/train.py -s "$SPEAKER" -l "$LANG" "$RECIPE" -text "."

fi

## Train the duration model in Merlin, and convert the output into the form suitable for Ossian
if [ "$COMMAND" == "duration" ] ; then
    
    ## Do the duration training in Merlin
    export THEANO_FLAGS=""
    python "$OSSIAN"/tools/merlin/src/run_merlin.py "$TRAINDIR"/processors/duration_predictor/config.cfg
    
    ## Export the Merlin generated files to Ossian-compatible format
    python "$OSSIAN"/scripts/util/store_merlin_model.py "$TRAINDIR"/processors/duration_predictor/config.cfg "$VOICESDIR"/processors/duration_predictor
    
fi

## Train the duration model in Merlin using the GPU, and convert the output into the form suitable for Ossian (NOTE: not sure if this makes it portable onto non-GPU machines)
if [ "$COMMAND" == "duration_gpu" ] ; then
    
    ## Do the duration training on the GPU in Merlin
    export THEANO_FLAGS="mode=FAST_RUN,device=cuda,floatX=float32,on_unused_input=ignore"
    python "$OSSIAN"/tools/merlin/src/run_merlin.py "$TRAINDIR"/processors/duration_predictor/config.cfg
    
    ## Export the Merlin generated files to Ossian-compatible format
    python "$OSSIAN"/scripts/util/store_merlin_model.py "$TRAINDIR"/processors/duration_predictor/config.cfg "$VOICESDIR"/processors/duration_predictor
    
fi

## Train the acoustic model in Merlin, and convert the output into the form suitable for Ossian
if [ "$COMMAND" == "acoustic" ] ; then
    
    ## Do the acoustic training in Merlin
    export THEANO_FLAGS=""
    python "$OSSIAN"/tools/merlin/src/run_merlin.py "$TRAINDIR"/processors/acoustic_predictor/config.cfg
    
    ## Export the Merlin generated files to Ossian-compatible format
    python "$OSSIAN"/scripts/util/store_merlin_model.py "$TRAINDIR"/processors/acoustic_predictor/config.cfg "$VOICESDIR"/processors/acoustic_predictor
    
fi

## Train the acoustic model in Merlin using the GPU, and convert the output into the form suitable for Ossian (NOTE: not sure if this makes it portable onto non-GPU machines)
if [ "$COMMAND" == "acoustic_gpu" ] ; then
    
    ## Do the acoustic training on the GPU in Merlin
    export THEANO_FLAGS="mode=FAST_RUN,device=cuda,floatX=float32,on_unused_input=ignore"
    python "$OSSIAN"/tools/merlin/src/run_merlin.py "$TRAINDIR"/processors/acoustic_predictor/config.cfg
    
    ## Export the Merlin generated files to Ossian-compatible format
    python "$OSSIAN"/scripts/util/store_merlin_model.py "$TRAINDIR"/processors/acoustic_predictor/config.cfg "$VOICESDIR"/processors/acoustic_predictor
    
fi

## Generate a wave file using the sample text stored in the ossian/test/txt folder, and place the test recording in ossian/test/wav. This script expects a file $LANG.txt in ossian/test/text.
if [ "$COMMAND" == "synth" ] ; then

    TESTNAME="$LANG"_"$SPEAKER"_test.wav
    
    ## Remove previous test output generation
    rm -rf "$OSSIAN"/test/wav/"$TESTNAME"
    
    python "$OSSIAN"/scripts/speak.py -l "$LANG" -s "$SPEAKER" -o "$OSSIAN"/test/wav/"$TESTNAME" -lab "$RECIPE" "$OSSIAN"/test/txt/"$LANG".txt 
    
fi

#deactivate
