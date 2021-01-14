#!/bin/bash 

### This is the CultureFoundry Ossian setup_tools.sh replacement file. It's basically the exact same file as the original Ossian setup_tools just with a bunch of edits.
### Definitely for internal use only, not sure how it complies with the licenses but I've marked down every edit I've made.

### This installs everything needed for the naive recipe:
BASIC=1

### The following are only needed to train letter-to-sound rules, and for the gold standard english systems:
SEQUITUR=1 
## CultureFoundry Edit --> Removed STANDFORD install


## Location of this script:-
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

OSSIAN=$SCRIPTPATH/../


if [ $BASIC == 1 ] ; then

    ## CultureFoundry Edit --> removed if for checking parameters as no parameters needed as we hand coded in the HTK user and pass.

    ## setup script based on http://homepages.inf.ed.ac.uk/owatts/ossian/html/setting_up.html
    HTK_USERNAME=$1
    HTK_PASSWORD=$2

    ## Assuming that you want to compile everything cleanly from scratch:
    rm -rf $OSSIAN/tools/downloads/*
    rm -rf $OSSIAN/tools/bin/*

    cd $OSSIAN/tools/
    git clone https://github.com/CSTR-Edinburgh/merlin.git
    cd merlin
    ## reset to this specific version, which I have tested, must check later versions:--
    git reset --hard 8aed278  

    ## Ossian will use Merlin's copy of World, instead of its own as previously:-
    cd $OSSIAN/tools/merlin/tools/WORLD/
    make -f makefile
    make -f makefile analysis
    make -f makefile synth
    mkdir -p $OSSIAN/tools/bin/
    cp $OSSIAN/tools/merlin/tools/WORLD/build/{analysis,synth} $OSSIAN/tools/bin/
    
    ## Make sure these locations exist:
    mkdir -p $OSSIAN/tools/bin
    mkdir -p $OSSIAN/tools/downloads

    cd $OSSIAN/tools/downloads

    ## Download HTK source code:
    wget http://htk.eng.cam.ac.uk/ftp/software/HTK-3.4.1.tar.gz --http-user=$HTK_USERNAME --http-password=$HTK_PASSWORD
    wget http://htk.eng.cam.ac.uk/ftp/software/hdecode/HDecode-3.4.1.tar.gz  --http-user=$HTK_USERNAME --http-password=$HTK_PASSWORD

    ## Download HTS patch:
    wget http://hts.sp.nitech.ac.jp/archives/2.3alpha/HTS-2.3alpha_for_HTK-3.4.1.tar.bz2

    ## Unpack everything:
    tar -zxvf HTK-3.4.1.tar.gz
    tar -zxvf HDecode-3.4.1.tar.gz
    tar -xvf HTS-2.3alpha_for_HTK-3.4.1.tar.bz2
    
    ## CultureFoundry Edit --> fix the line from HTK's HLMTools' Makefile line 77 which is separated by 8 spaces instead of a tab...
    sed -i '77 c\	if [ ! -d $(bindir) -a X_@TRADHTK@ = X_yes ] ; then mkdir -p $(bindir) ; fi' $OSSIAN/tools/downloads/htk/HLMTools/Makefile.in

    ## CultureFoundry Edit --> fix the line from htk/HTKLib/HRec.c; THIS MUST BE APPLIED BEFORE THE HTS PATCH
    #sed -i '1626 c\            if (dur<=0 && labpr != splabid) HError(8522,"LatFromPaths: Align have dur<=0 "); /* CultureFoundry Edit: replace labid with labpr */' $OSSIAN/tools/downloads/htk/HTKLib/HRec.c
    #sed -i '1650 c\            if (dur<=0 && labpr != splabid) HError(8522,"LatFromPaths: Align have dur<=0 "); /* CultureFoundry Edit: replace labid with labpr */' $OSSIAN/tools/downloads/htk/HTKLib/HRec.c
    
    
    
    ## Apply HTS patch:
    cd htk
    patch -p1 -d . < ../HTS-2.3alpha_for_HTK-3.4.1.patch

    ## Apply the Ossian patch:
    patch -p1 -d . < ../../patch/ossian_hts.patch



    ## Finally, configure and compile:
    ## CultureFoundry Edit: added --enable-hdecode, --enable-hlmtools and gcc-8
    ./configure --prefix=$OSSIAN/tools/ --enable-hdecode --enable-hlmtools CC=gcc-8 --disable-hslab --without-x
    make
    make install

    ## Get hts_engine:
    cd $OSSIAN/tools/downloads
    wget http://sourceforge.net/projects/hts-engine/files/hts_engine%20API/hts_engine_API-1.05/hts_engine_API-1.05.tar.gz
    tar xvf hts_engine_API-1.05.tar.gz
    cd hts_engine_API-1.05
    ## Patch engine for use with Ossian (glottHMM compatibility):
    patch -p1 -d . < ../../patch/ossian_engine.patch
    ./configure --prefix=$OSSIAN/tools/
    make
    make install

    ## Get SPTK:
    cd $OSSIAN/tools/downloads
    wget http://downloads.sourceforge.net/sp-tk/SPTK-3.6.tar.gz
    tar xvf SPTK-3.6.tar.gz
    cd SPTK-3.6
    ## CultureFoundry Edit --> added CC=gcc-8 because compilation fails with gcc10 
    ./configure --prefix=$OSSIAN/tools/ CC=gcc-8

    if [ "$(uname)" == "Darwin" ]; then
        ## To compile on Mac, modify Makefile for delta tool:
        mv ./bin/delta/Makefile ./bin/delta/Makefile.BAK
        sed 's/CC = gcc/CC = clang/' ./bin/delta/Makefile.BAK > ./bin/delta/Makefile     ## (see http://sourceforge.net/p/sp-tk/bugs/68/)
    fi
    
    make
    make install

    # CultureFoundry Edit --> removed binary counter
    
    # CultureFoundry Edit --> added installer cleanup below
    cd ..
    rm -rf HTK-3.4.1.tar.gz
    rm -rf HDecode-3.4.1.tar.gz
    rm -rf HTS-2.3alpha_for_HTK-3.4.1.tar.bz2
    rm -rf hts_engine_API-1.05.tar.gz
    rm -rf SPTK-3.6.tar.gz
    rm ChangeLog COPYING HTS_Document.pdf README INSTALL
    rm HTS-2.3alpha_for_HTK-3.4.1.patch

fi

## Sequitur G2P
if [ $SEQUITUR == 1 ] ; then

    rm -rf $OSSIAN/tools/g2p/ 

    # Sequitur G2P
    cd $OSSIAN/tools/
    wget https://www-i6.informatik.rwth-aachen.de/web/Software/g2p-r1668-r3.tar.gz
    tar xvf g2p-r1668-r3.tar.gz
    rm -r g2p-r1668-r3.tar.gz
    cd g2p

    if [ `uname -s` == Darwin ] ; then
        # Patch to avoid compilation problems on Mac OS relating to tr1 libraries like this:
        #
        # In file included from ./Multigram.hh:33:
        # ./UnorderedMap.hh:26:10: fatal error: 'tr1/unordered_map' file not found
        # #include <tr1/unordered_map>     
        echo 'Apply patch to sequitur for compilation on Mac OS...'
        patch -p1 -d . < ../patch/sequitur_compilation.patch
    fi

    ## Compile:
    # CultureFoundry Edit --> changed python to python2
    python setup.py install --prefix  $OSSIAN/tools

fi
