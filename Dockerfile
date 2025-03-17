# Use the Ubuntu 24.04 base image for the Python build stage
FROM ubuntu:24.04 AS python-build

# Set environment variables
ENV PYTHON_VERSION=3.13.2

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    curl \
    libbz2-dev \
    libsqlite3-dev \
    wget \
    xz-utils \
    tk-dev \
    liblzma-dev \
    libgdbm-compat-dev

# Copy only the necessary files and directories for configuration and build
COPY . /usr/src/python/

# Configure and build Python
WORKDIR /usr/src/python
RUN ./configure --enable-optimizations && make -j$(nproc) && make altinstall

# Create a virtual environment using the custom Python
RUN /usr/local/bin/python3.13 -m venv /opt/venv

# Set the correct permissions for the virtual environment
RUN chmod -R 755 /opt/venv

# Set the PATH environment variable to include the virtual environment
ENV PATH="/opt/venv/bin:${PATH}"

# Use the Ubuntu 24.04 base image for the final stage
FROM ubuntu:24.04

# Set environment variables
ENV PYTHON_VERSION=3.13.2

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libbz2-dev \
    libsqlite3-dev \
    xz-utils \
    tk-dev \
    liblzma-dev \
    libgdbm-compat-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the Python installation and virtual environment from the build stage
COPY --from=python-build /usr/local /usr/local
COPY --from=python-build /opt/venv /opt/venv

# Set the PATH environment variable to include the virtual environment
ENV PATH="/opt/venv/bin:${PATH}"

# Install app dependencies
COPY requirements.txt /tmp/requirements.txt
RUN /opt/venv/bin/pip install -r /tmp/requirements.txt

# Copy the application code
COPY . /app

# Set the working directory
WORKDIR /app

# Set the default command to run when the container starts
CMD ["bash"]

# Build the Docker image
# docker build -t custom-python-venv:latest .

# Run the Docker container
# docker run -it custom-python-venv:latest

# Run the Docker container with debugging
# docker build --no-cache --progress=plain -t custom-python-venv:latest .