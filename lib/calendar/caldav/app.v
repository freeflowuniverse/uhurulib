module caldav

import freeflowuniverse.uherolib.calendar.calbox
import vweb
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console

// Represents a CalDAV app instance
pub struct App {
	vweb.Context
	user_db  map[string]string @[required]
	root_dir pathlib.Path      @[vweb_global]
pub mut:
	server_port int
	middlewares map[string][]vweb.Middleware
	collections map[string]&calbox.Calendar // Map of calendar collections by path
}

@[params]
pub struct AppArgs {
pub mut:
	server_port int = 8080
	root_dir    string            @[required]
	user_db     map[string]string @[required]
}

// Creates a new CalDAV app instance
pub fn new(args AppArgs) !&App {
	root_dir := pathlib.get_dir(path: args.root_dir, create: true)!
	mut app := &App{
		user_db:     args.user_db.clone()
		root_dir:    root_dir
		server_port: args.server_port
		collections: map[string]&calbox.Calendar{}
	}
	app.middlewares['/'] << logging_middleware
	app.middlewares['/'] << app.auth_middleware

	return app

}

@[params]
pub struct RunArgs {
pub mut:
	background bool
}

pub fn (mut app App) run(args RunArgs) {
	console.print_green('Running the server on port: ${app.server_port}')

	if args.background {
		spawn vweb.run(app, app.server_port)
	} else {
		vweb.run(app, app.server_port)
	}
}

pub fn (mut app App) not_found() vweb.Result {
	app.set_status(404, 'Not Found')
	return app.text('Not Found')
}

pub fn (mut app App) server_error() vweb.Result {
	app.set_status(500, 'Inernal Server Error')
	return app.text('Internal Server Error')
}

pub fn (mut app App) bad_request(message string) vweb.Result {
	app.set_status(400, 'Bad Request')
	return app.text(message)
}


// // Adds a calendar collection to the app
// pub fn (mut s App) add_collection(path string, cal &calbox.Calendar) {
// 	s.collections[path] = cal
// }

// // Gets a calendar collection by path
// pub fn (s App) get_collection(path string) ?&calbox.Calendar {
// 	return s.collections[path] or { none }
// }

// // Handles a MKCALENDAR request
// pub fn (mut s App) handle_mkcalendar(path string, props map[string]string) !&calbox.Calendar {
// 	// Create new calendar collection
// 	mut cal := calbox.new(props['displayname'] or { path.all_after_last('/') })

// 	// Set optional properties
// 	if desc := props['calendar-description'] {
// 		cal.description = desc
// 	}
// 	if tz := props['calendar-timezone'] {
// 		cal.timezone = tz
// 	}
// 	if components := props['supported-calendar-component-set'] {
// 		cal.supported_components = components.split(',')
// 	}

// 	// Add to app
// 	s.add_collection(path, cal)

// 	return cal
// }

// // Handles a calendar-query REPORT request
// pub fn (s App) handle_calendar_query(path string, filter CalendarQueryFilter) ![]calbox.CalendarObject {
// 	// Get calendar collection
// 	cal := s.get_collection(path) or { return error('Calendar not found') }

// 	// Apply filter
// 	mut results := []calbox.CalendarObject{}

// 	if filter.time_range != none {
// 		tr := filter.time_range or { return error('Invalid time range') }
// 		results = cal.find_by_time(calbox.TimeRange{
// 			start: tr.start
// 			end:   tr.end
// 		})!
// 	} else {
// 		results = cal.list()!
// 	}

// 	return results
// }

// // Handles a calendar-multiget REPORT request
// pub fn (s App) handle_calendar_multiget(path string, hrefs []string) ![]calbox.CalendarObject {
// 	// Get calendar collection
// 	cal := s.get_collection(path) or { return error('Calendar not found') }

// 	mut results := []calbox.CalendarObject{}

// 	// Get requested resources
// 	for href in hrefs {
// 		obj_path := href.all_after(path)
// 		if obj := cal.get_by_uid(obj_path) {
// 			results << obj
// 		}
// 	}

// 	return results
// }

// // Handles a free-busy-query REPORT request
// pub fn (s App) handle_freebusy_query(path string, tr calbox.TimeRange) ![]calbox.TimeRange {
// 	// Get calendar collection
// 	cal := s.get_collection(path) or { return error('Calendar not found') }

// 	// Get free/busy info
// 	return cal.get_freebusy(tr)
// }

// // Filter for calendar-query REPORT
// pub struct CalendarQueryFilter {
// pub mut:
// 	time_range ?calbox.TimeRange
// 	comp_type  string
// 	prop_name  string
// 	text_match string
// }
