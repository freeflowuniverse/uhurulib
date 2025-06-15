
# IMAP LIST Command Specification (Plaintext)

This specification describes how an IMAP client can discover available mailboxes on the server using the LIST command. It explains the syntax, parameters, and server response format in a plaintext (unencrypted) context.

---

## 1. Overview

The LIST command is used by an IMAP client to obtain a directory‐like view of mailbox names available for the authenticated user. With LIST, a client may request:
- A complete list of mailboxes,
- Mailboxes that match a given pattern (including the use of wildcards),
- And, optionally, additional information (such as mailbox attributes and hierarchy delimiters).

When the server processes a LIST command, it returns one or more untagged responses—each describing a single mailbox (or mailbox-like entity).

---

## 2. Connection and State

- **State:**  
  The LIST command is valid when the client is in the Authenticated state (or in the Selected state). It is issued after a successful login.

- **Plaintext Context:**  
  All commands (including LIST) are transmitted in plaintext. No encryption is applied in this specification.

---

## 3. Command Syntax

### 3.1 Basic Syntax

The basic form of the LIST command is:

```
<tag> LIST <reference> <mailbox-pattern>
```

- `<tag>` is a client-generated identifier (e.g., A101) that is echoed by the server.
- `<reference>` is an astring that specifies the base reference for the mailbox name. In many cases, clients use an empty string (`""`) so that the mailbox pattern is interpreted relative to the root of the mailbox hierarchy.
- `<mailbox-pattern>` is an astring that may include wildcard characters:
  - The asterisk (`*`) matches zero or more characters (including hierarchy delimiters).
  - The percent sign (`%`) matches zero or more characters but does not cross the hierarchy delimiter.

### 3.2 Extended Syntax (Optional)

Some implementations support an extended version of LIST with selection and return options. In that case, the command may include additional parameters:
```
<tag> LIST (selection-options) <reference> <mailbox-pattern> RETURN (return-options)
```
For the purpose of this specification, only the basic form is required. (Extended options are omitted here.)

---

## 4. Detailed Command Parameters

### 4.1 The Reference Parameter

- **Purpose:**  
  The reference parameter provides a context in which the mailbox-pattern is interpreted.
- **Usage:**  
  - An empty string (`""`) is common, meaning that the pattern is interpreted from the top of the hierarchy.
  - When a non-empty reference is provided, the server concatenates it (taking into account hierarchy delimiters) with the mailbox pattern to form the canonical mailbox name.

### 4.2 The Mailbox-Pattern Parameter

- **Purpose:**  
  The mailbox pattern determines which mailboxes are returned.
- **Wildcards:**  
  - `*` matches all characters (and may span across hierarchy levels).
  - `%` matches all characters except the hierarchy delimiter, which is used to indicate the immediate level only.

- **Example Patterns:**  
  - `"*"` returns all mailboxes.
  - `"INBOX*"` returns mailboxes whose names begin with “INBOX”.
  - `"INBOX/%"` returns immediate sub-mailboxes of the INBOX.

---

## 5. Server Response Format

When processing a LIST command, the server sends one or more untagged responses with the following format:

```
* LIST (<mailbox-attributes>) "<hierarchy-delimiter>" <mailbox-name>
```

### 5.1 Mailbox Attributes

- **Examples of Attributes:**  
  - `\Noselect`: Indicates that the mailbox cannot be selected (for example, it is a container for other mailboxes).
  - `\HasChildren`: Indicates that the mailbox has subordinate (child) mailboxes.
  - `\HasNoChildren`: Indicates that the mailbox does not have any subordinate mailboxes.
  - `\Subscribed`: Indicates that the mailbox is one to which the user has subscribed.
  - `\Remote`: Indicates that the mailbox is hosted on another server (if applicable).

- **Note:**  
  The attributes inform the client how the mailbox may be used (for example, whether it can be opened or if it is just a hierarchical container).

### 5.2 Hierarchy Delimiter

- **Definition:**  
  The hierarchy delimiter is a character (commonly `/` or `.`) that separates levels in a mailbox hierarchy.
- **Special Case:**  
  A NIL delimiter means that there is no hierarchy (i.e., the mailbox names are flat).

### 5.3 Mailbox Name

- **Description:**  
  This is the canonical name of the mailbox, after interpreting the reference and pattern.
- **Example:**  
  A response might indicate a mailbox name as `"INBOX"` or `"Mail/Work"`.

### 5.4 Tagged Completion Response

After all matching mailboxes have been listed, the server returns a tagged response (using the same tag as in the command) to indicate that the LIST command has completed successfully:

```
<tag> OK LIST completed
```

---

## 6. Example Transaction

### Example 1: Listing All Mailboxes

1. **Client Command:**
   ```
   A101 LIST "" "*"
   ```

2. **Server Responses:**
   ```
   * LIST (\HasChildren) "/" "INBOX"
   * LIST () "/" "Drafts"
   * LIST (\Noselect) "/" "Archive"
   * LIST () "/" "Mail/Work"
   A101 OK LIST completed
   ```

- **Explanation:**  
  - The client issues a LIST command with an empty reference and the pattern `"*"`.
  - The server returns several untagged LIST responses:
    - The INBOX mailbox is marked as having children.
    - The Archive mailbox is marked with `\Noselect`, indicating it is a container.
    - Other mailboxes are returned with their respective attributes and hierarchy delimiters.
  - Finally, the server sends a tagged OK response to indicate completion.

### Example 2: Listing Sub-Mailboxes of INBOX

1. **Client Command:**
   ```
   A102 LIST "INBOX" "%"
   ```

2. **Server Responses:**
   ```
   * LIST () "/" "INBOX/Personal"
   * LIST () "/" "INBOX/Work"
   A102 OK LIST completed
   ```

- **Explanation:**  
  - The reference is set to `"INBOX"`, and the pattern is `"%"` which returns only the immediate sub-mailboxes.
  - The server lists two sub-mailboxes under INBOX.
  - The tagged response confirms the command’s successful completion.

---

## 7. Implementation Notes

- **Whitespace and Formatting:**  
  The command must be constructed exactly as specified. A single space (SP) must separate the command and parameters; the command line must be terminated by CRLF.
  
- **Parsing the Response:**  
  Clients should parse the untagged LIST responses to extract:
  - The set of mailbox attributes (which may affect whether the mailbox can be selected).
  - The hierarchy delimiter (to allow the client to construct or display the mailbox hierarchy).
  - The canonical mailbox name.
  
- **Error Handling:**  
  If the LIST command fails (for example, due to a syntax error), the server will respond with a tagged NO or BAD response. The client should handle such errors appropriately.

---

## 8. Summary

- **Purpose:**  
  The LIST command allows a client to request a list of mailbox names from the server, filtered by a reference and a mailbox pattern.

- **Syntax:**  
  The basic command format is:  
  ```
  <tag> LIST <reference> <mailbox-pattern>
  ```
  with the reference and mailbox pattern provided as astrings, supporting wildcards such as `*` and `%`.

- **Server Responses:**  
  For each matching mailbox, the server returns an untagged LIST response that includes mailbox attributes, the hierarchy delimiter, and the mailbox name. The command concludes with a tagged OK response.

- **Usage Example:**  
  To list all mailboxes, a client might issue:  
  ```
  A101 LIST "" "*"
  ```
  which the server answers with a set of untagged LIST responses followed by a completion response.

By following these guidelines, an IMAP client can correctly implement the LIST command to retrieve a directory of mailboxes from an IMAP server over a plaintext connection.

