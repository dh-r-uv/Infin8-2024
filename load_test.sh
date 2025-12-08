#!/bin/bash
# Load Generator for Infin8 HPA Testing

URL=$1

if [ -z "$URL" ]; then
  echo "Usage: ./load_test.sh <URL>"
  echo "Example: ./load_test.sh http://192.168.49.2:30123"
  exit 1
fi

echo "Starting load test on $URL..."
echo "Press CTRL+C to stop."

while true; do
  curl -s -o /dev/null "$URL"
done
