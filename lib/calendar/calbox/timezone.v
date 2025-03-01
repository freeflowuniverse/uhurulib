module calbox
import freeflowuniverse.herolib.core.pathlib

// Represents a time zone component
@[heap]
pub struct TimeZone{
pub mut:
    tzid          string            // Time zone identifier (e.g., "US-Eastern")
    last_modified string            // Last modified timestamp (e.g., "19870101T000000Z")
    standard      TimeZoneRule      // Standard time rule
    daylight      TimeZoneRule      // Daylight saving time rule
}

// Represents a time zone rule (STANDARD or DAYLIGHT)
@[heap]
pub struct TimeZoneRule {
pub mut:
    dtstart        string            // Start date and time (e.g., "19671029T020000")
    rrule          string            // Recurrence rule (e.g., "FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10")
    tzoffset_from  string            // Offset from UTC before the transition (e.g., "-0400")
    tzoffset_to    string            // Offset from UTC after the transition (e.g., "-0500")
    tzname         string            // Time zone name (e.g., "Eastern Standard Time (US & Canada)")
}

// Implement Clone for TimeZoneRule
pub fn (self TimeZoneRule) clone() TimeZoneRule {
    return TimeZoneRule{
        dtstart: self.dtstart.clone()
        rrule: self.rrule.clone()
        tzoffset_from: self.tzoffset_from.clone()
        tzoffset_to: self.tzoffset_to.clone()
        tzname: self.tzname.clone()
    }
}

// Parses a TimeZone component from ICS string
pub fn new_vtimezone(ics string) !TimeZone {
    println("hereee")
    lines := ics.split_into_lines()
    mut tzid, mut last_modified := '', ''
    mut standard, mut daylight := TimeZoneRule{}, TimeZoneRule{}
    mut current_rule := &TimeZoneRule{}
    mut current := ''

    for line in lines {
        if line.starts_with('TZID:') {
            tzid = line.all_after('TZID:')
        } else if line.starts_with('LAST-MODIFIED:') {
            last_modified = line.all_after('LAST-MODIFIED:')
        } else if line.starts_with('BEGIN:STANDARD') {
            current = 'STANDARD'
        } else if line.starts_with('BEGIN:DAYLIGHT') {
            current = 'DAYLIGHT'
        } else if line.starts_with('DTSTART:') {
            current_rule.dtstart = line.all_after('DTSTART:')
        } else if line.starts_with('RRULE:') {
            current_rule.rrule = line.all_after('RRULE:')
        } else if line.starts_with('TZOFFSETFROM:') {
            current_rule.tzoffset_from = line.all_after('TZOFFSETFROM:')
        } else if line.starts_with('TZOFFSETTO:') {
            current_rule.tzoffset_to = line.all_after('TZOFFSETTO:')
        } else if line.starts_with('TZNAME:') {
            current_rule.tzname = line.all_after('TZNAME:')
        }else if line.starts_with('END:') {
            rule := line.all_after('END:')
            if rule != current {
                error('invalid timezone syntax')
            }
            if rule == 'STANDARD' {
                standard = current_rule.clone()
            }else {
                daylight = current_rule.clone()
            }
        }
    }
    println('tzid2---->: and ${tzid}')
    if tzid == '' {
        return error('Missing required fields in VTIMEZONE val ${tzid}')
    }

    return TimeZone{
        tzid: tzid
        last_modified: last_modified
        standard: standard
        daylight: daylight
    }
}

// Save function for TimeZone
pub fn (self TimeZone) save(path string) ! {
    content := 'BEGIN:VTIMEZONE\nTZID:${self.tzid}\nLAST-MODIFIED:${self.last_modified}\n' +
               'BEGIN:STANDARD\nDTSTART:${self.standard.dtstart}\nRRULE:${self.standard.rrule}\n' +
               'TZOFFSETFROM:${self.standard.tzoffset_from}\nTZOFFSETTO:${self.standard.tzoffset_to}\n' +
               'TZNAME:${self.standard.tzname}\nEND:STANDARD\n' +
               'BEGIN:DAYLIGHT\nDTSTART:${self.daylight.dtstart}\nRRULE:${self.daylight.rrule}\n' +
               'TZOFFSETFROM:${self.daylight.tzoffset_from}\nTZOFFSETTO:${self.daylight.tzoffset_to}\n' +
               'TZNAME:${self.daylight.tzname}\nEND:DAYLIGHT\nEND:VTIMEZONE'
    
    mut p := pathlib.get(path +'/'+ self.tzid+'.ics')
    p.write(content) or { return error('Failed to save TimeZone') }
}