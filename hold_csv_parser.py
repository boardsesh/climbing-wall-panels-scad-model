#!/usr/bin/env python3
"""
Excel to OpenSCAD Angle Data Converter for Kilter Homewall

This script reads the hold angle data and hold numbers from the CSV files and generates the
corresponding OpenSCAD code to define the hold data for the Kilter homewall model.

Usage:
    python csv_to_openscad.py <mainline_csv> <aux_csv> <output_file>

Example:
    python csv_to_openscad.py "10x12 Hold Map.xlsx  Main Line Grid.csv" "10x12 Hold Map.xlsx  Aux Grid.csv" "kilter_angles.scad"
"""

import sys
import csv
import re


def parse_csv_files(mainline_path, aux_path):
    """
    Parse the CSV files containing hold angle information and hold numbers.
    
    Args:
        mainline_path: Path to the Main Line Grid CSV
        aux_path: Path to the Aux Grid CSV
        
    Returns:
        Dictionary with hold data indexed by [column][row]
    """
    hold_data = {}

    # Process horizontal (mainline) holds
    print(f"Processing Mainline (horizontal) holds from: {mainline_path}")
    with open(mainline_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        rows = list(reader)

        row_id = None
        in_kickboard_section = False
        
        for i in range(len(rows)):
            row = rows[i]

            # Skip empty rows
            if not row or len(row) < 14:
                continue

            grid_type = row[0].strip() if row[0] else ""
            
            # Check if we're in the kickboard section
            if grid_type == "Kickboard Below":
                in_kickboard_section = True
            
            # Get row ID from the ROW column
            if len(row) > 14 and row[14] and row[14].strip().startswith("R-"):
                row_id = row[14].strip()
            elif len(row) > 14 and row[14] and row[14].strip().startswith("K-"):
                row_id = row[14].strip().replace("K-", "K")  # Convert K-1 to K1

            # If this is a "Hold #" row, get hold numbers and the next row should have angle info
            if grid_type == "Hold #" and row_id and i + 1 < len(rows) and len(rows[i+1]) > 0:
                hold_number_row = row  # Store hold numbers
                angle_row = rows[i+1]

                if angle_row[0].strip() == "Angle":
                    # Process even columns (C-2, C-4, etc.)
                    for j in range(1, 14):  # Columns C-2 through C-26
                        if j < len(angle_row) and angle_row[j].strip():
                            angle_text = angle_row[j].strip()
                            hold_number = hold_number_row[j].strip() if j < len(hold_number_row) else ""

                            # Extract numeric angle from format like "180˚"
                            angle_match = re.search(r'(\d+)', angle_text)
                            if angle_match:
                                angle = int(angle_match.group(1))
                            else:
                                continue  # Skip if no angle found

                            # Determine column number
                            col_name = ""
                            for k in range(i-1, max(0, i-5), -1):
                                if k < len(rows) and j < len(rows[k]) and rows[k][j]:
                                    col_match = re.search(r'C-(\d+)', rows[k][j].strip())
                                    if col_match:
                                        col_name = rows[k][j].strip()
                                        break

                            col_match = re.search(r'C-(\d+)', col_name) if col_name else None
                            if not col_match and j <= 13:
                                # Use position to determine column (for even columns)
                                col_num = 2 + (j-1) * 2
                            else:
                                col_num = int(col_match.group(1)) if col_match else None

                            if col_num:
                                # Extract row number from row_id
                                if row_id.startswith("K"):
                                    row_num = row_id  # Keep K1 as is
                                else:
                                    row_num = row_id.split('-')[1]

                                if col_num not in hold_data:
                                    hold_data[col_num] = {}

                                hold_data[col_num][row_num] = {
                                    "angles": [angle, 0],
                                    "hold_number": hold_number if hold_number else f"C{col_num}_R{row_num}"
                                }
            
            # Special handling for kickboard section
            elif in_kickboard_section and grid_type == "Hold #" and i + 1 < len(rows) and len(rows[i+1]) > 0:
                hold_number_row = row  # Store hold numbers
                angle_row = rows[i+1]
                
                if angle_row[0].strip() == "Angle":
                    # Get the row ID for kickboard (K-1)
                    for k in range(i, i+3):
                        if k < len(rows) and len(rows[k]) > 14 and rows[k][14] and rows[k][14].strip().startswith("K-"):
                            row_id = rows[k][14].strip().replace("K-", "K")
                            break
                    
                    if row_id and row_id.startswith("K"):
                        # Process even columns (C-2, C-4, etc.)
                        for j in range(1, 14):  # Columns C-2 through C-26
                            if j < len(angle_row) and j < len(hold_number_row):
                                angle_text = angle_row[j].strip()
                                hold_number = hold_number_row[j].strip()
                                
                                # Extract numeric angle from format like "180˚"
                                angle_match = re.search(r'(\d+)', angle_text)
                                if angle_match:
                                    angle = int(angle_match.group(1))
                                else:
                                    continue  # Skip if no angle found
                                
                                # Determine column number (for even columns)
                                col_num = 2 + (j-1) * 2
                                
                                if col_num not in hold_data:
                                    hold_data[col_num] = {}
                                
                                hold_data[col_num][row_id] = {
                                    "angles": [angle, 0],
                                    "hold_number": hold_number if hold_number else row_id
                                }

    # Process vertical (auxiliary) holds
    print(f"Processing Auxiliary (vertical) holds from: {aux_path}")
    with open(aux_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        rows = list(reader)

        row_id = None
        in_kickboard_section = False
        
        for i in range(len(rows)):
            row = rows[i]

            # Skip empty rows
            if not row or len(row) < 15:
                continue

            grid_type = row[0].strip() if row[0] else ""
            
            # Check if we're in the kickboard section
            if grid_type == "Kickboard Below":
                in_kickboard_section = True
            
            # Get row ID from the ROW column
            if len(row) > 15 and row[15] and row[15].strip().startswith("R-"):
                row_id = row[15].strip()
            elif len(row) > 15 and row[15] and row[15].strip().startswith("K-"):
                row_id = row[15].strip().replace("K-", "K")  # Convert K-2 to K2

            # If this is a "Hold #" row, get hold numbers and the next row should have angle info
            if grid_type == "Hold #" and row_id and i + 1 < len(rows) and len(rows[i+1]) > 0:
                hold_number_row = row  # Store hold numbers
                angle_row = rows[i+1]

                if angle_row[0].strip() == "Angle":
                    # Process odd columns (C-1, C-3, etc.)
                    for j in range(1, 15):  # Columns C-1 through C-27
                        if j < len(angle_row) and angle_row[j].strip():
                            angle_text = angle_row[j].strip()
                            hold_number = hold_number_row[j].strip() if j < len(hold_number_row) else ""

                            # Extract numeric angle from format like "180˚"
                            angle_match = re.search(r'(\d+)', angle_text)
                            if angle_match:
                                angle = int(angle_match.group(1))
                            else:
                                continue  # Skip if no angle found

                            # Determine column number
                            col_name = ""
                            for k in range(i-1, max(0, i-5), -1):
                                if k < len(rows) and j < len(rows[k]) and rows[k][j]:
                                    col_match = re.search(r'C-(\d+)', rows[k][j].strip())
                                    if col_match:
                                        col_name = rows[k][j].strip()
                                        break

                            col_match = re.search(r'C-(\d+)', col_name) if col_name else None
                            if not col_match and j <= 14:
                                # Use position to determine column (for odd columns)
                                col_num = 1 + (j-1) * 2
                            else:
                                col_num = int(col_match.group(1)) if col_match else None

                            if col_num:
                                # Extract row number from row_id
                                if row_id.startswith("K"):
                                    row_num = row_id  # Keep K2 as is
                                else:
                                    row_num = row_id.split('-')[1]

                                if col_num not in hold_data:
                                    hold_data[col_num] = {}

                                # For vertical angles, use [0, angle] format
                                if row_num in hold_data[col_num]:
                                    hold_data[col_num][row_num]["angles"][1] = angle
                                else:
                                    hold_data[col_num][row_num] = {
                                        "angles": [0, angle],
                                        "hold_number": hold_number if hold_number else f"C{col_num}_R{row_num}"
                                    }
            
            # Special handling for kickboard section
            elif in_kickboard_section and grid_type == "Hold #" and i + 1 < len(rows) and len(rows[i+1]) > 0:
                hold_number_row = row  # Store hold numbers
                angle_row = rows[i+1]
                
                if angle_row[0].strip() == "Angle":
                    # Get the row ID for kickboard (K-2)
                    for k in range(i, i+3):
                        if k < len(rows) and len(rows[k]) > 15 and rows[k][15] and rows[k][15].strip().startswith("K-"):
                            row_id = rows[k][15].strip().replace("K-", "K")
                            break
                    
                    if row_id and row_id.startswith("K"):
                        # Process odd columns (C-1, C-3, etc.)
                        for j in range(1, 15):  # Columns C-1 through C-27
                            if j < len(angle_row) and j < len(hold_number_row):
                                angle_text = angle_row[j].strip()
                                hold_number = hold_number_row[j].strip()
                                
                                # Extract numeric angle from format like "180˚"
                                angle_match = re.search(r'(\d+)', angle_text)
                                if angle_match:
                                    angle = int(angle_match.group(1))
                                else:
                                    continue  # Skip if no angle found
                                
                                # Determine column number (for odd columns)
                                col_num = 1 + (j-1) * 2
                                
                                if col_num not in hold_data:
                                    hold_data[col_num] = {}
                                
                                if row_id in hold_data[col_num]:
                                    hold_data[col_num][row_id]["angles"][1] = angle
                                else:
                                    hold_data[col_num][row_id] = {
                                        "angles": [0, angle],
                                        "hold_number": hold_number if hold_number else row_id
                                    }

    # Add kicker rows with default angles if they're missing
    # K1 - Horizontal holds (even columns)
    for col in range(2, 28, 2):
        if col not in hold_data:
            hold_data[col] = {}
        if "K1" not in hold_data[col]:
            # Default to 180 degrees for horizontal kicker holds
            hold_data[col]["K1"] = {
                "angles": [180, 0],
                "hold_number": "K1"
            }

    # K2 - Vertical holds (odd columns)
    for col in range(1, 28, 2):
        if col not in hold_data:
            hold_data[col] = {}
        if "K2" not in hold_data[col]:
            # Default to 90 degrees for vertical kicker holds
            hold_data[col]["K2"] = {
                "angles": [0, 90],
                "hold_number": "K2"
            }

    return hold_data


def row_sort_key(row):
    """
    Custom sort key function to handle mixed string/numeric row IDs.
    """
    if row in ["K1", "K2"]:
        # Sort K1 and K2 after numbered rows
        return (2, row)
    else:
        # For numbered rows, convert to integer for proper numeric sorting
        try:
            return (1, int(row))
        except ValueError:
            # Fallback for any other row format
            return (3, row)


def generate_openscad_code(hold_data):
    """
    Generate OpenSCAD code for hold angle and hold number definitions using static arrays.
    
    Args:
        hold_data: Dictionary with hold data indexed by [column][row]
        
    Returns:
        String with OpenSCAD code for hold data
    """
    code = "// Hold angle data for Kilter Homewall\n"
    code += "// Generated from CSV data\n\n"

    # Create angle_data array
    code += "// Static array with hold angles\n"
    code += "// Format: [angle_h, angle_v] for each position\n"
    code += "angle_data = [\n"

    # Add angle data for all columns and rows using custom sort key
    for col in sorted(hold_data.keys()):
        for row in sorted(hold_data[col].keys(), key=row_sort_key):
            angle_h, angle_v = hold_data[col][row]["angles"]
            code += f'    ["{col}_{row}", [{angle_h}, {angle_v}]],\n'

    code += "];\n\n"

    # Create hold_number array
    code += "// Static array with hold numbers\n"
    code += "// Format: hold_number for each position\n"
    code += "hold_numbers = [\n"

    # Add hold numbers for all columns and rows using custom sort key
    for col in sorted(hold_data.keys()):
        for row in sorted(hold_data[col].keys(), key=row_sort_key):
            hold_number = hold_data[col][row]["hold_number"]
            code += f'    ["{col}_{row}", "{hold_number}"],\n'

    code += "];\n\n"

    # Add helper functions
    code += "// Helper function to check if a value is a number\n"
    code += "function is_num(val) = \n"
    code += "    is_undef(val) ? false : \n"
    code += "    is_string(val) ? false : \n"
    code += "    is_list(val) ? false : \n"
    code += "    is_bool(val) ? false : \n"
    code += "    true;\n\n"

    code += "// Helper function to check if a row is a kicker row (K1 or K2)\n"
    code += "function is_kicker_row(row) =\n"
    code += "    is_string(row) && (row == \"K1\" || row == \"K2\");\n\n"

    # Add improved get_angle function with better search logic
    code += "// Function to find angle data for a position\n"
    code += "function get_angle(col, row, is_horizontal) = \n"
    code += "    let(\n"
    code += "        // Debug output\n"
    code += "        debug_1 = echo(\"DEBUG - get_angle:\"),\n"
    code += "        debug_2 = echo(\"  col:\", col, \"row:\", row, \"is_horizontal:\", is_horizontal),\n"
    code += "        \n"
    code += "        // Create the key in the format used in the angle_data array\n"
    code += "        key = str(col, \"_\", is_string(row) ? row : str(row)),\n"
    code += "        \n"
    code += "        // Debug output\n"
    code += "        debug_3 = echo(\"  key:\", key),\n"
    code += "        \n"
    code += "        // Find the index in the angle_data array\n"
    code += "        // We need to search for the key in the first element of each entry\n"
    code += "        indices = [for (i = [0:len(angle_data)-1]) \n"
    code += "                  if (angle_data[i][0] == key) i],\n"
    code += "        \n"
    code += "        // Debug output\n"
    code += "        debug_4 = echo(\"  indices:\", indices),\n"
    code += "        \n"
    code += "        // Get the angles or use default based on column parity\n"
    code += "        angles = (len(indices) > 0) ? \n"
    code += "                 // Found in array\n"
    code += "                 angle_data[indices[0]][1] :\n"
    code += "                 // Default based on column parity\n"
    code += "                 (col % 2 == 0) ? [180, 0] : [0, 90],\n"
    code += "                 \n"
    code += "        // Debug output\n"
    code += "        debug_5 = echo(\"  angles:\", angles)\n"
    code += "    )\n"
    code += "    \n"
    code += "    // Return the appropriate angle based on orientation\n"
    code += "    is_horizontal ? angles[0] : angles[1];\n\n"

    # Add improved get_hold_number function with better search logic
    code += "// Function to find hold number for a position\n"
    code += "function get_hold_number(col, row) = \n"
    code += "    let(\n"
    code += "        // Debug output\n"
    code += "        debug_1 = echo(\"DEBUG - get_hold_number:\"),\n"
    code += "        debug_2 = echo(\"  col:\", col, \"row:\", row),\n"
    code += "        \n"
    code += "        // Create the key in the format used in the hold_numbers array\n"
    code += "        key = str(col, \"_\", is_string(row) ? row : str(row)),\n"
    code += "        \n"
    code += "        // Debug output\n"
    code += "        debug_3 = echo(\"  key:\", key),\n"
    code += "        \n"
    code += "        // Find the index in the hold_numbers array\n"
    code += "        // We need to search for the key in the first element of each entry\n"
    code += "        indices = [for (i = [0:len(hold_numbers)-1]) \n"
    code += "                  if (hold_numbers[i][0] == key) i],\n"
    code += "        \n"
    code += "        // Debug output\n"
    code += "        debug_4 = echo(\"  indices:\", indices),\n"
    code += "        \n"
    code += "        // Get the hold number or use default\n"
    code += "        number = (len(indices) > 0) ? \n"
    code += "                 // Found in array\n"
    code += "                 hold_numbers[indices[0]][1] :\n"
    code += "                 // Default\n"
    code += "                 str(\"C\", col, \"_R\", row),\n"
    code += "        \n"
    code += "        // Debug output\n"
    code += "        debug_5 = echo(\"  number:\", number)\n"
    code += "    )\n"
    code += "    number;\n"

    return code


def main():
    """
    Main function to process command line arguments and run the converter.
    """
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <mainline_csv> <aux_csv> <output_file>")
        sys.exit(1)

    mainline_path = sys.argv[1]
    aux_path = sys.argv[2]
    output_path = sys.argv[3]

    try:
        hold_data = parse_csv_files(mainline_path, aux_path)
        openscad_code = generate_openscad_code(hold_data)

        with open(output_path, 'w') as f:
            f.write(openscad_code)

        print(f"Successfully generated OpenSCAD code in {output_path}")
        print(
            f"Found {sum(len(angles) for angles in hold_data.values())} holds")

        # Print some statistics for verification
        horizontal_count = sum(1 for col in hold_data.keys() if col % 2 == 0
                               for row in hold_data[col].keys())
        vertical_count = sum(1 for col in hold_data.keys() if col % 2 == 1
                             for row in hold_data[col].keys())

        print(f"Horizontal holds: {horizontal_count}")
        print(f"Vertical holds: {vertical_count}")

        # Print K1 and K2 statistics for verification
        k1_count = sum(1 for col in hold_data.keys() if col %
                       2 == 0 and "K1" in hold_data[col])
        k2_count = sum(1 for col in hold_data.keys() if col %
                       2 == 1 and "K2" in hold_data[col])

        print(f"K1 (horizontal kicker) holds: {k1_count}")
        print(f"K2 (vertical kicker) holds: {k2_count}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
