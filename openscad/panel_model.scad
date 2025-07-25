// Kilter Homewall 10x12 OpenSCAD Model with Hold Angle Data
// This model includes proper hole placement and hold angle annotations
// Optimized for CNC machining with 2D projections
// Note: Using oversized Birch Ply panels (1525x3050mm) to ensure all LED holes fit properly
//
// PANEL LAYOUT:
// - Panel 1: Bottom section (rows that fall within 0-1525mm from bottom)
// - Panel 2: Middle section (rows that fall within 1525-3050mm from bottom)
// - Panel 3: Top section (rows that fall within 3050-4575mm from bottom)
// Rows are automatically assigned to panels based on their vertical position

// Constants for measurements in mm
mm_per_cm = 10;
mm_per_inch = 25.4;

// Full climbing wall dimensions
full_width = 3600;                    // Expanded width (3600mm)
full_height = 12 * 12 * mm_per_inch;  // 12ft in mm (3657.6mm)

// Panel dimensions (mounted sideways/landscape)
panel_width = 2440;      // Width when mounted sideways (2440mm)
panel_height = 1220;     // Height when mounted sideways (1220mm)
half_panel_width = 1220; // Half sheet width for alternating layout
kicker_height = 10 * mm_per_inch;     // 10in in mm
panel_thickness = 18;                 // Typical plywood thickness (18mm)

// Hole sizes
t_nut_hole_diameter = 7/16 * mm_per_inch; // 7/16" in mm
led_hole_diameter = 1/2 * mm_per_inch;    // 1/2" in mm
text_depth = 1;                          // Depth of engraved text
text_size = 6;                           // Size for engraved text

// Angle indicator settings - CUSTOMIZABLE
angle_indicator_length = 30;             // Length in mm (3cm)
angle_indicator_width = 1.5;             // Width in mm (line thickness)

// Column spacings as per the guide
// Columns are 10cm apart, centered layout for 31 columns
col_edge_margin = 25 * mm_per_cm;        // 25cm from left edge to C1 (centered)
col_spacing = 10 * mm_per_cm;            // 10cm between columns
col_count = 31;                          // Total columns (2 extra left, 2 extra right)

// Row spacings and margins
row_spacing = 10 * mm_per_cm;            // 10cm between rows
bottom_margin = 10 * mm_per_cm;          // 10cm from bottom edge to R1

// LED hole spacing
horizontal_led_spacing = 2.5 * mm_per_cm; // 2.5cm between t-nut and LED for horizontal patterns
vertical_led_spacing = 2.0 * mm_per_cm;   // 2.0cm between t-nut and LED for vertical patterns

// Debug output for constants
echo("Column edge margin:", col_edge_margin / mm_per_cm, "cm");
echo("Column spacing:", col_spacing / mm_per_cm, "cm");
echo("Row spacing:", row_spacing / mm_per_cm, "cm");
echo("Bottom margin:", bottom_margin / mm_per_cm, "cm");

// Include the generated angles file with hold data
include <kilter_angles.scad>

// Helper function to get hold ID from column and row numbers
function get_hold_id(col, row_num) =
    // Convert row number to actual row ID
    // Rows 1-35 and Kicker rows K1, K2
    (row_num == "K1" || row_num == "K2") ? row_num : str(row_num);

// Function to calculate column position (from left edge)
function col_pos(col_num) = 
    let(
        position = col_edge_margin + (col_num - 1) * col_spacing,
        debug = echo("Column", col_num, "position:", position / mm_per_cm, "cm from left edge")
    )
    position;

// Function to calculate row position (from bottom edge)
function row_pos(row_num) =
    let(
        // For rows 1-35, calculate position from bottom
        // Ignore kicker rows for now
        position = (is_string(row_num)) ? 0 :  // Ignore K1 and K2 for now
                   bottom_margin + (row_num - 1) * row_spacing,
        debug = echo("Row", row_num, "position:", position / mm_per_cm, "cm from bottom edge")
    )
    position;

// 2D hole patterns
module t_nut_hole_2d() {
    circle(d=t_nut_hole_diameter);
}

module led_hole_2d() {
    circle(d=led_hole_diameter);
}

