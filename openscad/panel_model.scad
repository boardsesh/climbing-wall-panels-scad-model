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
full_width = 10 * 12 * mm_per_inch;   // 10ft in mm (3048mm)
full_height = 12 * 12 * mm_per_inch;  // 12ft in mm (3657.6mm)

// Panel dimensions
panel_width = 3050;      // Actual width of Birch Ply panels (3050mm)
panel_height = 1525;     // Actual height of Birch Ply panels (1525mm)
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
// Columns are 10cm apart, with 22.4cm from edge to first column (C1)
col_edge_margin = 22.4 * mm_per_cm;      // 22.4cm from left edge to C1
col_spacing = 10 * mm_per_cm;            // 10cm between columns
col_count = 27;

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
        
        // Angle indicator and text - position text further away to avoid overlap
        translate([5 * mm_per_cm, 0]) {
            engrave_hold_id_2d(col, row, true);
        }
        
        // Add the angle indicator at the t-nut hole
        // Pass row directly to get_angle
        angle = get_angle(col, row, true);
        
        // Convert angle to proper rotation with error handling
        rotate(convert_angle(angle))
        angle_indicator_2d();
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
        
        // Angle indicator and text - position text further away to avoid overlap
        translate([5 * mm_per_cm, 0]) {
            engrave_hold_id_2d(col, row, false);
        }
        
        // Add the angle indicator at the t-nut hole
        // Pass row directly to get_angle
        angle = get_angle(col, row, false);
        
        // Convert angle to proper rotation with error handling
        rotate(convert_angle(angle))
        angle_indicator_2d();
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
        for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]) {
            // For even columns, use odd rows
            for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
                horizontal_bolt_pattern_2d(col, row);
            }
            // Ignore kicker rows for now
        }
        
        // Generate vertical patterns (odd columns with even rows)
        for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27]) {
            // For odd columns, use even rows
            for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
                vertical_bolt_pattern_2d(col, row);
            }
            // Ignore kicker rows for now
        }
    }
}

// Function to determine if a row position fits within a panel's vertical range
function row_fits_in_panel(row_num, panel_num) =
    let(
        y = row_pos(row_num),
        panel_bottom = (panel_num - 1) * panel_height,
        panel_top = panel_num * panel_height,
        fits = (y >= panel_bottom && y < panel_top),
        debug = fits ? echo(str("Panel ", panel_num, " includes row ", row_num, " at y=", y, "mm")) : undef
    )
    fits;

// Individual panel module (for CNC cutting)
module panel_2d(panel_num) {
    difference() {
        // Panel outline
        square([panel_width, panel_height]);
        
        // Generate horizontal patterns (even columns with odd rows)
        for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]) {
            // Check all possible rows
            for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
                if (row_fits_in_panel(row, panel_num)) {
                    horizontal_bolt_pattern_2d(col, row);
                }
            }
        }
        
        // Generate vertical patterns (odd columns with even rows)
        for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27]) {
            // Check all possible rows
            for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
                if (row_fits_in_panel(row, panel_num)) {
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
    // Generate horizontal patterns (even columns with odd rows)
    for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]) {
        // Check all possible rows
        for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
            if (row_fits_in_panel(row, panel_num)) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x, y - (panel_num - 1) * panel_height]) {
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
    for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27]) {
        // Check all possible rows
        for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
            if (row_fits_in_panel(row, panel_num)) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x, y - (panel_num - 1) * panel_height]) {
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
    // Generate horizontal patterns (even columns with odd rows)
    for (col = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]) {
        // Check all possible rows
        for (row = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]) {
            if (row_fits_in_panel(row, panel_num)) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x, y - (panel_num - 1) * panel_height]) {
                    // Angle indicator and text - position text further away to avoid overlap
                    translate([5 * mm_per_cm, 0]) {
                        color("blue") engrave_hold_id_2d(col, row, true);
                    }
                    
                    // Add the angle indicator at the t-nut hole
                    angle = get_angle(col, row, true);
                    
                    // Convert angle to proper rotation with error handling
                    color("blue") rotate(convert_angle(angle))
                    angle_indicator_2d();
                }
            }
        }
    }
    
    // Generate vertical patterns (odd columns with even rows)
    for (col = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27]) {
        // Check all possible rows
        for (row = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]) {
            if (row_fits_in_panel(row, panel_num)) {
                x = col_pos(col);
                y = row_pos(row);
                
                translate([x, y - (panel_num - 1) * panel_height]) {
                    // Angle indicator and text - position text further away to avoid overlap
                    translate([5 * mm_per_cm, 0]) {
                        color("blue") engrave_hold_id_2d(col, row, false);
                    }
                    
                    // Add the angle indicator at the t-nut hole
                    angle = get_angle(col, row, false);
                    
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
    // Panel outline
    color("green") square([panel_width, panel_height]);
    
    // Add panel number label for reference
    color("green") translate([panel_width/2, panel_height/2])
    text(str("PANEL ", panel_num), size=50, halign="center", valign="center");
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
// Panel 1 - Drilling operations only
panel_drill_only(1);

// Panel 1 - Engraving operations only
//panel_engrave_only(1);

// Panel 1 - Outline only
//panel_outline_only(1);

// Panel 2 - Drilling operations only
//panel_drill_only(2);

// Panel 2 - Engraving operations only
//panel_engrave_only(2);

// Panel 2 - Outline only
//panel_outline_only(2);

// Panel 3 - Drilling operations only
//panel_drill_only(3);

// Panel 3 - Engraving operations only
//panel_engrave_only(3);

// Panel 3 - Outline only
//panel_outline_only(3);

// Render Kicker (separate panel)
//kicker_2d();

// Display dimensions
echo("FULL CLIMBING WALL WIDTH (mm):", full_width);
echo("FULL CLIMBING WALL HEIGHT (mm):", full_height);
echo("PANEL WIDTH (mm):", panel_width);
echo("PANEL HEIGHT (mm):", panel_height);
echo("KICKER HEIGHT (mm):", kicker_height);
echo("T-NUT HOLE SIZE (mm):", t_nut_hole_diameter);
echo("LED HOLE SIZE (mm):", led_hole_diameter);

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
