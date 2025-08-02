FROM debian:bookworm-slim

# Install dependencies for all database clients
RUN apt-get update \
    && apt-get install -y \
    # General utilities
    curl \
    gnupg \
    vim-tiny \
    unzip \
    # Oracle client dependency
    libaio1 \
    # PostgreSQL client
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install MongoDB Client
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update \
    && apt-get install -y mongodb-org-tools mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*

# Install Oracle Client
WORKDIR /opt/oracle
# These URLs are for Oracle 21c, matching the database version.
# Note: These links can become outdated.
RUN curl -o instantclient-basiclite.zip https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-basiclite-linux.x64-21.13.0.0.0dbru.zip && \
    curl -o instantclient-sqlplus.zip https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-sqlplus-linux.x64-21.13.0.0.0dbru.zip && \
    unzip instantclient-basiclite.zip && \
    unzip instantclient-sqlplus.zip && \
    rm -f *.zip

# Set environment variables for Oracle Client
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_21_13
ENV PATH=$PATH:/opt/oracle/instantclient_21_13

# Set the final working directory back to the project workspace
WORKDIR /workspaces/db-assignment-2
