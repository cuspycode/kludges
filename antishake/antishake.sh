#!/bin/bash

# Usage:
#   rm -f stabilized.mp4 mytransforms.trf
#   cpulimit -l 50 -e ffmpeg
#   time sh antishake.sh

FFMPEG="/usr/bin/ffmpeg"
DVDDIR=$HOME/Videos/smalfilm
VOBS=movie/VIDEO_TS/VTS_01_{1,2,3}.VOB

SOURCES=`bash -c "echo $DVDDIR/$VOBS"`

cat $SOURCES |\
	$FFMPEG -nostdin -i - -threads $NTHREADS -vf yadif=0,vidstabdetect=shakiness=10:accuracy=15:result="mytransforms.trf" -f null -

cat $SOURCES |\
	$FFMPEG -nostdin -i - -threads $NTHREADS -vf yadif=0,vidstabtransform=smoothing=25:zoom=1:input="mytransforms.trf",unsharp=13:13:1.4:9:9:1.4 -vcodec h264 -acodec ac3 stabilized.mp4
