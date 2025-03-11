module calbox
import freeflowuniverse.herolib.core.pathlib


// Represents a journal entry
@[heap]
pub struct Journal implements CalendarComponent{
pub mut:
	uid         string
	dtstamp     string    // Creation or last update timestamp
	description string
	props 		map[string]string
}

pub fn (self Journal)  to_ics() string {
	return ''
}

pub fn new_vjournal (ics string) !Journal{
	lines := ics.split_into_lines()
    mut journal := Journal{}

    for line in lines {
        if line.starts_with('UID:') {
            journal.uid = line.all_after('UID:')
        } else if line.starts_with('DTSTAMP:') {
            journal.dtstamp = line.all_after('DTSTAMP:')
        } else if line.starts_with('DESCRIPTION:') {
            journal.description = line.all_after('DESCRIPTION:')
        } else {
            index := line.index(':') or { return error("Delimiter : not found in the string.")}
			journal.props[line[..index]] = line[index + 1..]
		}
    }

    if journal.uid == '' || journal.dtstamp == '' || journal.description == '' {
        return error('Missing required fields in VEVENT')
    }

    return journal
}

// Save function for Event
pub fn (self Journal) save(path string) ! {
    mut content := 'BEGIN:VJOURNAL\nUID:${self.uid}\nDTSTAMP:${self.dtstamp}\nDESCRIPTION:${self.description}\n'
    for key, val in self.props {
        content += '${key}:${val}\n'
    }
    content += 'END:VJOURNAL'
    mut p := pathlib.get(path + '/' + self.uid + '.ics')
    p.write(content) or { return error('Failed to save Event') }
}