module calbox
import os
import json
import freeflowuniverse.herolib.core.pathlib

// Represents a calendar collection
@[heap]
pub struct Calendar {
pub mut:
	name        string
	objects     CalendarItem
	description string
	read_only   bool   // Whether calendar is read-only

	// Properties from CalDAV spec
	min_date_time        string          // Earliest date allowed
	max_date_time        string          // Latest date allowed
	max_instances        int             // Max recurrence instances
	max_attendees        int             // Max attendees per instance
	max_resource_size    int             // Max size of calendar object
}

// Constructor for Calendar
pub fn new_calendar(name string, description string, min_date_time string, max_date_time string, max_instances int, max_attendees int, max_resource_size int) Calendar {
	return Calendar{
		name: name
		description: description
		min_date_time: min_date_time
		max_date_time: max_date_time
		max_instances: max_instances
		max_attendees: max_attendees
		max_resource_size: max_resource_size
	}
}

// Ensures the given path is a valid Calendar collection
pub fn is_calendar_collection(path string) bool {
	mut p := pathlib.get(path)
	mut collection_metadata := pathlib.get(os.join_path(path, 'collection.json'))
	return p.is_dir() && collection_metadata.exists()
}

// Saves the calendar as a JSON file
pub fn (c Calendar) save(path string) ! {
	if !is_calendar_collection(path) {
		return 
	}
	data := json.encode_pretty(c)
	os.write_file(os.join_path(path, 'collection.json'), data) or { error('Error writing metadata to the collection') }

	c.objects.save(path)!
}

// Deletes a calendar collection
pub fn delete_calendar(path string) ! {
	if is_calendar_collection(path) {
		os.rmdir_all(path) or { error('Error deleting calendar path') }
	} else {
		return error('Invalid calendar path')
	}
}

// Retrieves all resources from a calendar collection
pub fn get_resources(path string) ![]CalendarItem {
	mut items := []CalendarItem{}
	new_calendar_item(path)!

	files := os.ls(path)!
	for file in files {
		if file.ends_with('.ics') {
			content := os.read_file(os.join_path(path, file))!
			items << new_calendar_item(content)!
		}
	}
	return items
}
