module calbox

// Represents a calendar object resource (event, todo, journal)
@[heap]
pub struct CalendarItem {
pub mut:
	calendar_components []CalendarComponent
	timezone_components []TimeZone
	header  []string  // List of header lines
	footer  string  // List of footer lines
}

// Component type enum
pub enum ComponentType {
	vevent
	vtodo
	vjournal
	vtimezone
}


pub fn new_calendar_item(ics string)! CalendarItem {
	lines := ics.split_into_lines()
	if lines.len < 3 {
		return error('Invalid ICS format')
	}

	mut header := []string{}
	mut footer := ''
	mut components := []CalendarComponent{}
	mut timezones := []TimeZone{}
	mut current_component := []string{}
	mut current_type := ""
	mut card_type := ""
	mut in_component := 0

	for line in lines {
		if line.starts_with('BEGIN:VCALENDAR') {
			header << line
		} else if line.starts_with('END:VCALENDAR') {
			footer = line
		} else if line.starts_with('BEGIN:') && in_component == 0{
			// Start of a new component
			current_component = header.clone()
			current_component << line
			in_component++;

			// Detect component type
			if line.contains('VEVENT') {
				current_type = "vevent"
			} else if line.contains('VTODO') {
				current_type = "vtodo"
			} else if line.contains('VJOURNAL') {
				current_type = "vjournal"
			}else if line.contains('VTIMEZONE') {
				current_type = "vtimezone"
			}else {
				error('Unsupported ics type')
			}
		} else if line.starts_with('END:') && in_component == 1 {
			current_component << line
			current_component << 'END:VCALENDAR'
			// Save component
			match current_type {
				"vevent" {
					if card_type != '' && card_type != "vevent" {
						error('card contain multiple types')
					}else {
						card_type = 'vevent'
					}
					mut component := new_vevent(current_component.join('\n'))!
					components << component
				}
				"vtodo" {
					if card_type != '' && card_type != "vtodo" {
						error('card contain multiple types')
					}else {
						card_type = 'vtodo'
					}
					mut component := new_vevent(current_component.join('\n'))!
					components << component
				}
				"vjournal" {
					if card_type != '' && card_type != "vjournal" {
						error('card contain multiple types')
					}else {
						card_type = 'vjournal'
					}
					mut component := new_vevent(current_component.join('\n'))!
					components << component
				}
				"vtimezone" {
					mut component := new_vtimezone(current_component.join('\n'))!
					timezones << component
				}
				else {
					error('Unsupported ics type')
				}
			}
			in_component = 0
		} else {
			// Add to header or current component
			if in_component > 0 {
				current_component << line
				if line.starts_with('END:') {
					in_component--;
				}
			} else {
				header << line
			}
		}
	}

	return CalendarItem{
		calendar_components: components
		timezone_components: timezones
		header: header
		footer: footer
	}
}


pub fn (self CalendarItem) save(path string)! {
	for _, component in self.calendar_components {
		component.save(path) or { return error('Failed to save ICS file') }
	}
	for _, timezone in self.timezone_components {
		timezone.save(path) or { return error('Failed to save ICS file') }
	}
}