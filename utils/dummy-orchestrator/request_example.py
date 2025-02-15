import requests
import yaml

# Function to fetch and parse the topology information
def fetch_topology_info(url, provider):
    try:
        # Send GET request to the specified URL
        response = requests.get(url)
        
        # Check if the request was successful
        if response.status_code == 200:
            # Parse the YAML response
            network_info = yaml.safe_load(response.text)
            
            # Extract and display relevant information
            if 'network_info' in network_info:
                network_data = network_info['network_info']
                
                # Common fields
                print(f"Protocol: {network_data.get('protocol')}")
                print(f"VXLAN ID: {network_data.get('vxlan_id')}")
                print(f"UDP Port: {network_data.get('udp_port')}")
                print(f"Consumer Tunnel Endpoint: {network_data.get('consumer_tunnel_endpoint')}")
                print(f"Provider Tunnel Endpoint: {network_data.get('provider_tunnel_endpoint')}")
                
                # Conditional fields based on the provider flag
                if provider:
                    print(f"Provider Subnet: {network_data.get('provider_subnet')}")
                    print(f"Provider Router Endpoint: {network_data.get('provider_router_endpoint')}")
                else:
                    print(f"Consumer Subnet: {network_data.get('consumer_subnet')}")
                    print(f"Consumer Router Endpoint: {network_data.get('consumer_router_endpoint')}")
            else:
                print("Network information not found in the response.")
        else:
            print(f"Error: Unable to fetch data from the URL. Status code: {response.status_code}")
    
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")


# Function to fetch and print the raw YAML response
def fetch_raw_yaml(url):
    try:
        # Send GET request to the specified URL
        response = requests.get(url)
        
        # Check if the request was successful
        if response.status_code == 200:
            # Print the entire raw YAML content
            print(response.text)
        else:
            print(f"Error: Unable to fetch data from the URL. Status code: {response.status_code}")
    
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")

# URL to fetch the data from
url = "http://localhost:9999/topology/consumer-net.yaml"

# Fetch and display the topology info
fetch_topology_info(url, provider=False)

# URL to fetch the data from
url = "http://localhost:9999/topology/provider-net.yaml"

# Fetch and display the topology info
fetch_topology_info(url, provider=True)

# URL to fetch the data from
url = "http://localhost:9999/catalog/consumer-app.yaml"
fetch_raw_yaml(url)