// 2D angle indicator
module angle_indicator_2d() {
    // Simple line starting from the origin (t-nut hole center)
    // Default orientation is along the X-axis (to the right)
    translate([0, -angle_indicator_width/2])
    square([angle_indicator_length, angle_indicator_width]);
}

// Function to convert angle data to proper rotation
// In our data: 0° = up, 90° = right, 180° = down, 270° = left
// In OpenSCAD: 0° = right, 90° = up, 180° = left, 270° = down
function convert_angle(angle) =
    // We need to map the angles correctly:
    // 0° (up) → 90° in OpenSCAD
    // 90° (right) → 0° in OpenSCAD
    // 180° (down) → 270° in OpenSCAD
    // 270° (left) → 180° in OpenSCAD
    
    // If angle is undefined, use a default of 0 degrees
    is_undef(angle) ? 0 : 
    // Otherwise, convert the angle
    (90 - angle) % 360;

// 2D text engraving
module engrave_text_2d(text_str, y_offset=0) {
    translate([0, y_offset])
    text(text_str, size=text_size, halign="center", valign="center");
}

// 2D hold ID engraving
module engrave_hold_id_2d(col, row, is_horizontal) {
    // Debug output
    echo("DEBUG - engrave_hold_id_2d:");
    echo("  col:", col, "row:", row, "is_horizontal:", is_horizontal);
    
    // Get angle and hold number
    angle = get_angle(col, row, is_horizontal);
    hold_number = get_hold_number(col, row);
    
    // Debug output
    echo("  angle:", angle, "hold_number:", hold_number);
    
    // For display purposes, we can use get_hold_id
    row_id = get_hold_id(col, row);
    
    // Combine all text operations
    // Display the position (column and row)
    text(str("C", col, " R", row_id), size=text_size, halign="center", valign="center");
    
    // Display the hold number (or a default if undefined)
    translate([0, -text_size - 2])
    text(str(hold_number), size=text_size, halign="center", valign="center");
    
    // Display the angle (or a default if undefined)
    translate([0, -2 * text_size - 4])
    text(str(angle, "°"), size=text_size, halign="center", valign="center");
}

// 2D horizontal bolt pattern
module horizontal_bolt_pattern_2d(col, row) {
    x = col_pos(col);
    y = row_pos(row);
    
    translate([x, y]) {
        // T-nut hole
        t_nut_hole_2d();
        
        // LED holes
        translate([-horizontal_led_spacing, 0]) led_hole_2d();
        translate([horizontal_led_spacing, 0]) led_hole_2d();
        
        // Only add markings for columns 3-29 (the Kilter pattern)
        if (col >= 3 && col <= 29) {
            // Angle indicator and text - position text further away to avoid overlap
            translate([5 * mm_per_cm, 0]) {
                // Map display column to data column (col 3 -> 1, col 4 -> 2, etc.)
                data_col = col - 2;
                engrave_hold_id_2d(data_col, row, true);
            }
            
            // Add the angle indicator at the t-nut hole
            // Map display column to data column for angle lookup
            data_col = col - 2;
            angle = get_angle(data_col, row, true);
            
            // Convert angle to proper rotation with error handling
            rotate(convert_angle(angle))
            angle_indicator_2d();
        }
    }
}

// 2D vertical bolt pattern
module vertical_bolt_pattern_2d(col, row) {
    x = col_pos(col);
    y = row_pos(row);
    
    translate([x, y]) {
        // T-nut hole
        t_nut_hole_2d();
        
        // LED holes
        translate([0, vertical_led_spacing]) led_hole_2d();
        translate([0, -vertical_led_spacing]) led_hole_2d();
        
        // Only add markings for columns 3-29 (the Kilter pattern)
        if (col >= 3 && col <= 29) {
            // Angle indicator and text - position text further away to avoid overlap
            translate([5 * mm_per_cm, 0]) {
                // Map display column to data column (col 3 -> 1, col 4 -> 2, etc.)
                data_col = col - 2;
                engrave_hold_id_2d(data_col, row, false);
            }
            
            // Add the angle indicator at the t-nut hole
            // Map display column to data column for angle lookup
            data_col = col - 2;
            angle = get_angle(data_col, row, false);
            
            // Convert angle to proper rotation with error handling
            rotate(convert_angle(angle))
            angle_indicator_2d();
        }
    }
}

