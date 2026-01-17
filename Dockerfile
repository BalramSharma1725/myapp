FROM python:3.10-slim

WORKDIR /app

COPY src/ .

EXPOSE 8080

CMD ["python", "-m", "http.server", "8080"]
