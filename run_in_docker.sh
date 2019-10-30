#!/bin/sh

docker run -it --mount src="$(pwd)",target=/xclogparser,type=bind xclogparser
