#!/bin/bash

# Default subnet if no argument is provided
SUBNET=""

# Function to display usage information
usage() {
    echo "Usage: $0 --subnet <SUBNET>"
    echo "Example: $0 --subnet 192.168.1.0/24"
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --subnet)
            if [ -n "$2" ]; then
                SUBNET="$2"
                shift # consume argument
            else
                echo "Error: --subnet requires a value."
                usage
            fi
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift # consume option or value
done

# Check if SUBNET was set
if [ -z "$SUBNET" ]; then
    echo "Error: Subnet must be specified."
    usage
fi

# --- Main Logic ---

echo "Scanning subnet: $SUBNET"
echo "Collecting live hosts..."

# Get list of live hosts
LIVE_HOSTS=$(nmap -sn "$SUBNET" | awk '/Nmap scan report/{ip=$NF} /Host is up/{print ip}')

# Expand subnet into full IP list
# We use the -n option with nmap -sL to suppress reverse DNS lookups for faster expansion
ALL_HOSTS=$(nmap -n -sL "$SUBNET" | awk '/Nmap scan report/{print $NF}')

echo
echo "Hosts NOT up:"
echo "----------------"

# Compare ALL_HOSTS vs LIVE_HOSTS
for ip in $ALL_HOSTS; do
    # Use -w (word regex) with grep for an exact match, which is faster and safer than ^$ip$
    if ! echo "$LIVE_HOSTS" | grep -w -q "$ip"; then
        echo "[available]: $ip"
    elif echo "$LIVE_HOSTS" | grep -w -q "$ip"; then
        echo "[TAKEN]: $ip"
    fi
done
