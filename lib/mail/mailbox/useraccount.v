module mailbox

import time

import crypto.bcrypt

// Represents a user account in the mail server
@[heap]
struct UserAccount {
mut:
	name          string
	description   string
	emails        []string
	password_hash string    // Hashed password for authentication
	mailboxes     map[string]&Mailbox // Map of mailbox name to mailbox instance
}

// Verifies user credentials
fn (self UserAccount) authenticate(password string) bool {
	// Verify password against stored hash
	bcrypt.compare_hash_and_password(password.bytes(), self.password_hash.bytes()) or {
		return false
	}
	
	return true
}

// Creates a new mailbox for the user account
fn (mut self UserAccount) create_mailbox(name string) !&Mailbox {
	if name in self.mailboxes {
		return error('Mailbox ${name} already exists')
	}

	mb := &Mailbox{
		name:         name
		uid_validity: u32(time.now().unix())
	}
	self.mailboxes[name] = mb
	return mb
}

// Gets a mailbox by name
fn (mut self UserAccount) get_mailbox(name string) !&Mailbox {
	if mailbox := self.mailboxes[name] {
		return mailbox
	}
	return error('Mailbox ${name} not found')
}

// Deletes a mailbox by name
fn (mut self UserAccount) delete_mailbox(name string) ! {
	if name !in self.mailboxes {
		return error('Mailbox ${name} not found')
	}
	self.mailboxes.delete(name)
}

// Lists all mailboxes for the user
fn (self UserAccount) list_mailboxes() []string {
	return self.mailboxes.keys()
}