// Full climbing wall 2D module (without kicker)
module full_climbing_wall_2d() {
    difference() {
        // Main board outline
        square([full_width, full_height]);
        
        // Panel divider lines (for reference only)
        color("blue") {
            // Horizontal dividers
            translate([0, panel_height]) square([full_width, 1]);
            translate([0, 2 * panel_height]) square([full_width, 1]);
            
            // Vertical dividers (if needed)
            // translate([panel_width, 0]) square([1, full_height]);
        }
        
        // Generate all holds
        
        // Generate horizontal patterns (even columns with odd rows)
        for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]) {
            // For even columns, use odd rows
            for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
                horizontal_bolt_pattern_2d(col, row);
            }
            // Ignore kicker rows for now
        }
        
        // Generate vertical patterns (odd columns with even rows)
        for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31]) {
            // For odd columns, use even rows
            for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
                vertical_bolt_pattern_2d(col, row);
            }
            // Ignore kicker rows for now
        }
    }
}

// Function to determine which panel (1-6) a position belongs to
// Panel layout:
// Bottom row: Panel 1 (left, small), Panel 2 (right, large)
// Middle row: Panel 3 (left, large), Panel 4 (right, small)
// Top row: Panel 5 (left, small), Panel 6 (right, large)
function get_panel_for_position(col, row_num) =
    let(
        x = col_pos(col),
        y = row_pos(row_num),
        // Determine row (1=bottom, 2=middle, 3=top)
        row_index = floor(y / panel_height) + 1,
        // Panel boundaries for alternating layout
        is_bottom_row = (row_index == 1),
        is_middle_row = (row_index == 2),
        is_top_row = (row_index == 3),
        // Left/right boundary changes based on row
        left_boundary = is_middle_row ? half_panel_width : 0,
        right_boundary = is_middle_row ? full_width : half_panel_width,
        // Determine if position is in left or right panel
        is_left = (x < (is_middle_row ? panel_width : half_panel_width)),
        // Calculate panel number
        panel_num = is_bottom_row ? (is_left ? 1 : 2) :
                   is_middle_row ? (is_left ? 3 : 4) :
                   is_top_row ? (is_left ? 5 : 6) : 0
    )
    panel_num;

// Function to determine if a position fits within a specific panel
function position_fits_in_panel(col, row_num, panel_num) =
    get_panel_for_position(col, row_num) == panel_num;

// Individual panel module (for CNC cutting)
// Panel numbering:
// 1: Bottom left (small), 2: Bottom right (large)
// 3: Middle left (large), 4: Middle right (small)
// 5: Top left (small), 6: Top right (large)
module panel_2d(panel_num) {
    // Determine panel dimensions based on number
    p_width = (panel_num == 1 || panel_num == 4 || panel_num == 5) ? half_panel_width : panel_width;
    p_height = panel_height;
    
    // Calculate panel offsets for positioning holes correctly
    x_offset = (panel_num == 2) ? half_panel_width :
               (panel_num == 4) ? panel_width :
               (panel_num == 6) ? half_panel_width : 0;
    y_offset = (panel_num <= 2) ? 0 :
               (panel_num <= 4) ? panel_height :
               panel_height * 2;
    
    difference() {
        // Panel outline
        square([p_width, p_height]);
        
        // Generate horizontal patterns (even columns with odd rows)
        for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]) {
            // Check all possible rows
            for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
                if (position_fits_in_panel(col, row, panel_num)) {
                    // Translate to local panel coordinates
                    translate([-x_offset, -y_offset])
                    horizontal_bolt_pattern_2d(col, row);
                }
            }
        }
        
        // Generate vertical patterns (odd columns with even rows)
        for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31]) {
            // Check all possible rows
            for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
                if (position_fits_in_panel(col, row, panel_num)) {
                    // Translate to local panel coordinates
                    translate([-x_offset, -y_offset])
                    vertical_bolt_pattern_2d(col, row);
                }
            }
        }
    }
}

// 2D kicker module (separate panel)
module kicker_2d() {
    // Ignore kicker rows for now
    difference() {
        square([panel_width, kicker_height]);
        
        // Kicker rows are ignored for now
    }
}

// Create separate modules for different operations
// This allows exporting separate DXF files for each operation type

