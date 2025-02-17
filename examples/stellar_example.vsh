#!/usr/bin/env -S v -n -w -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import hero_blockchain.blockchain.stellar

import freeflowuniverse.herolib.core

core.interactive_set()! //make sure the sudo works so we can do things even if it requires those rights

