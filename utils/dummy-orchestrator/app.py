from flask import Flask, send_from_directory, abort
import os

app = Flask(__name__)

# Define the directory where YAML files are stored
YAML_DIR = "./descriptors"

# Ensure the directory exists
if not os.path.exists(YAML_DIR):
    os.makedirs(YAML_DIR)

def serve_yaml_file(descriptor):
    """
    Reusable function to serve YAML files from the YAML directory.
    """
    # Ensure the file is a YAML file
    if not descriptor.endswith(('.yaml', '.yml')):
        abort(400, "Invalid file type. Only YAML files are allowed.")
    
    # Try to serve the requested file if it exists
    try:
        return send_from_directory(YAML_DIR, descriptor)
    except FileNotFoundError:
        abort(404, "File not found.")

@app.route("/catalog/<path:descriptor>", methods=["GET"])
def get_yaml_from_catalog(descriptor):
    return serve_yaml_file(descriptor)

@app.route("/topology/<path:descriptor>", methods=["GET"])
def get_yaml_from_topology(descriptor):
    return serve_yaml_file(descriptor)

if __name__ == "__main__":
    app.run(debug=True)
