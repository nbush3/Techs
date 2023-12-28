# User input is seperated into pairs of 'stops' - origin and destination.

# Origin is first checked for in hardcoded dictionaries, then destination. Literal name input is checked for in mileage_dict. Aliases are checked for in alias_dict. If user input is not found in either, then the program breaks immmediately and tells the user where the lookup error was.

# If lookup is successful for both origin and destination, trip mileage is calculated by looking up the destination index number in the origin's mileage dictionary - treating origin as the row in the mileage table and destination as the column.

# After looping through all stop pairs, total is presented and user is asked to start the process again.





from tabulate import tabulate                           # For detail printout
from colorama import Fore, just_fix_windows_console     # For green 'total trip' printout, for readability





building_dict = [
    
    {'Name' :                   "Caring Steps", 
     'Aliases' :                ["CSCC", "30"], 
     'Mileage Values':          "0 2 6 8 4 7 7 2 5 5 8 6 4 7 4 9 6 7 7 6 4 5 7 8 6 7 6".split(' ')},
    
    {'Name' :                   "Baldwin", 
     'Aliases' :                ["12"], 
     'Mileage Values':          "2 0 5 8 2 7 7 3 5 6 7 4 4 7 4 9 4 6 5 5 4 5 7 8 5 7 5".split(' ')},

    {'Name' :                   "Brewster", 
     'Aliases' :                ["20"], 
     'Mileage Values':          "6 4 0 8 3 6 7 6 2 4 3 2 4 3 4 9 1 3 2 3 5 4 7 6 4 7 4".split(' ')},

    {'Name' :                   "Brooklands", 
     'Aliases' :                ["11"], 
     'Mileage Values':          "8 8 8 0 10 2 2 8 6 4 6 9 5 5 6 1 8 5 8 5 6 4 4 4 4 2 5".split(' ')},

    {'Name' :                   "Delta Kelly", 
     'Aliases' :                ["DK", "24"], 
     'Mileage Values':          "4 2 3 10 0 9 9 5 6 7 6 3 6 7 6 11 3 6 4 6 6 7 9 8 7 9 7".split(' ')},

    {'Name' :                   "Hamlin", 
     'Aliases' :                ["13"], 
     'Mileage Values':          "7 7 6 2 9 0 1 6 4 3 4 8 3 3 5 3 6 4 6 3 5 3 4 2 3 2 3".split(' ')},

    {'Name' :                   "Hampton", 
     'Aliases' :                ["23"], 
     'Mileage Values':          "7 7 7 2 9 1 0 7 5 3 5 8 4 4 5 2 7 4 7 4 5 3 4 3 3 1 4".split(' ')},

    {'Name' :                   "Hugger", 
     'Aliases' :                ["21"], 
     'Mileage Values':          "2 3 6 8 5 6 7 0 5 5 7 6 3 7 2 9 6 6 6 5 2 4 5 8 4 6 5".split(' ')},
    
    {'Name' :                   "Long Meadow", 
     'Aliases' :                ["LM", "18"], 
     'Mileage Values':          "5 5 2 6 6 4 5 5 0 2 2 4 2 2 3 7 3 2 3 1 3 2 5 4 1 4 1".split(' ')},
    
    {'Name' :                   "McGregor", 
     'Aliases' :                ["McG", "15"], 
     'Mileage Values':          "6 6 4 4 7 3 3 5 2 0 3 6 2 3 3 5 4 3 4 1 3 1 4 3 1 3 1".split(' ')},

    {'Name' :                   "Meadow Brook", 
     'Aliases' :                ["MB", "14", "Meadowbrook"],
     'Mileage Values':          "8 7 3 6 6 4 5 7 3 3 0 4 4 2 5 7 3 1 3 3 5 3 6 3 3 4 3".split(' ')},

    {'Name' :                   "Musson", 
     'Aliases' :                ["22"],
     'Mileage Values':          "6 4 2 9 3 8 8 6 4 6 4 0 5 5 5 10 2 4 2 5 5 5 8 6 5 8 5".split(' ')},

    {'Name' :                   "North Hill", 
     'Aliases' :                ["NH", "N Hill", "N. Hill", "16"],
     'Mileage Values':          "4 4 4 5 6 4 4 3 2 3 5 5 0 4 1 6 4 4 4 3 1 2 3 5 2 4 3".split(' ')},

    {'Name' :                   "University Hills", 
     'Aliases' :                ["UH", "U Hills", "19"],
     'Mileage Values':          "8 7 3 5 7 3 4 7 2 2 2 5 4 0 5 6 4 1 3 2 5 3 5 3 3 4 2".split(' ')},

    {'Name' :                   "Hart", 
     'Aliases' :                ["HMS", "Hart MS", "Hard Middle", "44"],
     'Mileage Values':          "4 4 4 6 6 4 5 2 3 3 5 5 1 5 0 7 4 4 4 3 1 2 3 6 3 4 3".split(' ')},

    {'Name' :                   "Reuther", 
     'Aliases' :                ["RMS", "Reuther MS", "Reuther Middle", "43"],
     'Mileage Values':          "9 9 9 1 11 3 2 9 7 5 7 10 6 6 7 0 9 7 9 6 7 5 4 5 5 2 6".split(' ')},
    
    {'Name' :                   "Van Hoosen", 
     'Aliases' :                ["VH", "VHMS", "VH MS", "Van Hoosen Middle", "Van Hoosen MS", "42"],
     'Mileage Values':          "6 4 1 8 3 6 7 7 3 4 3 2 4 4 5 9 0 3 1 4 5 4 7 5 4 7 4".split(' ')},
    
    {'Name' :                   "West", 
     'Aliases' :                ["WMS", "West Middle", "West MS", "41"],
     'Mileage Values':          "7 6 3 5 6 4 4 6 2 2 1 4 3 1 5 7 3 0 3 2 5 2 5 3 2 4 2".split(' ')},

    {'Name' :                   "AHS", 
     'Aliases' :                ["Adams", "Adams High", "Adams HS", "Rochester Adams", "51"],
     'Mileage Values':          "7 5 2 8 4 6 7 6 3 4 3 2 4 3 4 9 1 3 0 3 4 4 7 5 4 7 4".split(' ')},
    
    {'Name' :                   "RHS", 
     'Aliases' :                ["Rochester", "Rochester HS", "Rochester High", "50"],
     'Mileage Values':          "6 5 3 5 7 3 4 5 1 1 3 5 2 2 3 6 4 2 3 0 3 1 4 3 1 4 1".split(' ')},
    
    {'Name' :                   "SCHS", 
     'Aliases' :                ["Stoney", "Stoney Creek", "Stoney Creek High", "Stoney Creek HS", "52"],
     'Mileage Values':          "4 4 5 6 6 5 5 2 3 3 5 6 2 5 1 7 5 5 4 3 0 2 4 6 3 5 4".split(' ')},
    
    {'Name' :                   "Administration (Old)", 
     'Aliases' :                ["UNI", "501", "75", "Old Admin"],
     'Mileage Values':          "5 5 4 4 7 3 3 4 2 1 3 5 1 3 2 5 4 2 4 1 2 0 3 4 1 3 1".split(' ')},

    {'Name' :                   "Dequindre Building", 
     'Aliases' :                ["Dequindre", "DQ", "Admin", "79"],
     'Mileage Values':          "7 7 7 4 9 4 4 5 5 4 6 8 3 5 3 4 7 5 7 4 3 3 0 5 3 2 4".split(' ')},
    
    {'Name' :                   "FOC", 
     'Aliases' :                ["77", "Facilities", "Facility Operations Center"],
     'Mileage Values':          "8 8 6 4 8 2 3 8 4 3 3 6 5 3 6 5 5 3 5 3 6 4 6 0 3 4 3".split(' ')},
    
    {'Name' :                   "St. John", 
     'Aliases' :                ["Saint John", "St John", "92"],
     'Mileage Values':          "5 5 4 4 7 3 3 4 1 1 3 5 2 2 3 5 4 2 4 1 3 1 3 3 0 3 1".split(' ')},
    
    {'Name' :                   "Schultz Campus", 
     'Aliases' :                ["Schultz", "ACE", "RACE", "ATPS", "10", "31", "32", "33"],
     'Mileage Values':          "7 7 7 2 9 2 1 6 4 3 4 8 4 4 5 2 7 4 7 4 5 3 2 3 3 0 3".split(' ')},
    
    {'Name' :                   "Transportation", 
     'Aliases' :                ["Transpo", "TS", "76"],
     'Mileage Values':          "6 6 4 5 7 3 4 6 2 1 3 6 3 1 4 6 4 2 4 1 4 2 4 3 1 3 0".split(' ')},
]


