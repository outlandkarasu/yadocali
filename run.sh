#!/bin/sh

DMD=dmd
ROOT=./yadocali
OUT=./out

${DMD} ${ROOT}/peg.d -unittest -od${OUT} -run ${ROOT}/main.d 

