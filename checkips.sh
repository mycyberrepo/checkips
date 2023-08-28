#!/bin/bash

# TERMS OF USE
# In these terms, "author" shall be taken to mean the person or legal entity
# that created this work.
# This script is provided as-is with no warranty of any kind. 
# Use at your own risk.
# The author assumes no liability for any damages caused by this script.
# By using this script, you agree not to hold the author liable for any
# damages, legal claims, or legal actions arising from its use or distribution.
# If you use or distribute this script in any way, you agree to assume all
# legal liabilities arising from that use and/or distribution and defend
# and indemnify the author against any damages or costs arising from claims
# or legal actions related to the use and/or distribution of this script.
# By using this script, you also agree to abide by the abuseipdb.com
# terms of service. At time of writing, those terms are located at
# https://www.abuseipdb.com/legal. This URL is provided as a convince.
# If the URL of the terms of service applicable to abuseipdb.com changes
# or if any terms of the site change, it is up the user (or distributor)
# and not the author to find the new terms and ensure compliance with 
# the terms.
# The author retains the right to change the terms of service for this script
# without notice.
# You agree any disputes arising from this agreement will be governed
# by the laws of the Commonwealth of Virginia in the United States without
# regard to conflict of law.
# You further agree not to use this script to commit acts that are unlawful,
# violate abusedbip.com's terms of service, or may result in someone wanting
# to sue the author.
# If you cannot legally agree to these terms in full for any reason, such
# as, but not limited to, being below the age of 18, you are not permitted 
# to use or distribute this script.
# If any clauses in the abuseipdb.com's terms of service conflict with
# the terms of service of this script such that that conflict would
# open the author of this script to liability of any kind, then this agreement
# supersedes those clauses of abuseipdb's terms of service that create such
# conflict.
# This file constitutes the entire agreement.

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
