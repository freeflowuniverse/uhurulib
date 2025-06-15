
# IMAP FETCH Command Specification (Plaintext)

The FETCH command is used by an IMAP client to retrieve data associated with one or more messages from the currently selected mailbox. It can return static message information (such as flags, internal date, size, envelope, and UID) as well as dynamic message content (such as message bodies or specific MIME parts).

---

## 1. Overview

- **Purpose:**  
  The FETCH command allows a client to request specific pieces of data for one or more messages. This includes details such as:
  - **Message Flags:** e.g., \Seen, \Answered, \Flagged, etc.
  - **Internal Date:** The server’s recorded date for the message.
  - **RFC822.SIZE:** The size (in octets) of the entire message.
  - **Envelope:** Parsed header fields (e.g., From, To, Subject, Date).
  - **Body Structure:** The MIME structure of the message.
  - **Body Sections:** Full or partial text of the message, or specific parts such as headers only.
  - **UID:** The unique identifier for the message.

- **Connection State:**  
  The FETCH command is valid only in the Selected state. That is, after a mailbox has been successfully opened with a SELECT or EXAMINE command.

- **Plaintext Context:**  
  In this specification, all communication (including the FETCH command and its responses) occurs over a plaintext connection.

---

## 2. Command Syntax

### 2.1 Basic Format

The general syntax for the FETCH command is as follows:

```
<tag> FETCH <sequence-set> <data-item-list>
```

- **`<tag>`:**  
  A client-generated identifier (e.g., A103) that will be echoed back in the server’s final tagged response.

- **`<sequence-set>`:**  
  A set of message sequence numbers that identifies which messages the client wants to fetch. This may be a single number (e.g., 3), a range (e.g., 2:4), or a comma-separated list (e.g., 2,5,7).

- **`<data-item-list>`:**  
  A list of one or more message data items (or macros) enclosed in parentheses. Each data item specifies the type of information the client wishes to retrieve.

### 2.2 Data Items and Macros

#### Common Data Items
- **FLAGS:**  
  Returns the current flags for the message.
  
- **INTERNALDATE:**  
  Returns the internal date value that the server uses for the message.
  
- **RFC822.SIZE:**  
  Returns the size in octets of the message in [RFC5322] format.
  
- **ENVELOPE:**  
  Returns the envelope structure containing the parsed header fields.
  
- **BODYSTRUCTURE:**  
  Returns a parsed representation of the MIME body structure.
  
- **UID:**  
  Returns the unique identifier for the message.

#### Body Fetching
- **BODY[<section>]<<partial>>:**  
  Retrieves the body of the message or a specified section.  
  - `<section>` specifies a particular part of the message (e.g., `HEADER`, `TEXT`, `HEADER.FIELDS (Date From)`).  
  - The optional `<partial>` specifier (in the format `<start>.<max>`) allows the client to request a substring of the data.
  
- **BODY.PEEK[<section>]<<partial>>:**  
  Works like BODY[...] but does not automatically set the \Seen flag.
  
- **BINARY[<section-binary>]<<partial>>:**  
  For retrieving a body part after decoding its Content-Transfer-Encoding. A corresponding `BINARY.PEEK` variant is available if no flag update is desired.

#### Macros
- **ALL:**  
  A macro equivalent to retrieving: `(FLAGS INTERNALDATE RFC822.SIZE ENVELOPE)`.
  
- **FAST:**  
  A macro equivalent to: `(FLAGS INTERNALDATE RFC822.SIZE)`.
  
- **FULL:**  
  A macro equivalent to: `(FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY)`.

*Note:* The client can request one or more of these data items in any combination.

### 2.3 Example Command

```
A103 FETCH 2:4 (FLAGS INTERNALDATE RFC822.SIZE ENVELOPE UID)
```

This command asks the server to return for messages 2 through 4:
- Their current flags
- The internal date
- The size of the message
- The envelope structure
- The UID for each message

---

## 3. Server Response Format

When processing a FETCH command, the server returns a series of untagged responses—one for each message in the specified sequence set. Each response follows this format:

```
* <msg-number> FETCH (<data-item1> <value1> <data-item2> <value2> ... )
```

- **`<msg-number>`:**  
  The message sequence number of the fetched message.

- **Data Items and Values:**  
  Each data item specified in the FETCH command appears in the response, followed by its corresponding value.

### 3.1 Example Response

For the example command given above, a server response might be:

```
* 2 FETCH (FLAGS (\Seen) INTERNALDATE "17-Jul-1996 02:44:25 -0700" RFC822.SIZE 4286 ENVELOPE ("Wed, 17 Jul 1996 02:23:25 -0700" "Meeting Notes" (("Alice" NIL "alice" "example.com")) (("Alice" NIL "alice" "example.com")) (("Alice" NIL "alice" "example.com")) (NIL NIL "imap" "example.com") NIL NIL "<msgid1@example.com>") UID 4827313)
* 3 FETCH (FLAGS (\Answered \Seen) INTERNALDATE "17-Jul-1996 02:50:00 -0700" RFC822.SIZE 5230 ENVELOPE ("Wed, 17 Jul 1996 02:45:00 -0700" "Project Update" (("Bob" NIL "bob" "example.com")) (("Bob" NIL "bob" "example.com")) (("Bob" NIL "bob" "example.com")) (NIL NIL "imap" "example.com") NIL NIL "<msgid2@example.com>") UID 4827314)
* 4 FETCH (FLAGS (\Draft) INTERNALDATE "17-Jul-1996 03:00:00 -0700" RFC822.SIZE 3100 ENVELOPE ("Wed, 17 Jul 1996 02:55:00 -0700" "Draft Message" (("Carol" NIL "carol" "example.com")) (("Carol" NIL "carol" "example.com")) (("Carol" NIL "carol" "example.com")) (NIL NIL "imap" "example.com") NIL NIL "<msgid3@example.com>") UID 4827315)
A103 OK FETCH completed
```

