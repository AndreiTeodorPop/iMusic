# Use slim Python 3.11
FROM python:3.11-slim

# Install ffmpeg
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Optional: default port if Railway doesn't set it
ENV PORT=8080
# Optional: number of gunicorn workers (Railway auto-scales, so small number is fine)
ENV WORKERS=3

# Shell form ensures env variables are expanded
CMD gunicorn server:app --bind 0.0.0.0:$PORT --workers $WORKERS
