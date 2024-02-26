# This script requires the pandas module for Python. If you don't have it, open PowerShell as admin and run:
# python -m pip install pandas
import pandas as pd

# This script will do two things:
#   - Merge Windstream Master sheet with Changes Since... sheet
#   - Using Mitel CESID sheet as a template, create a new Mitel CESID sheet with updated CESID and CESID Comments fields


# You must do several things to prepare this script:
#   1. Export Mitel CESID Assignment sheet from .6
#   2. Download Windstream CESID sheet from Google Drive as CSVs (both the Master sheet and the "Changes Since 2023-12-06")
#   3. Put all 3 CSV files in the same folder as the script


# To run the script:
#   - Install Python: https://www.python.org/downloads/release/python-3122/
#   - Run script in regular (non-admin) Powershell: python S:\Techs\script\CESID\Convert-CESID.py


# Before (CESID_vMCD_202402121533.csv):
#       0,3001,"Save,Greet and Releas",-,-,,,Manual,Through System Only,
#       0,3003,"Technology,Tech Room",-,-,,,Manual,Through System Only,
#       0,3004,"Technology,Workroom",-,-,,,Manual,Through System Only,
#       0,3007,"Tech,Workroom",-,-,,,Manual,Through System Only,
#       0,3008,"Admin,ISTeam",-,-,,,Manual,Through System Only,
#       0,3010,"Admin,Harrison Room",-,-,,,Manual,Through System Only,
#
# After (Mitel Output.csv):
#       0,3001,"Save,Greet and Releas",-,-,2487263001,Greet and ,Manual,Through System Only
#       0,3003,"Technology,Tech Room",-,-,2487263003,Tech Room ,Manual,Through System Only
#       0,3004,"Technology,Workroom",-,-,2487263004,Workroom T,Manual,Through System Only
#       0,3007,"Tech,Workroom",-,-,2487263007,Workroom T,Manual,Through System Only
#       0,3008,"Admin,ISTeam",-,-,2487263008,ISTeam Adm,Manual,Through System Only
#       0,3010,"Admin,Harrison Room",-,-,2487263010,Harrison R,Manual,Through System Only


filepath = "S:/Techs/script/CESID"
mitel_file = f"{filepath}/CESID_vMCD_202402140810.csv"
windstream_master_file = f"{filepath}/Windstream CESID - Master.csv"
windstream_update_file = f"{filepath}/Windstream CESID - Changes Since 2023-12-06.csv"
output_file = f"{filepath}/Mitel Output.csv"


# Create panda dataframes for Mitel and Windstream CSVs
mitel_df = pd.read_csv(mitel_file, skiprows=[0,1])
windstream_df = pd.read_csv(windstream_master_file)
windstream_update_df = pd.read_csv(windstream_update_file)


# Update Windstream df by merging Master with Changes Since...
for update_index,update_row in windstream_update_df.iterrows():
    update_tendigit = update_row['Telephone Number']
    # Lookup row from master Windstream df based on 10digit
    master_row = windstream_df.loc[windstream_df['Telephone Number'] == update_tendigit]
    master_index = windstream_df.index[windstream_df['Telephone Number'] == update_tendigit][0]
    # Merge changes
    windstream_df.loc[master_index] = windstream_update_df.loc[update_index].copy()
    


# Remove commas from existing names (proof of concept)
# for row,index in mitel_df.iterrows():
#     name_unparsed = mitel_df.loc[index]['Name']
#     name_list = name_unparsed.split(',')
#     name_parsed = name_list[1] + ' ' + name_list[0]
#     mitel_df['Name'].at[index] = name_parsed



# Create Mitel CESID sheet
for mitel_index,mitel_row in mitel_df.iterrows():
    badcharflag=False
    output_comment = ""
    charcount = 1
    
    # Retrieve 4digit from Mitel df
    fourdigit = mitel_row['Number']

    # Filter out softphones (extensions have * (ex: 6*014))
    for char in fourdigit:
        if char == "*":
            badcharflag=True

    # Filter out softphones and numbers greater than 6999 (for purposes of mapping CESIDs to internal extensions and comments)    
    if not badcharflag:
        if int(fourdigit) <= 6999:

            # Calculate 10digit based on 4digit
            tendigit = int(f"248726{fourdigit}")

            # Lookup row from Windstream df based on 10digit
            windstream_row = windstream_df.loc[windstream_df['Telephone Number'] == tendigit]

            # Filter entries with no data in Windstream df - will throw errors otherwise
            if len(windstream_row) > 0:
                
                # Capture comment from Windstream df
                windstream_index = windstream_df.index[windstream_df['Telephone Number'] == tendigit][0]
                windstream_comment = windstream_row['Comments (Internal Only)'][windstream_index]

                # Ignore "--" comments in Windstream df - supposed to represent out of service numbers
                if windstream_comment == "--":
                    output_comment = ""
                else:
                    # Only capture the first 10 characters of the comment - Mitel's CESID sheet only supports 10 characters 
                    for char in windstream_comment:
                        if charcount <= 10:
                            output_comment += char
                        charcount += 1
                
                # Write new CESID and CESID Comments to Mitel df
                mitel_df['CESID Comments'].at[mitel_index] = output_comment
                mitel_df['CESID'].at[mitel_index] = str(tendigit)
            else:
                comment=""
                mitel_df['CESID Comments'].at[mitel_index] = output_comment
                mitel_df['CESID'].at[mitel_index] = str(tendigit)


    else:
        tendigit=""
        comment=""

# Drop extra "Unnamed" column from ouput df
mitel_df.drop(mitel_df.columns[mitel_df.columns.str.contains('unnamed',case=False)],axis=1,inplace=True)

# Create output csv
mitel_df.to_csv(output_file, index=False)