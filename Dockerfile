FROM swift:5.1
RUN apt-get update && apt-get install -y zlib1g-dev
CMD cd xclogparser && swift build
