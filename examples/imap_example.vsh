#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.uhurulib.lib.mail.server

// Start the IMAP server on port 143
server.start_demo()!