- Each untagged FETCH response begins with `*` followed by the message sequence number.
- Data items are enclosed in parentheses.
- The final tagged response (with the same tag as the command, here `A103`) confirms completion.

---

## 4. Partial Fetches and Special Fetch Items

### 4.1 Partial Fetches

- **Partial Fetch Syntax:**  
  To fetch only a part of a body section, a partial specifier may be appended. For example:
  ```
  BODY[TEXT]<0.2048>
  ```
  This requests up to 2048 octets of the TEXT portion starting from the beginning.

- **Behavior:**  
  If the starting octet is beyond the end of the body, the server returns an empty string. If the range extends beyond the body’s length, the server truncates the result to the available data.

### 4.2 PEEK Variant

- **BODY.PEEK:**  
  When a client uses BODY.PEEK instead of BODY, the message’s \Seen flag is not automatically set. This is useful for previewing message content without marking it as read.

---

## 5. Detailed Transaction Flow

Below is an example transaction using the FETCH command:

1. **Client Sends FETCH Command:**
   ```
   A103 FETCH 2:4 (FLAGS INTERNALDATE RFC822.SIZE ENVELOPE UID)
   ```

2. **Server Responds with Data for Each Message:**
   - For message 2:
     ```
     * 2 FETCH (FLAGS (\Seen) INTERNALDATE "17-Jul-1996 02:44:25 -0700" RFC822.SIZE 4286 ENVELOPE ("Wed, 17 Jul 1996 02:23:25 -0700" "Meeting Notes" (("Alice" NIL "alice" "example.com")) (("Alice" NIL "alice" "example.com")) (("Alice" NIL "alice" "example.com")) (NIL NIL "imap" "example.com") NIL NIL "<msgid1@example.com>") UID 4827313)
     ```
   - For message 3:
     ```
     * 3 FETCH (FLAGS (\Answered \Seen) INTERNALDATE "17-Jul-1996 02:50:00 -0700" RFC822.SIZE 5230 ENVELOPE ("Wed, 17 Jul 1996 02:45:00 -0700" "Project Update" (("Bob" NIL "bob" "example.com")) (("Bob" NIL "bob" "example.com")) (("Bob" NIL "bob" "example.com")) (NIL NIL "imap" "example.com") NIL NIL "<msgid2@example.com>") UID 4827314)
     ```
   - For message 4:
     ```
     * 4 FETCH (FLAGS (\Draft) INTERNALDATE "17-Jul-1996 03:00:00 -0700" RFC822.SIZE 3100 ENVELOPE ("Wed, 17 Jul 1996 02:55:00 -0700" "Draft Message" (("Carol" NIL "carol" "example.com")) (("Carol" NIL "carol" "example.com")) (("Carol" NIL "carol" "example.com")) (NIL NIL "imap" "example.com") NIL NIL "<msgid3@example.com>") UID 4827315)
     ```

3. **Server Sends Final Tagged Response:**
   ```
   A103 OK FETCH completed
   ```

---

## 6. Implementation Notes

- **State Requirement:**  
  The FETCH command is valid only when a mailbox is already selected (Selected state). The `<sequence-set>` refers to message sequence numbers in the currently selected mailbox.

- **Data Consistency:**  
  Static data items (e.g., INTERNALDATE, RFC822.SIZE, ENVELOPE, UID) must not change during a session, whereas dynamic items (e.g., FLAGS) may update over time.

- **Macro Usage:**  
  Instead of listing individual data items, clients may use macros such as ALL, FAST, or FULL:
  - **ALL** returns: `(FLAGS INTERNALDATE RFC822.SIZE ENVELOPE)`
  - **FAST** returns: `(FLAGS INTERNALDATE RFC822.SIZE)`
  - **FULL** returns: `(FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY)`

- **Parsing Responses:**  
  The client must correctly parse each untagged FETCH response to extract the message sequence number and the corresponding data items. Each data item will be provided as part of a parenthesized list.

- **Error Handling:**  
  If the FETCH command is malformed or if the requested data item is not available, the server will return a tagged NO or BAD response. The client should handle such errors appropriately.

---

## 7. Summary

- **Purpose:**  
  The FETCH command retrieves specific data items from one or more messages in the selected mailbox.

- **Syntax:**  
  ```
  <tag> FETCH <sequence-set> <data-item-list>
  ```
  where `<data-item-list>` may include items such as FLAGS, INTERNALDATE, RFC822.SIZE, ENVELOPE, BODY, BODY.PEEK, BODYSTRUCTURE, UID, and macros like ALL, FAST, or FULL.

- **Server Responses:**  
  The server returns an untagged FETCH response for each message in the sequence set, followed by a final tagged response. Each FETCH response provides the requested data items.

- **Usage Considerations:**  
  - Use BODY.PEEK if you do not wish to mark the message as read.
  - Use partial fetch specifiers to limit the amount of data retrieved from large messages.
  - The FETCH command is only valid in the Selected state.

