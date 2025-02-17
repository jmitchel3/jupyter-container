# Use a slim Python image
FROM python:3.13-slim

ARG NOTEBOOKS_DIR=${NOTEBOOKS_DIR:-/notebooks}
# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Jupyter and common data science packages
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
    jupyter \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn \
    && jupyter notebook --generate-config

# Copy and run install_packages script for additional requirements
COPY ./build_scripts/install_packages.sh /opt/install_packages.sh
RUN chmod +x /opt/install_packages.sh
ARG PY_REQUIREMENTS
RUN /opt/install_packages.sh "${PY_REQUIREMENTS}" "${NOTEBOOKS_DIR}"

# Create a working directory
RUN mkdir -p "${NOTEBOOKS_DIR}"
COPY ./samples "${NOTEBOOKS_DIR}/samples"

WORKDIR "${NOTEBOOKS_DIR}"

# Expose Jupyter port
EXPOSE 8888


# create a bash script to run the Jupyter notebook
# this script will execute at runtime when
# the container starts and the database is available
RUN printf "#!/bin/bash\n" > /opt/jupyter_runner.sh && \
    printf "jupyter notebook --ip=\${JUPYTER_IP:-0.0.0.0} --port=\${PORT:-8888} --no-browser --allow-root --NotebookApp.password=\$(python -c \"from jupyter_server.auth import passwd; print(passwd('\$JUPYTER_PASSWORD'))\")\n" >> /opt/jupyter_runner.sh

# make the bash script executable
RUN chmod +x /opt/jupyter_runner.sh


# Start Jupyter notebook with password authentication
CMD ["sh", "-c", "/opt/jupyter_runner.sh"] 