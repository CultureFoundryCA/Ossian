#!/bin/bash

## CultureFoundry Ossian Install Script
## For internal use only. Not sure on license compliance because I edited the provided Ossian install script a good bit.

echo
echo "CultureFoundry Ossian Install Script"
echo "Starting..."
echo

## Get the directory that this setup file is in. Ossian will install into $DIR/../ossian_env/ossian
DIR="${0%/*}"
## Set the Ossian environment directory
ENVDIR="$DIR/../ossian_env"
## Remove any previous installation attempt
rm -rf "$ENVDIR"
## Make new Ossian environment directory
mkdir "$ENVDIR"

## To install when using Anaconda3, just give this script any argument; only really necessary when using GPU opitimizations since you need conda for theano.
if [ "$#" -ne 0 ] ; then

    ## Install for using Anaconda3. Manually type in these lines before running the setup script:
    ## conda create -n ossian python=2.7
    ## conda activate ossian
    conda install numpy scipy scikit-learn configobj regex lxml
    python -m pip install argparse
    python -m pip install bandmat
    conda install theano matplotlib
    
fi

## Install Ossian in a python2 virtual environment (might as well use when not using GPU optimizations)
if [ "$#" -eq 0 ] ; then

    ## Install python2 virutalenv
    python2 -m pip install virtualenv 2>&1 | tee "$ENVDIR/ossian_install.log"

    ## Set up the python2 virtualenv in ossian_env
    python2 -m virtualenv "$ENVDIR" 2>&1 | tee -a "$ENVDIR/ossian_install.log"

    ## Start the virtual environment
    source "$ENVDIR/bin/activate"

    ## Dependencies for Ossian
    python -m pip install numpy scipy configobj scikit-learn regex lxml argparse 2>&1 | tee -a "$ENVDIR/ossian_install.log"
    ## Dependencies for Merlin
    python -m pip install bandmat theano matplotlib 2>&1 | tee -a "$ENVDIR/ossian_install.log"
    
fi


## Get Ossian
git clone https://github.com/CSTR-Edinburgh/Ossian.git "$ENVDIR/ossian" | tee -a "$ENVDIR/ossian_install.log"

## Replace Ossian setup_tools with our own that works
mv "$ENVDIR/ossian/scripts/setup_tools.sh" "$ENVDIR/ossian/scripts/setup_tools.sh.orig"
cp "$DIR/cf_ossian_install_patch.sh" "$ENVDIR/ossian/scripts/setup_tools.sh"

## Copy the run_ossian.sh script into the ossian_env folder
cp "$DIR/run_ossian.sh" "$ENVDIR/"


## Install Ossian
"$ENVDIR/ossian/scripts/setup_tools.sh" culturefoundry @cwdmSwg 2>&1 | tee -a "$ENVDIR/ossian_install.log"


echo
echo "CultureFoundry Ossian Install Script finished."
echo "Please check '$ENVDIR/ossian_install.log' for any errors; use ctrl+f to search for 'error'. If you got an 'ERROR 503', that is an error from one of the download servers and you have to wait like 10 minutes and then try running this setup script again."
echo "To start the virtual environment, cd into $ENVDIR and run 'source /bin/activate'. To leave the virtual environment, type 'deactivate'."
echo

if [ "$#" -ne 0 ] ; then 
    echo "Type `conda deactivate` to leave the conda virtual environment, and `conda activate ossian` to re-enter it."
fi

if [ "$#" -eq 0 ] ; then
    echo "Type `deactivate` to leave the python2 virutalenv, and then `source $ENVDIR/bin/activate` too re-enter it."
fi

echo
