# Dockerfile with python & JDK 17 installed
# Build as gumjoe/python-and-jdk-17:latest
# for CI/CD pipeline
FROM python:3.12

# Install JDK 17
RUN apt-get update && apt-get install -y openjdk-17-jdk

# Sanity check
RUN java -version