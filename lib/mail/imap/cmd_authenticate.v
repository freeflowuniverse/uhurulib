module imap

import net
import io
import freeflowuniverse.herolib.ui.console
import encoding.base64

// handle_authenticate processes the AUTHENTICATE command
pub fn (mut self Session) handle_authenticate(tag string, cmd_parts []string) ! {
	if cmd_parts.len < 3 {
		self.conn.write('${tag} BAD AUTHENTICATE requires an authentication mechanism\r\n'.bytes())!
		return
	}
	auth_type := cmd_parts[2].to_upper()
	if auth_type == 'PLAIN' {
		mut creds := if cmd_parts.len > 3 {
			cmd_parts[3]
		} else {
			// Send continuation request for credentials
			self.conn.write('+\r\n'.bytes())!
			// Read base64 credentials
			self.reader.read_line() or {
				match err.msg() {
					'closed' {
						console.print_debug('Client disconnected during authentication')
						return error('client disconnected during auth')
					}
					'EOF' {
						console.print_debug('Client ended connection during authentication (EOF)')
						return error('connection ended during auth')
					}
					else {
						eprintln('Connection read error during authentication: ${err}')
						return error('connection error during auth: ${err}')
					}
				}
			}
		}
		if creds.len > 0 {
			// Decode base64 credentials
			decoded := base64.decode_str(creds)
			if decoded.len == 0 {
				self.conn.write('${tag} NO Invalid base64 encoding\r\n'.bytes())!
				return
			}

			// AUTH=PLAIN format: [authzid]\0authcid\0password
			// authzid is optional and can be empty
			auth_parts := decoded.split('\0')
			if auth_parts.len < 3 {
				self.conn.write('${tag} NO Invalid AUTH=PLAIN format\r\n'.bytes())!
				return
			}

			// Extract authentication identity (username) and password
			// authzid := auth_parts[0] // Authorization identity (ignored for now)
			authcid := auth_parts[1] // Authentication identity (username)
			password := auth_parts[2] // Password

			// Try to find existing account by email
			email := '${authcid}@example.com'
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

			// Set the username in the session
			self.username = existing_username

			// After successful auth, remove STARTTLS and LOGINDISABLED capabilities
			self.capabilities = ['IMAP4rev2', 'AUTH=PLAIN']
			self.conn.write('${tag} OK [CAPABILITY IMAP4rev2 AUTH=PLAIN] Authentication successful\r\n'.bytes())!
		} else {
			self.conn.write('${tag} NO Authentication failed\r\n'.bytes())!
		}
	} else {
		self.conn.write('${tag} NO [ALERT] Unsupported authentication mechanism\r\n'.bytes())!
	}
}
