#! /usr/bin/python3

import os
import re
import sys

def process_baker_profiling(file_path, threshold_duration):
    rounds = []
    current_round = None

    with open(file_path, 'r') as file:
        lines = file.readlines()

    for line in lines:
        # Check if the line contains round information
        round_match = re.match(r'^([^\s]+)\s+\.{4,} (\d+)\s+([\d.]+)ms', line)
        if round_match:
            if current_round:
                rounds.append(current_round)

            block_name, round_number, round_duration = round_match.groups()
            current_round = {
                'block_name': block_name,
                'round_number': int(round_number),
                'round_duration': float(round_duration),
                'logs': [],
                'quorum_reached': False
            }
        elif current_round:
            # Check if the line contains 'do step with event' for 'quorum reached'
            quorum_match = re.match(r'^\s*do step with event \'quorum reached\'', line)
            if quorum_match:
                current_round['quorum_reached'] = True
            else:
                # Attempt to extract duration using a regular expression
                duration_match = re.match(r'^.*\.\.\.+.+ (\d+\.\d+)ms.*$', line)
                if duration_match:
                    duration = float(duration_match.group(1))
                    if duration >= threshold_duration:
                        current_round['logs'].append(line)
                else:
                    current_round['logs'].append(line)

    if current_round:
        rounds.append(current_round)

    return rounds

def main(folder_path, threshold_duration):
    baker_profiling_files = []
    first_baker_logs = None

    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith('baker_profiling.txt'):
                file_path = os.path.join(root, file)
                baker_profiling_files.append(file_path)

                # Process logs only from the first baker
                if first_baker_logs is None:
                    first_baker_logs = process_baker_profiling(file_path, threshold_duration)

    if not first_baker_logs:
        print("No baker profiling files found.")
        sys.exit(1)

    # Filter out rounds without 'quorum reached'
    first_baker_rounds = [round_info for round_info in first_baker_logs if round_info['quorum_reached']]

    # Sort rounds by duration
    sorted_rounds = sorted(first_baker_rounds, key=lambda x: x['round_duration'])

    # Print top 3 fastest and slowest rounds
    top_fastest = sorted_rounds[:3]
    top_slowest = sorted_rounds[-3:]

    def print_round(round_info):
        print(f"Block: {round_info['block_name']}, Round: {round_info['round_number']}, "
              f"Duration: {round_info['round_duration']}ms")
        print("Logs:")
        for log in round_info['logs']:
            print(log, end='')  # Preserve indentation
        print("\n")

    print("Top 3 Fastest Rounds:")
    for round_info in top_fastest:
        print_round(round_info)

    print("Top 3 Slowest Rounds:")
    for round_info in top_slowest:
        print_round(round_info)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <folder_path> <threshold_duration>")
        print("""
folder_path - path to the folder with profiler logs
threshold_duration - skip the lines with duration below the threshold.

This script takes data about the blocks from a random baker.
Then it filters and prints out:
- top 3 slowest rounds
- top 3 fastest rounds""")
        sys.exit(1)

    folder_path = sys.argv[1]
    threshold_duration = float(sys.argv[2])
    main(folder_path, threshold_duration)
    