module smtp

import freeflowuniverse.uhurulib.lib.mail.mailbox

pub fn new(mailboxserver &mailbox.MailServer) !SMTPServer {
	mut server := SMTPServer{
		mailboxserver: mailboxserver
	}
	return server
}
