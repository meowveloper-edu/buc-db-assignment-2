FROM debian:bookworm-slim

RUN apt-get update \ 
    && apt-get install -y postgresql-client curl gnupg vim-tiny \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update && apt-get install -y mongodb-org-tools mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*