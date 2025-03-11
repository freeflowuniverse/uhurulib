module calbox

// Base calendar component fields
@[heap]
pub interface CalendarComponent {
	to_ics() string	  // iCalendar representation
	save(path string)!
mut:
	uid         string
	dtstamp     string    // Creation or last update timestamp
	props 		map[string]string
}
