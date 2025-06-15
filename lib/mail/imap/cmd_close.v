module imap

import freeflowuniverse.uhurulib.lib.mail.mailbox

// handle_close processes the CLOSE command
// See RFC 3501 Section 6.4.1
pub fn (mut self Session) handle_close(tag string) ! {
	// If no mailbox is selected, return error
	if self.mailbox == '' {
		self.conn.write('${tag} NO No mailbox selected\r\n'.bytes())!
		return
	}

	// Get all messages in the mailbox
	messages := self.server.mailboxserver.message_list(self.username, self.mailbox) or {
		self.conn.write('${tag} NO Failed to list messages: ${err}\r\n'.bytes())!
		return
	}

	// Delete messages with \Deleted flag
	for msg in messages {
		for flag in msg.flags {
			if flag == '\\Deleted' {
				self.server.mailboxserver.message_delete(self.username, self.mailbox, msg.uid) or {
					eprintln('Failed to delete message ${msg.uid}: ${err}')
					continue
				}
				break
			}
		}
	}

	// Clear selected mailbox
	self.mailbox = ''

	self.conn.write('${tag} OK CLOSE completed\r\n'.bytes())!
}
