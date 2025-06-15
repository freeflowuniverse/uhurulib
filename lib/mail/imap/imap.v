module imap

import freeflowuniverse.uhurulib.lib.mail.mailbox

// new creates a new IMAP server with the given mailbox server
pub fn new(mailboxserver &mailbox.MailServer) &IMAPServer {
	mut server := &IMAPServer{
		mailboxserver: mailboxserver
	}
	return server
}