global_flag = True
loop_flag = True
detail_flag = False

# Required to make ANSI escapes work in older Windows terminals and auto_py_to_exe console windows (see https://pypi.org/project/colorama/ under Usage)
just_fix_windows_console()


while global_flag:
    
    detail_query = input("\nEnable detail mode? (y/n): ")
    if detail_query.lower().strip() == 'y':
        detail_flag = True
        print("Detail mode enabled.")
    else:
        print("Detail mode disabled.")

    while loop_flag:
        # Initializing values at beginning of each input loop
        
        place_counter = 0
        trip_total = 0
        
        trip_list = []
        trip_table = [['Origin', 'Destination', 'Miles']]
        
        query_flag = True
        noinput_flag = False
        error_flag = False

   
        # Trip input
        
        trip_input = input("\nEnter your day's trip, seperated by dashes, like so:      DQ - McGregor - FOC - UH - DQ\nEnter here: ")

        # Input check - initial - good
        if trip_input.strip():
            
            trip_delim = trip_input.split('-')
            
            length = len(trip_delim) - 1

            if length > 0:

                # For each 'trip' (origin to destination)
                while place_counter < length:

                    from_flag = False
                    to_flag = False
                    destination = ""


                    origin_input = trip_delim[place_counter].strip()
                    destination_input = trip_delim[place_counter + 1].strip()

                    # Check for origin name in mileage dictionary (full names as written on Mileage Chart)
                    for entry in building_dict:
                        for k1, v1 in entry.items():
                            # Attempt name lookup by building name
                            if k1 == 'Name':
                                origin_thru = v1
                                if origin_input.lower().strip() == v1.lower().strip():
                                    from_flag = True
                                    origin = origin_thru
                            # Attempt name lookup by alias
                            if k1 == 'Aliases':
                                for alias in v1:
                                    if origin_input.lower().strip() == alias.lower().strip():
                                        from_flag = True
                                        origin = origin_thru
                    

                    # Exception handling - if origin is not found
                    if not from_flag:
                        loop_flag = False
                        error_flag = True
                        print(f"\nERROR: Naming error found here: \"***{origin_input}*** - {destination_input}\". Try again.")

                    # Break loop if origin is not found
                    if not loop_flag:
                        break
                    
                    # If origin is found, continue with destination processing
                    else:
                        # Check for destination name in mileage dictionary
                        for entry in building_dict:
                            entry_flag = False
                            for k1, v1 in entry.items():
                                # Attempt name lookup by building name
                                if k1 == 'Name':
                                    destination_thru = v1
                                    if destination_input.lower().strip() == v1.lower().strip():
                                        to_flag = True
                                        entry_flag = True
                                        destination = v1
                                # Attempt name lookup by alias
                                if not to_flag:
                                    if k1 == 'Aliases':
                                        for alias in v1:
                                            if destination_input.lower().strip() == alias.lower().strip():
                                                to_flag = True
                                                destination = destination_thru
                                                entry_flag = True
                                
                                if entry_flag:
                                    destination_index = building_dict.index(entry)
                             
                    # Exception handling - if destination is not found
                    if not to_flag:
                        loop_flag = False
                        error_flag = True
                        print(f"\nERROR: Naming error found here: {origin_input} - ***{destination_input}***. Try again.")
                        break
                    
                    
                    
                    else:    
                        # Mileage lookup
                    
                        for entry in building_dict:

                            from_flag = False
                            to_flag = False

                            # Locate the origin's dict (the row)
                            if entry["Name"].lower().strip() == origin.lower().strip():
                                from_flag = True

                            # Locate the destination's mileage value (the column)
                            if from_flag:
                                trip_list.append(entry["Mileage Values"][destination_index])
                                
                                if detail_flag:
                                    trip_table.append([origin, destination, entry["Mileage Values"][destination_index]])
                                    
                    place_counter += 1
                
                # After all trips are gathered - aggregate all trip miles into total
                if loop_flag:
                    for trip in trip_list:
                        trip_total += int(trip)
                    # trip_table.append(['', '', ''])
                    trip_table.append(['', (Fore.LIGHTGREEN_EX + "Trip total"), (Fore.LIGHTGREEN_EX + str(trip_total))])


                # User printout
                if not error_flag:
                    
                    # Detail table printout
                    if detail_flag:
                        print('')
                        print(tabulate(trip_table,headers='firstrow'))
                    
                    # Non-detail printout
                    else:
                        print(f"\nTrip stops: {trip_input}")
                        print(f"Trip miles: {trip_list}")
                        print(Fore.LIGHTGREEN_EX + f"Trip total: {trip_total}")

                    
                    print(Fore.WHITE + f"\nVERY IMPORTANT: Double check the miles for each trip against the Mileage chart! Don't trust this 100%!")
        
            # Trip length insufficient
            else:
                print("\nOnly one stop detected. Try again.")


        # Input check - initial - bad
        else:
            noinput_flag = True
            print("\nNo input detected. Try again.")

        

        # Query for additional entries
        # loop_query = input("\nEnter another trip? (y/n): ")
        # 
        # while query_flag:
        #     if loop_query.lower().strip() == 'y':
        #         query_flag = False
        #         loop_flag = True
        #     elif loop_query.lower().strip() == 'n':
        #         query_flag = False
        #         loop_flag = False
        #         global_flag = False
        #     else:
        #         loop_query = input("Improper input. Try again: ")