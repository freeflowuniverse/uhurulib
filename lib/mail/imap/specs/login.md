
# IMAP Login Specification (Plaintext)

This document describes in detail how an IMAP client can log in to an IMAP server using the LOGIN command. The procedure outlined here assumes that the connection is made over an unencrypted (plaintext) channel.

---

## 1. Overview

Before accessing any mailbox data, the client must authenticate with the IMAP server. The LOGIN command is one of the two primary authentication methods defined in the IMAP protocol. It uses a user name and password (both provided as textual strings) to identify the client. Once the server validates the credentials, the connection moves from the "Not Authenticated" state to the "Authenticated" state.

---

## 2. Establishing the Connection

- **TCP Connection:**  
  The client initiates a TCP connection to the IMAP server. In this specification, no encryption is applied; all communications, including login credentials, are transmitted in plaintext.

- **Server Greeting:**  
  After the connection is established, the server sends an untagged greeting message indicating that the service is ready.  
  _Example:_  
  ```
  * OK IMAP4rev2 Service Ready
  ```

---

## 3. The LOGIN Command

### 3.1 Command Syntax

The LOGIN command is used to authenticate by providing a user name and a password. The general syntax is as follows:

```
LOGIN <userid> <password>
```

- **Parameters:**
  - `<userid>`: The user name (or login identifier) for the account.
  - `<password>`: The password associated with the account.

Both parameters are expressed as *astrings*, which means they can be provided either as atoms or as quoted strings.

### 3.2 Detailed Format

- **Command Line:**  
  The LOGIN command is sent as a single line that is terminated by a CRLF (Carriage Return and Line Feed). There must be a space between the command and each parameter.

- **Example Command:**  
  ```
  A003 LOGIN "user@example.com" "p@ssw0rd"
  ```
  Here, `A003` is a client-generated tag used to match the server’s response with the command.

### 3.3 Server Response

After the LOGIN command is received and processed:

- **Successful Authentication:**  
  If the credentials are correct, the server returns a tagged OK response indicating that the login has completed successfully.  
  _Example:_  
  ```
  A003 OK LOGIN completed
  ```

- **Failed Authentication:**  
  If the credentials are incorrect, the server returns a tagged NO response, often including a response code (e.g., `[AUTHENTICATIONFAILED]`) and a brief message explaining the error.  
  _Example:_  
  ```
  A003 NO [AUTHENTICATIONFAILED] Invalid username or password
  ```

- **Capabilities Update:**  
  On successful login, the server may include additional capability information in its response, updating the client with features that are now available once authentication is complete.

---

## 4. Detailed Transaction Flow

The following step-by-step sequence demonstrates a typical IMAP login session using the LOGIN command over a plaintext connection:

1. **Connection Establishment:**
   - The client opens a TCP connection to the server.
   - The server sends a greeting:
     ```
     S: * OK IMAP4rev2 Service Ready
     ```

2. **LOGIN Command:**
   - The client sends the LOGIN command with the desired user name and password:
     ```
     C: A003 LOGIN "user@example.com" "p@ssw0rd"
     ```

3. **Server Authentication Response:**
   - If the credentials are accepted, the server replies with:
     ```
     S: A003 OK LOGIN completed
     ```
   - If the credentials are rejected, the server replies with an error message such as:
     ```
     S: A003 NO [AUTHENTICATIONFAILED] Invalid username or password
     ```

4. **Post-Login State:**
   - Once the server responds with an OK, the client is now in the "Authenticated" state.
   - At this point, the client may issue further commands (such as SELECT, LIST, etc.) to access and manipulate mailbox data.

---

## 5. Implementation Notes

- **Plaintext Transmission:**  
  Since the LOGIN command transmits credentials as plaintext, caution must be taken. This specification assumes that the environment is controlled or that other measures (such as physical network isolation) are in place, because no transport-layer encryption is applied.

- **Tag Management:**  
  Every client command is prefixed by a unique tag (e.g., A003). The server's response will include the same tag, which the client uses to correlate the response with its original command.

- **Protocol Compliance:**  
  Clients must follow the strict syntax defined by the IMAP specification. Any deviations (such as extra or missing spaces) may result in a protocol error.

- **Error Handling:**  
  When a NO response is received, the client should report the error and may prompt the user to re-enter credentials or take other appropriate actions.

---

## 6. Summary

To log in to an IMAP server using the LOGIN command over an unencrypted connection:

1. **Connect via TCP:** Establish a connection and receive the server's greeting.
2. **Send the LOGIN Command:** Use the syntax `LOGIN <userid> <password>`, ensuring that both parameters are provided as astrings.
3. **Process the Response:**  
   - An OK response indicates successful login.
   - A NO response indicates a failure; handle accordingly.
4. **Proceed to Further Operations:** Once authenticated, the client may proceed to select mailboxes and manage messages.

