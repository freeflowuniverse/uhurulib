module calbox
import freeflowuniverse.herolib.core.pathlib

// Represents an event
@[heap]
pub struct Event implements CalendarComponent{
pub mut:
	uid         string
	dtstamp     string    // Creation or last update timestamp
	props 		map[string]string
	start_time ?i64
	end_time   ?i64    // Either end_time or duration must be set
	duration   ?string // ISO 8601 duration format
	rrule      ?string
	attendees  []Attendee
	organizer  ?Attendee
}


pub fn (self Event)  to_ics() string {
	return ''
}
// Parses an Event component from ICS string
pub fn new_vevent(ics string) !Event {
    lines := ics.split_into_lines()
    mut event := Event{}

    for line in lines {
        if line.starts_with('UID:') {
            event.uid = line.all_after('UID:')
        } else if line.starts_with('DTSTAMP:') {
            event.dtstamp = line.all_after('DTSTAMP:')
        } else if line.starts_with('DTSTART:') {
            event.start_time = line.all_after('DTSTART:').i64()
        } else if line.starts_with('DTEND:') {
            event.end_time = line.all_after('DTEND:').i64()
        } else if line.starts_with('DURATION:') {
            event.duration = line.all_after('DURATION:')
        } else if line.starts_with('RRULE:') {
            event.rrule = line.all_after('RRULE:')
        }else {
            index := line.index(':') or { return error("Delimiter : not found in the string.")}
			event.props[line[..index]] = line[index + 1..]
		}
    }

    if event.uid == '' || event.dtstamp == '' {
        return error('Missing required fields in VEVENT')
    }

    return event
}

// Save function for Event
pub fn (self Event) save(path string) ! {
    mut content := 'BEGIN:VEVENT\nUID:${self.uid}\nDTSTAMP:${self.dtstamp}\n'
    if self.start_time != none { content += 'DTEND:${self.start_time}\n' }
    if self.end_time != none { content += 'DTEND:${self.end_time}\n' }
    if self.duration != none { content += 'DURATION:${self.duration}\n' }
    if self.rrule != none { content += 'RRULE:${self.rrule}\n' }
    for key, val in self.props {
        content += '${key}:${val}\n'
    }
    content += 'END:VEVENT'
    mut p := pathlib.get(path + '/' + self.uid + '.ics')
    p.write(content) or { return error('Failed to save Event') }
}

// Checks if an event overlaps with a time range
// fn (event Event) overlaps(tr TimeRange) bool {
// 	// Get end time from either end_time or duration
// 	mut end_ts := event.end_time or {
// 		// TODO: Add duration parsing to get actual end time
// 		event.start_time + 3600 // Default 1 hour if no end/duration
// 	}

// 	// Check basic overlap
// 	if is_in_range(event.start_time, tr) || is_in_range(end_ts, tr) {
// 		return true
// 	}

// 	// Check recurrences if any
// 	if rule := event.rrule {
// 		// TODO: Implement recurrence expansion
// 		// For now just check if the rule's until date (if any) is after range start
// 		if until := rule.until {
// 			return until >= tr.start
// 		}
// 		return true // Infinite recurrence overlaps everything
// 	}

// 	return false
// }

// // Gets the effective end time of an event
// pub fn (event Event) get_effective_end_time() !i64 {
// 	if end := event.end_time {
// 		return end
// 	}
// 	if dur_str := event.duration {
// 		duration := parse_duration(dur_str)!
// 		return duration.add_to(event.start_time)
// 	}
// 	// Default 1 hour duration
// 	return event.start_time + 3600
// }

// Gets all instances of an event that overlap with a time range
// pub fn (event Event) get_instances(tr TimeRange) ![]EventInstance {
// 	// For non-recurring events, just check if it overlaps
// 	if event.rrule == none && event.rdate.len == 0 {
// 		end_time := event.get_effective_end_time()!
// 		if event.start_time < tr.end && end_time > tr.start {
// 			return [
// 				EventInstance{
// 					original_event: event
// 					start_time:     event.start_time
// 					end_time:       end_time
// 					recurrence_id:  event.start_time
// 					is_override:    false
// 				},
// 			]
// 		}
// 		return []
// 	}

// 	// Expand recurring event
// 	if instances := expand_recurring_event(event, tr) {
// 		return instances
// 	}
// 	return []
// }
