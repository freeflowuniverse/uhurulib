
# IMAP STORE Command Specification (Plaintext)

The STORE command allows an IMAP client to modify the flags associated with one or more messages. Flags may be system flags (e.g. \Seen, \Answered, \Flagged, \Deleted, \Draft) or user-defined keywords. In this plaintext specification, we describe the command syntax, parameters, server responses, and processing behavior.

---

## 1. Overview

- **Purpose:**  
  The STORE command is used to alter the state of messages by changing their flags. It can either replace the existing flag set or modify it by adding or removing specific flags.

- **Use Cases:**  
  - Marking a message as read or unread (setting or clearing the \Seen flag).  
  - Flagging a message as important (using the \Flagged flag).  
  - Marking messages for deletion (using the \Deleted flag).  
  - Changing other state attributes in the mailbox.

- **State Transition:**  
  The STORE command is only valid in the Selected state (i.e. after a successful SELECT or EXAMINE command).

---

## 2. Command Syntax

### 2.1 Basic Command Format

The general syntax for the STORE command is:

```
<tag> STORE <sequence-set> <store-att-flags>
```

- **`<tag>`:**  
  A client-generated identifier (e.g., A003) used to correlate the command with the server response.

- **`<sequence-set>`:**  
  A set of message sequence numbers identifying which messages to update. This can be a single number, a range (e.g. `2:4`), or a list (e.g. `2,4,7`).

- **`<store-att-flags>`:**  
  The data item that specifies how the flags are to be changed. This includes the flag operation (replace, add, or remove), an optional “.SILENT” suffix to suppress automatic untagged FETCH responses, and a flag list (or an inline list of flags).

### 2.2 Flag Operation Variants

There are three forms of STORE operations:

1. **Replace Flags:**  
   ```
   STORE <sequence-set> FLAGS <flag-list>
   ```  
   This replaces the current flags with the given flag list.

2. **Add Flags:**  
   ```
   STORE <sequence-set> +FLAGS <flag-list>
   ```  
   This adds the specified flags to the current flag set.

3. **Remove Flags:**  
   ```
   STORE <sequence-set> -FLAGS <flag-list>
   ```  
   This removes the specified flags from the current flag set.

For each operation, the client can append the suffix `.SILENT` (e.g. `+FLAGS.SILENT`) to indicate that the server should not send untagged FETCH responses reflecting the change.

---

## 3. Detailed Format and Examples

### 3.1 Syntax Details

- **Flag List:**  
  The `<flag-list>` is enclosed in parentheses and contains one or more flag names separated by spaces.  
  _Example:_  
  ```
  (\Seen \Flagged)
  ```

- **Example – Replace Flags:**  
  ```
  A004 STORE 2:4 FLAGS (\Seen \Answered)
  ```  
  This command replaces the flags for messages 2, 3, and 4 with the flags \Seen and \Answered.

- **Example – Add Flags:**  
  ```
  A005 STORE 5 +FLAGS (\Flagged)
  ```  
  This command adds the \Flagged flag to message 5.

- **Example – Remove Flags with SILENT:**  
  ```
  A006 STORE 7 -FLAGS.SILENT (\Deleted)
  ```  
  This command removes the \Deleted flag from message 7 without causing the server to send untagged FETCH responses.

### 3.2 Command Line Formatting

- All commands and responses are ASCII text lines ending with a CRLF.
- There must be exactly one space (SP) between the command, parameters, and keywords.
- The command tag (e.g. `A004`) allows the client to match the final tagged response with its command.

---

## 4. Server Response Behavior

### 4.1 Normal Response

When the STORE command is processed:
- **Without .SILENT:**  
  The server typically issues one or more untagged FETCH responses showing the updated flag state for each message affected.  
  _Example:_  
  ```
  * 2 FETCH (FLAGS (\Seen \Answered))
  * 3 FETCH (FLAGS (\Seen \Answered))
  * 4 FETCH (FLAGS (\Seen \Answered))
  A004 OK STORE completed
  ```

- **With .SILENT:**  
  If the operation uses the `.SILENT` variant, the server does not send the untagged FETCH responses. The server only returns the final tagged response.  
  _Example:_  
  ```
  A006 OK STORE completed
  ```

### 4.2 Error Responses

- If the command syntax is incorrect, or if the specified `<sequence-set>` or `<flag-list>` is invalid, the server will return a BAD response.  
- If the operation cannot be performed (for example, due to permission restrictions), the server returns a NO response along with an optional response code that explains the error (e.g., `[NOPERM]`).

---

## 5. Detailed Transaction Flow

Below is an example session for each STORE variant:

### Example 1: Replacing Flags for a Set of Messages

1. **Client Command:**
   ```
   A004 STORE 2:4 FLAGS (\Seen \Answered)
   ```

2. **Server Responses:**
   ```
   * 2 FETCH (FLAGS (\Seen \Answered))
   * 3 FETCH (FLAGS (\Seen \Answered))
   * 4 FETCH (FLAGS (\Seen \Answered))
   A004 OK STORE completed
   ```

### Example 2: Adding a Flag (without SILENT)

1. **Client Command:**
   ```
   A005 STORE 5 +FLAGS (\Flagged)
   ```

2. **Server Responses:**
   ```
   * 5 FETCH (FLAGS (\Seen \Flagged))
   A005 OK STORE completed
   ```

### Example 3: Removing a Flag Using SILENT

1. **Client Command:**
   ```
   A006 STORE 7 -FLAGS.SILENT (\Deleted)
   ```

2. **Server Response:**  
   (No untagged FETCH responses are sent)
   ```
   A006 OK STORE completed
   ```

---

## 6. Implementation Notes

- **State Requirements:**  
  The STORE command is valid only when a mailbox is selected (i.e., the connection is in the Selected state). It applies only to messages within the selected mailbox.

- **Flag Persistence:**  
  Changes made using the STORE command are persistent; subsequent sessions or commands (such as FETCH) will reflect the updated flag state.

- **SILENT Modifier:**  
  Using the `.SILENT` suffix suppresses the untagged FETCH response. Clients may choose to use SILENT if they already maintain a local view of the mailbox flags or wish to reduce network traffic.

- **Sequence Set Interpretation:**  
  The `<sequence-set>` must be interpreted according to the current state of the mailbox (i.e., based on message sequence numbers). The client must ensure that the numbers reference the correct messages.

- **Error Handling:**  
  If the command fails (for instance, if the user lacks permission to modify flags), the server returns a tagged NO or BAD response. The client should handle these errors by informing the user or retrying as appropriate.

---

## 7. Summary

- **Purpose:**  
  The STORE command allows an IMAP client to modify the flags of messages in the selected mailbox.

- **Syntax:**  
  The command is structured as:
  ```
  <tag> STORE <sequence-set> <store-att-flags>
  ```
  with operations for replacing flags (FLAGS), adding flags (+FLAGS), or removing flags (-FLAGS). The optional `.SILENT` suffix can be appended to suppress untagged FETCH responses.

- **Server Responses:**  
  - Without SILENT, the server sends untagged FETCH responses showing the updated flags for each message.
  - With SILENT, only a final tagged OK (or an error) is returned.
  - Error responses (NO or BAD) indicate failure conditions.

- **Operational Impact:**  
  On success, the flag state of the messages is updated and persists for subsequent operations.