// Drill holes only (t-nut and LED holes)
module panel_drill_only(panel_num) {
    // Calculate panel offsets
    x_offset = (panel_num == 2) ? half_panel_width :
               (panel_num == 4) ? panel_width :
               (panel_num == 6) ? half_panel_width : 0;
    y_offset = (panel_num <= 2) ? 0 :
               (panel_num <= 4) ? panel_height :
               panel_height * 2;
    
    // Generate horizontal patterns (even columns with odd rows)
    for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]) {
        // Check all possible rows
        for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
            if (position_fits_in_panel(col, row, panel_num)) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x - x_offset, y - y_offset]) {
                    // T-nut hole
                    color("red") t_nut_hole_2d();
                    
                    // LED holes
                    color("red") translate([-horizontal_led_spacing, 0]) led_hole_2d();
                    color("red") translate([horizontal_led_spacing, 0]) led_hole_2d();
                }
            }
        }
    }
    
    // Generate vertical patterns (odd columns with even rows)
    for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31]) {
        // Check all possible rows
        for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
            if (position_fits_in_panel(col, row, panel_num)) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x - x_offset, y - y_offset]) {
                    // T-nut hole
                    color("red") t_nut_hole_2d();
                    
                    // LED holes
                    color("red") translate([0, vertical_led_spacing]) led_hole_2d();
                    color("red") translate([0, -vertical_led_spacing]) led_hole_2d();
                }
            }
        }
    }
}

// Engrave text and angle indicators only
module panel_engrave_only(panel_num) {
    // Calculate panel offsets
    x_offset = (panel_num == 2) ? half_panel_width :
               (panel_num == 4) ? panel_width :
               (panel_num == 6) ? half_panel_width : 0;
    y_offset = (panel_num <= 2) ? 0 :
               (panel_num <= 4) ? panel_height :
               panel_height * 2;
    
    // Generate horizontal patterns (even columns with odd rows)
    for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]) {
        // Check all possible rows
        for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
            if (position_fits_in_panel(col, row, panel_num) && col >= 3 && col <= 29) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x - x_offset, y - y_offset]) {
                    // Angle indicator and text - position text further away to avoid overlap
                    translate([5 * mm_per_cm, 0]) {
                        data_col = col - 2;
                        color("blue") engrave_hold_id_2d(data_col, row, true);
                    }
                    
                    // Add the angle indicator at the t-nut hole
                    data_col = col - 2;
                    angle = get_angle(data_col, row, true);
                    
                    // Convert angle to proper rotation with error handling
                    color("blue") rotate(convert_angle(angle))
                    angle_indicator_2d();
                }
            }
        }
    }
    
    // Generate vertical patterns (odd columns with even rows)
    for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31]) {
        // Check all possible rows
        for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
            if (position_fits_in_panel(col, row, panel_num) && col >= 3 && col <= 29) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x - x_offset, y - y_offset]) {
                    // Angle indicator and text - position text further away to avoid overlap
                    translate([5 * mm_per_cm, 0]) {
                        data_col = col - 2;
                        color("blue") engrave_hold_id_2d(data_col, row, false);
                    }
                    
                    // Add the angle indicator at the t-nut hole
                    data_col = col - 2;
                    angle = get_angle(data_col, row, false);
                    
                    // Convert angle to proper rotation with error handling
                    color("blue") rotate(convert_angle(angle))
                    angle_indicator_2d();
                }
            }
        }
    }
}

// Reference outline only
module panel_outline_only(panel_num) {
    // Determine panel dimensions
    p_width = (panel_num == 1 || panel_num == 4 || panel_num == 5) ? half_panel_width : panel_width;
    p_height = panel_height;
    
    // Panel outline
    color("green") square([p_width, p_height]);
    
    // Add panel number and position label for reference
    position = (panel_num == 1) ? "BOTTOM LEFT" :
               (panel_num == 2) ? "BOTTOM RIGHT" :
               (panel_num == 3) ? "MIDDLE LEFT" :
               (panel_num == 4) ? "MIDDLE RIGHT" :
               (panel_num == 5) ? "TOP LEFT" :
               "TOP RIGHT";
    
    color("green") translate([p_width/2, p_height/2]) {
        text(str("PANEL ", panel_num), size=50, halign="center", valign="center");
        translate([0, -60])
        text(position, size=30, halign="center", valign="center");
        translate([0, -100])
        text(str(p_width, " x ", p_height, " mm"), size=25, halign="center", valign="center");
    }
}

