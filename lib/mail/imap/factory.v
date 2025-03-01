module imap

import time
import freeflowuniverse.uhurulib.lib.mail.mailbox

pub fn new(mailboxserver &mailbox.MailServer) !IMAPServer {
	mut server := IMAPServer{
		mailboxserver: mailboxserver
	}

	return server
}
