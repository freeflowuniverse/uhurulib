module calbox

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
	rrule      string
	attendees  []Attendee
	organizer  ?Attendee
}

pub fn (self Todo)  to_ics() string {
	return ''
}

pub fn (self Todo) save(path string) ! {
	return 
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