// Uncomment the section you want to render for CNC
// Only enable one at a time when exporting for CNC

// === COMPLETE PANELS (all elements) ===
// Render full climbing wall (all panels together, without kicker)
//full_climbing_wall_2d();

// Render Panel 1 (bottom panel) - all elements
//panel_2d(1);

// Render Panel 2 (middle panel) - all elements
//panel_2d(2);

// Render Panel 3 (top panel) - all elements
//panel_2d(3);

// === SEPARATE OPERATIONS (for multi-file approach) ===
// Panel 1 (Bottom Left - 1220mm) - Drilling operations only
panel_drill_only(1);

// Panel 1 - Engraving operations only
//panel_engrave_only(1);

// Panel 1 - Outline only
//panel_outline_only(1);

// Panel 2 (Bottom Right - 2440mm) - Drilling operations only
//panel_drill_only(2);

// Panel 2 - Engraving operations only
//panel_engrave_only(2);

// Panel 2 - Outline only
//panel_outline_only(2);

// Panel 3 (Middle Left - 2440mm) - Drilling operations only
//panel_drill_only(3);

// Panel 3 - Engraving operations only
//panel_engrave_only(3);

// Panel 3 - Outline only
//panel_outline_only(3);

// Panel 4 (Middle Right - 1220mm) - Drilling operations only
//panel_drill_only(4);

// Panel 4 - Engraving operations only
//panel_engrave_only(4);

// Panel 4 - Outline only
//panel_outline_only(4);

// Panel 5 (Top Left - 1220mm) - Drilling operations only
//panel_drill_only(5);

// Panel 5 - Engraving operations only
//panel_engrave_only(5);

// Panel 5 - Outline only
//panel_outline_only(5);

// Panel 6 (Top Right - 2440mm) - Drilling operations only
//panel_drill_only(6);

// Panel 6 - Engraving operations only
//panel_engrave_only(6);

// Panel 6 - Outline only
//panel_outline_only(6);

// Render Kicker (separate panel)
//kicker_2d();

// Display dimensions
echo("FULL CLIMBING WALL WIDTH (mm):", full_width);
echo("FULL CLIMBING WALL HEIGHT (mm):", full_height);
echo("FULL PANEL WIDTH (mm):", panel_width);
echo("HALF PANEL WIDTH (mm):", half_panel_width);
echo("PANEL HEIGHT (mm):", panel_height);
echo("TOTAL PANELS:", 6);
echo("KICKER HEIGHT (mm):", kicker_height);
echo("T-NUT HOLE SIZE (mm):", t_nut_hole_diameter);
echo("LED HOLE SIZE (mm):", led_hole_diameter);
echo("TOTAL COLUMNS:", col_count);
echo("KILTER PATTERN COLUMNS:", "3-29");
echo("EXTRA COLUMNS (no markings):", "1-2, 30-31");

// Export instructions:
// This model now supports a multi-file approach for better layer management in LibreCAD:
//
// 1. Export each operation type separately:
//    a. Uncomment ONE module at a time (e.g., panel_drill_only(1))
//    b. Render in OpenSCAD (press F6)
//    c. Export as DXF: File > Export > Export as DXF...
//    d. Save with a descriptive name (e.g., "panel1_drill.dxf")
//    e. Repeat for each operation type (drill, engrave, outline)
//
// 2. In LibreCAD:
//    a. Open a new document
//    b. Import each DXF file: File > Import > [select DXF file]
//    c. Each file will maintain its color information
//    d. Organize layers in Layer Manager:
//       - RED elements (from drill file): Rename layer to "DRILL"
//       - BLUE elements (from engrave file): Rename layer to "ENGRAVE"
//       - GREEN elements (from outline file): Rename layer to "REFERENCE"
//    e. Save the combined file as a new DXF
//
// 3. When submitting to the CNC shop, specify:
//    - DRILL layer elements should be drilled through the material
//    - ENGRAVE layer elements should be lightly engraved (specify depth, e.g., 1mm)
//    - REFERENCE layer elements are for reference only and should not be machined
//
// This approach ensures each operation type is clearly separated in the final DXF file,
// making it easier for the CNC shop to understand and implement your requirements.
