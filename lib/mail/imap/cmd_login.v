module imap

import net

// handle_login processes the LOGIN command
// See RFC 3501 Section 6.2.3
pub fn (mut self Session) handle_login(tag string, parts []string) ! {
	// Check if LOGINDISABLED is advertised
	if self.capabilities.contains('LOGINDISABLED') {
		self.conn.write('${tag} NO [PRIVACYREQUIRED] LOGIN disabled\r\n'.bytes())!
		return
	}

	if parts.len < 4 {
		self.conn.write('${tag} BAD LOGIN requires username and password\r\n'.bytes())!
		return
	}

	username := parts[2]
	password := parts[3]

	// Try to find existing account by email
	email := '${username}@example.com'
	existing_username := self.server.mailboxserver.account_find_by_email(email) or {
		self.conn.write('${tag} NO [AUTHENTICATIONFAILED] Account not found\r\n'.bytes())!
		return
	}

	// Authenticate the user
	auth_success := self.server.mailboxserver.authenticate(existing_username, password) or {
		self.conn.write('${tag} NO [AUTHENTICATIONFAILED] Authentication failed\r\n'.bytes())!
		return
	}

	if !auth_success {
		self.conn.write('${tag} NO [AUTHENTICATIONFAILED] Invalid credentials\r\n'.bytes())!
		return
	}

	self.username = existing_username

	// Update capabilities - remove LOGINDISABLED and STARTTLS after login
	self.capabilities = self.capabilities.filter(it != 'LOGINDISABLED' && it != 'STARTTLS')

	// Send OK response with updated capabilities
	self.conn.write('${tag} OK [CAPABILITY ${self.capabilities.join(' ')}] LOGIN completed\r\n'.bytes())!
}
