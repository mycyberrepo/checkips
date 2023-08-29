#!/bin/bash

# Read the LICENSE file before use.
# This script is NOT endorsed, sponsored by, or in any way affiliated
# with abuseipdb.com or any of its owners.

#################################################################
# PURPOSE
# The intent of this script is to automate queries against the IP
# check API of abuseipdb.com.
#################################################################

#################################################################
# Print usage statement
#################################################################
function usage {
  echo "Usage: ${0} input_file output_file"
  echo "Output a CSV of abuseipdb information based on a file of IP addresses."
  echo "An abuseipdb API key must be stored in env var 'ABUSE_IP_DB_API_KEY.'"
  echo "  -i input_file    File path to a newline-separated list of IPs"
  echo "  -o output_file   File path for the output file"
  echo "  -m maxAgeInDays  How far back in time to check reports (default 60). Values must be between 1-365 inclusive."
}

#################################################################
# Set default parameters
#################################################################
max_age=60

#################################################################
# Parse options passed in
#################################################################
while [[ $# -gt 0 ]]; do
  case $1 in
    -i)
      input_file=$2
      shift
      shift
      ;;
    -o)
      output_file=$2
      shift
      shift
      ;;
    -m)
      max_age=$2
      shift
      shift
      ;;
    *)
      echo "Invalid option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

#################################################################
# Check input
#################################################################
if [ -z "$ABUSE_IP_DB_API_KEY" ]; then
  echo "An abuseipdb API key must be stored in env var 'ABUSE_IP_DB_API_KEY.'"
  exit 2
fi

if [ -z "$input_file" ]; then
  usage
  exit 3
fi

if [ -z "$output_file" ]; then
  usage
  exit 4
fi

if [ ! -f "$input_file" ]; then
  echo "***Input file not found***"
  exit 5
fi

echo 'ipAddress,isPublic,ipVersion,isWhitelisted,abuseConfidenceScore,countryCode,usageType,isp,domain,hostnames,isTor,totalReports,numDistinctUsers,lastReportedAt' > $output_file
if [ ! -w "$output_file" ]; then
  echo "***You do not have permission to write to the file \"$output_file\"***"
  exit 6
fi

if [[ -n ${max_age//[0-9]/} ]]; then
  echo "***max_age must be a natural number 1-365***"
  usage
  exit 7
fi

if [ "$max_age" -gt 365 ] || [ "$max_age" -lt 1 ]; then
  echo "***max_age is out of range!***"
  usage
  exit 8
fi

#################################################################
# Process the file
#################################################################
# Loop through each IP address in the file
while read ip; do
  # Query AbuseIPDB's check endpoint for the current IP address
   echo "Checking IP $ip"
    response=$(curl -s -G https://api.abuseipdb.com/api/v2/check \
       --data-urlencode "ipAddress=$ip" \
       -H "Key: $ABUSE_IP_DB_API_KEY" \
       -H "Accept: application/json" \
       -d maxAgeInDays=$max_age)

  # Write the response to the output file
  echo $response | jq -r '.data | [.ipAddress, .isPublic, .ipVersion, .isWhitelisted, .abuseConfidenceScore, .countryCode, .usageType, .isp, .domain, (.hostnames | join(",")), .isTor, .totalReports, .numDistinctUsers, .lastReportedAt] | @csv' >> $output_file
done < "$input_file"
