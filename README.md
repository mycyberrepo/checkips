# Check IPs

Takes a list of IP addresses stored in a file, looks them up using abuseipdb.com, and writes the output to a CSV file.

```
Usage: 
./checkips.sh input_file output_file
Output a CSV of abuseipdb information based on a file of IP addresses.
An abuseipdb API key must be stored in env var 'ABUSE_IP_DB_API_KEY.'
  -i input_file    File path to a newline-separated list of IPs
  -o output_file   File path for the output file
  -m maxAgeInDays  How far back in time to check reports (default 60). 
                   Values must be between 1-365 inclusive.
```
# Dependencies

1. bash
1. jq

# Read Also
This script is NOT endorsed, sponsored by, or in any way affiliated with abuseipdb.com or any of its owners.

Read the Terms of Use in the script before using or distributing.