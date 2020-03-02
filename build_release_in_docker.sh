#!/bin/sh

docker image build -t xclogparser .
docker run -it --mount src="$(pwd)",target=/xclogparser,type=bind xclogparser bin/sh -c "cd xclogparser && swift build -c release"  

DESTINATION_PATH=releases/linux
mkdir -p "$DESTINATION_PATH"
cp .build/x86_64-unknown-linux/release/xclogparser "$DESTINATION_PATH"
zip -X -r "$DESTINATION_PATH"/XCLogParser-x.x.x-Linux.zip "$DESTINATION_PATH"/xclogparser