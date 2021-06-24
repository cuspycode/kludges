#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 MINUTES [SECONDS]"
    exit 1
fi
TIMEDIFF=`expr $1 \* 60`
if [ -n "$2" ]; then
    TIMEDIFF=`expr $TIMEDIFF + $2`
fi

FORMAT="\r%02d:%02d "
T0=`date +%s`
T1=`expr $T0 + $TIMEDIFF`
while [ "$TIMEDIFF" -gt 0 ]; do
    MINUTES=`expr $TIMEDIFF / 60`
    SECONDS=`expr $TIMEDIFF % 60`
    printf "$FORMAT" $MINUTES $SECONDS
    sleep 1
    T=`date +%s`
    TIMEDIFF=`expr $T1 - $T`
done

printf "$FORMAT" 0 0
printf "\033[?5h (Press RETURN to continue) "
if [ -n "$TIMERHOOK" ]; then
    $TIMERHOOK
fi
read x
printf "\033[?5l"
