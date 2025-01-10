# Jack's image, but with more tools inside using Jamie's advice
# Known as the "slim" version as it doesn't have the backend compiler in
# Build on work by:
# Jack McComish <jm1922>
# Jamie Willis

FROM gumjoe/wacc-ci-scala:slim

# BACKEND
# Allow us to set our target architecture
ARG COMPILER
ARG TEST_COMMAND
# Install gcc-multilib first for cross compiler support

RUN apt-get install -y $COMPILER
# We assume you tag this as required
# Check it works
RUN ${TEST_COMMAND} --version

# Install QEMU
ARG QEMU_PACKAGE
ARG QEMU_TEST_COMMAND
RUN apt-get install -y ${QEMU_PACKAGE}
RUN ${QEMU_TEST_COMMAND} --version