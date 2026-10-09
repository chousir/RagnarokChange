class_name MessageIds
extends RefCounted
## Ids of the messages the server sends; the server sends only the id and its
## parameters (docs/02-networking.md SystemMessage, HelloResult). The client shows
## the text from locale/ (docs/03-data-formats.md section 7), and a test checks that
## every constant here has English and Traditional Chinese text.

## Login rejection reasons (docs/02-networking.md section 5).
const LOGIN_VERSION_MISMATCH := "msg.login.version_mismatch"
const LOGIN_DATA_MISMATCH := "msg.login.data_mismatch"
const LOGIN_SERVER_FULL := "msg.login.server_full"
const LOGIN_WRONG_PASSWORD := "msg.login.wrong_password"
const LOGIN_IP_BLOCKED := "msg.login.ip_blocked"
const LOGIN_SERVER_CLOSING := "msg.login.server_closing"
