module smtp

import freeflowuniverse.uhurulib.lib.mail.mailbox

// new creates a new SMTP server with the given mailbox server
pub fn new(mailboxserver &mailbox.MailServer) &SMTPServer {
	mut server := &SMTPServer{
		mailboxserver: mailboxserver
	}
	return server
}
