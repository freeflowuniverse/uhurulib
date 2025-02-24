module calbox
import freeflowuniverse.herolib.core.pathlib

// Represents a todo/task
@[heap]
pub struct Todo implements CalendarComponent{
pub mut:
	uid         string
	dtstamp     string    // Creation or last update timestamp
	props 		map[string]string
	start_time ?i64    // Optional start time
	end_time   ?i64    // When the todo is due
	summary     string
	v_alarm 	Alarm
	status     ?TodoStatus
	rrule      ?string
	attendees  []Attendee
	organizer  ?Attendee
}

pub fn (self Todo)  to_ics() string {
	return ''
}

// Parses a Todo component from an ICS string
pub fn new_todo(ics string) !Todo {
    lines := ics.split_into_lines()
    mut todo := Todo{}
    mut v_alarm := Alarm{}

    for line in lines {
        if line.starts_with('UID:') {
            todo.uid = line.all_after('UID:')
        } else if line.starts_with('DTSTAMP:') {
            todo.dtstamp = line.all_after('DTSTAMP:')
        } else if line.starts_with('SUMMARY:') {
            todo.summary = line.all_after('SUMMARY:')
        } else if line.starts_with('DTSTART:') {
            todo.start_time = line.all_after('DTSTART:').i64()
        } else if line.starts_with('DUE:') {
            todo.end_time = line.all_after('DUE:').i64()
        } else if line.starts_with('RRULE:') {
            todo.rrule = line.all_after('RRULE:')
        } else if line.starts_with('STATUS:') {
            todo.status = string_to_todo_status(line.all_after('STATUS:'))
        } else if line.starts_with('ACTION:') {
            v_alarm.action = parse_alarm_action(line.all_after('ACTION:')) or { AlarmAction.display }
        } else if line.starts_with('TRIGGER:') {
            v_alarm.trigger = line.all_after('TRIGGER:')
        } else if line.starts_with('REPEAT:') {
            v_alarm.repeat = line.all_after('REPEAT:').int()
        } else if line.starts_with('DURATION:') {
			mut duration := Duration{}
			duration = parse_duration(line.all_after('DURATION:'))!
            v_alarm.duration = duration
        }
    }


    if todo.uid == '' || todo.dtstamp == '' || todo.summary == '' {
        return error('Missing required fields in VTODO')
    }

    return todo
}

// Saves the Todo as an ICS file
pub fn (self Todo) save(path string) ! {
    mut content := 'BEGIN:VTODO\nUID:${self.uid}\nDTSTAMP:${self.dtstamp}\nSUMMARY:${self.summary}\n'
    if self.start_time != none { content += 'DTSTART:${self.start_time}\n' }
    if self.end_time != none { content += 'DUE:${self.end_time}\n' }
    if self.rrule != none { content += 'RRULE:${self.rrule}\n' }
    if self.status != none { content += 'STATUS:${todo_status_to_string(self.status)}\n' }
    content += 'END:VTODO'
	mut p := pathlib.get(path + '/' + self.uid + '.ics')
    p.write(content) or { return error('Failed to save Todo') }
}

enum TodoStatus {
	needs_action
	in_process
	completed
	cancelled
}

// Converts TodoStatus enum to a string (uppercase for ICS format)
fn todo_status_to_string(status TodoStatus) string {
	return match status {
		.needs_action { 'NEEDS-ACTION' }
		.in_process   { 'IN-PROCESS' }
		.completed    { 'COMPLETED' }
		.cancelled    { 'CANCELLED' }
	}
}

// Converts a string to the corresponding TodoStatus enum
fn string_to_todo_status(status string) ?TodoStatus {
	return match status.to_upper() {
		'NEEDS-ACTION' { TodoStatus.needs_action }
		'IN-PROCESS'   { TodoStatus.in_process }
		'COMPLETED'    { TodoStatus.completed }
		'CANCELLED'    { TodoStatus.cancelled }
		else           { error('Invalid status: ${status}') }
	}
}
