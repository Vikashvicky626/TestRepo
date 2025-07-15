FROM python:3.11-slim

WORKDIR /app

# Install netcat-openbsd and dependencies
RUN apt-get update && apt-get install -y netcat-openbsd gcc libpq-dev

COPY . .

RUN pip install --no-cache-dir fastapi uvicorn psycopg2-binary python-jose[cryptography]

RUN chmod +x /app/wait-for-it.sh

CMD ["./wait-for-it.sh", "db", "5432", "--", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
