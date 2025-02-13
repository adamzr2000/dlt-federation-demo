#!/bin/bash

# Default port
PORT=9999

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port) PORT="$2"; shift ;;
    esac
    shift
done

export FLASK_APP=app.py
export FLASK_ENV=development
flask run --host=0.0.0.0 --port=$PORT
