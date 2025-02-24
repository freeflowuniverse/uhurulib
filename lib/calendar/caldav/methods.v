module caldav
import vweb
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import log
import encoding.xml
import freeflowuniverse.uhurulib.calendar.calbox

// // Handles PUT request
// pub fn handle_put(cal &calbox.CalBox, obj calbox.CalendarObject, principal Principal) !bool {
// 	// Check privileges
// 	if !cal.acl.can_write(principal) {
// 		return error(err_no_privilege)
// 	}

// 	// Check preconditions
// 	check_put_preconditions(cal, obj)!

// 	// Add/update object
// 	cal.put(obj)!

// 	return true
// }

// // Handles DELETE request
// pub fn handle_delete(cal &calbox.CalBox, uid string, principal Principal) !bool {
// 	// Check privileges
// 	if !cal.acl.can_unbind(principal) {
// 		return error(err_no_privilege)
// 	}

// 	// Delete object
// 	cal.delete(uid)!

// 	return true
// }

// // Handles COPY request
// pub fn handle_copy(src_cal &calbox.CalBox, dst_cal &calbox.CalBox, uid string, principal Principal) !bool {
// 	// Check source privileges
// 	if !src_cal.acl.can_read(principal) {
// 		return error(err_no_privilege)
// 	}

// 	// Check destination privileges
// 	if !dst_cal.acl.can_bind(principal) {
// 		return error(err_no_privilege)
// 	}

// 	// Get source object
// 	obj := src_cal.get_by_uid(uid) or { return error(err_resource_not_found) }

// 	// Check preconditions
// 	check_copy_move_preconditions(src_cal, dst_cal, obj)!

// 	// Copy object
// 	dst_cal.put(obj)!

// 	return true
// }

// // Handles MOVE request
// pub fn handle_move(src_cal &calbox.CalBox, dst_cal &calbox.CalBox, uid string, principal Principal) !bool {
// 	// Check source privileges
// 	if !src_cal.acl.can_unbind(principal) {
// 		return error(err_no_privilege)
// 	}

// 	// Check destination privileges
// 	if !dst_cal.acl.can_bind(principal) {
// 		return error(err_no_privilege)
// 	}

// 	// Get source object
// 	obj := src_cal.get_by_uid(uid) or { return error(err_resource_not_found) }

// 	// Check preconditions
// 	check_copy_move_preconditions(src_cal, dst_cal, obj)!

// 	// Move object
// 	dst_cal.put(obj)!
// 	src_cal.delete(uid)!

// 	return true
// }

// // Handles PROPFIND request
// pub fn handle_propfind(cal &calbox.CalBox, props []string, principal Principal) !map[string]string {
// 	// Check privileges
// 	if !cal.acl.can_read(principal) {
// 		return error(err_no_privilege)
// 	}

// 	mut result := map[string]string{}

// 	// Get requested properties
// 	for prop in props {
// 		if value := get_prop_string(cal.props, prop) {
// 			result[prop] = value
// 		}
// 	}

// 	return result
// }

// // Handles PROPPATCH request
// pub fn handle_proppatch(mut cal calbox.CalBox, props map[string]string, principal Principal) !bool {
// 	// Check privileges
// 	if !cal.acl.can_write_props(principal) {
// 		return error(err_no_privilege)
// 	}

// 	// Validate and set properties
// 	for name, value in props {
// 		match name {
// 			calendar_timezone { validate_calendar_timezone(value)! }
// 			supported_calendar_component_set { validate_supported_component_set(value.split(','))! }
// 			else {}
// 		}
// 		set_prop(mut cal.props, name, value)
// 	}

// 	return true
// }

@['/:path...'; options]
fn (mut app App) options(path string) vweb.Result {
	app.set_status(200, 'OK')
	app.add_header('DAV', '1,2')
	app.add_header('Allow', 'OPTIONS, PROPFIND, MKCALENDAR, MKCOL, GET, HEAD, POST, PUT, DELETE, COPY, MOVE')
	app.add_header('MS-Author-Via', 'DAV')
	app.add_header('Access-Control-Allow-Origin', '*')
	app.add_header('Access-Control-Allow-Methods', 'OPTIONS, PROPFIND, MKCOL, GET, HEAD, POST, PUT, DELETE, COPY, MOVE')
	app.add_header('Access-Control-Allow-Headers', 'Authorization, Content-Type')
	app.send_response_to_client('text/plain', '')
	return vweb.not_found()
}

@['/:path...'; mkcalendar]
fn (mut app App) mkcalendar(path string) vweb.Result {
	mut calendar_path := pathlib.get(app.root_dir.path + path)

	// Check if the calendar already exists
	if calendar_path.exists() {
		return app.bad_request('Another collection exists at ${app.root_dir.path + path}')
	}
	file_data := app.req.data
	doc := xml.XMLDocument.from_string(file_data) or { return app.bad_request('Invalid XML data') }

	mut calendar := calbox.Calendar{}
	app.collections << &calendar
	app.print_xml_nodes(doc.root, 1)
	return app.text('HTTP 200: Successfully saved file: ${app.root_dir.path + path}')
}

fn (mut app App) print_xml_nodes(node xml.XMLNode, depth int) {
    // Print the current node's name and text (if any)
    println('Tag: ${node.name}')
	println('Depth: ${depth}')
	if depth == 1 && node.name != 'C:mkcalendar' {
		panic('')
	}

	
    // Print attributes (if any)
    for attr, attrval in node.attributes {
        println('Attribute: ${attr} = ${attrval}')
    }

    // Recursively print child nodes
    for child in node.children {
        match child {
            xml.XMLNode {
                // If the child is another XML node, recursively process it
                app.print_xml_nodes(child, depth+1)
            }
            string {
				// If the child is plain text or CDATA, print it
                println('Text/CDATA: ${child}')
                if node.name == 'C:max-attendees-per-instance' {
					app.collections.last().max_attendees = child.str().int()
				}else if node.name == 'C:max-resource-size' {
					app.collections.last().max_resource_size = child.str().int()
				}else if node.name == 'C:min-date-time' {
					app.collections.last().min_date_time = child.str()
				}else if node.name == 'C:max-date-time' {
					app.collections.last().max_date_time = child.str()
				}else if node.name == 'C:max-instances' {
					app.collections.last().max_instances = child.str().int()
				}
            }
            xml.XMLComment {
                // If the child is a comment, print it
                println('Comment: ${child.text}')
            }
			xml.XMLCData{
				println('CDATA: ${child}')
				if node.name == 'C:calendar-timezone' {
					app.collections.last().objects.timezone_components << calbox.new_vtimezone(child.text) or {panic(err)}
				}
			}
            // else {
            //     // Handle other types of children (if any)
            //     println('Unknown child type: ${child}')
            // }
        }
    }
}