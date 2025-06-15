module server

import freeflowuniverse.uhurulib.lib.mail.mailbox
import freeflowuniverse.uhurulib.lib.mail.imap
import freeflowuniverse.uhurulib.lib.mail.smtp

pub fn start_demo() {
	// Create the server and initialize an example INBOX.

	mut mailboxserver := mailbox.new_with_demo_data()

	// Use new from imap module and use mailboxserver as input
	mut imap_server := imap.new(mailboxserver)
	mut smtp_server := smtp.new(mailboxserver)

	imap_server.start() or { panic(err) }
	smtp_server.start() or { panic(err) }

	println('servers started.')

	for { 
	}
}
