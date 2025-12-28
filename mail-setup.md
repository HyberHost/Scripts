# Mail Setup Guide (Linux Servers)

This document explains **two supported ways** to enable email sending from a Linux server:

1. **Direct delivery from the server itself** (no external SMTP relay)
2. **Delivery via an external SMTP server** (relay / smarthost)

Both approaches work with tools like `mail`, `mailx`, `sendmail`, and monitoring scripts (such as RAID alerts).

---

## 1. Direct Mail Delivery (Server → Recipient MX)

This method sends email **directly from your server to the recipient's mail server** using SMTP.

This is equivalent to how cPanel/Exim works by default.

### ✔ Characteristics

* No external SMTP provider
* No authentication
* Uses the server's IP address
* Likely to be marked as spam (expected for testing)
* Best for **internal alerts, testing, or isolated environments**

---

### 1.1 Install Postfix and mail utilities

```bash
apt update
apt install postfix mailutils
```

During installation (or via reconfiguration), choose:

* **General type of mail configuration:** `Internet Site`
* **System mail name:** your hostname (e.g. `server.example.com`)

If Postfix was already installed but not configured:

```bash
dpkg-reconfigure postfix
```

---

### 1.2 Start and verify Postfix

```bash
systemctl restart postfix
systemctl status postfix
```

You should see:

```
Active: active (running)
```

---

### 1.3 Test direct mail sending

```bash
echo "Direct mail test from $(hostname)" | \
mail -s "Mail test" you@example.com
```

Check logs:

```bash
tail -f /var/log/mail.log
```

Expected behaviour:

* Postfix looks up recipient MX
* Attempts SMTP delivery
* Mail may be delayed, spam-filtered, or rejected — **this is still success**

---

### 1.4 Common issues (direct delivery)
#### Port 25 blocked

Some hosting providers block outbound traffic on port 25 by default, which prevents direct mail delivery.  
**HyberHost** does **not** block port 25 for new customers. We only restrict it if an IP address generates abuse complaints, ensuring responsible use while allowing direct mail for testing and alerts.

Test:

```bash
nc -vz gmail-smtp-in.l.google.com 25
```

If blocked, direct delivery will fail.

#### Reverse DNS mismatch

Not required for testing, but affects deliverability.

```bash
hostname -f
```

---

### 1.5 Recommended usage

✔ Monitoring alerts (RAID, disk, uptime)
✔ Internal systems
✔ Temporary testing

❌ Transactional or user-facing email

---

## 2. Sending Mail via an External SMTP Server (Relay)

This method relays all outgoing mail through a **third-party SMTP server**.

Examples:

* Google Workspace
* Microsoft 365
* Mailgun
* SendGrid
* ISP SMTP servers

---

### ✔ Characteristics

* Requires authentication
* Better deliverability
* Works even if port 25 is blocked
* Recommended for production alerts

---

## 2.1 Option A: Postfix with SMTP relay

### Install Postfix

```bash
apt install postfix mailutils
```

Choose:

* **General type:** `Internet Site`

---

### Configure relay settings

Edit:

```bash
nano /etc/postfix/main.cf
```

Add or modify:

```ini
relayhost = [smtp.example.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

---

### Create SMTP credentials

```bash
nano /etc/postfix/sasl_passwd
```

Format:

```
[smtp.example.com]:587 username:password
```

Secure and apply:

```bash
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
systemctl restart postfix
```

---

### Test

```bash
echo "Relay test" | mail -s "SMTP relay test" you@example.com
```

---

## 2.2 Option B: msmtp (lightweight, no daemon)

This is ideal for **simple alerting scripts**.

### Install

```bash
apt install msmtp msmtp-mta
```

---

### Configure `/etc/msmtprc`

```ini
defaults
auth           on
tls            on
logfile        /var/log/msmtp.log

account relay
host smtp.example.com
port 587
user username
password password
from alerts@example.com

account default : relay
```

Secure it:

```bash
chmod 600 /etc/msmtprc
```

---

### Test

```bash
echo "msmtp test" | mail -s "msmtp test" you@example.com
```

---

## 3. Choosing the Right Method

| Use case                 | Recommended method        |
| ------------------------ | ------------------------- |
| Quick testing            | Direct delivery (Postfix) |
| RAID / system alerts     | Direct or relay           |
| VPS with blocked port 25 | SMTP relay                |
| Production alerting      | SMTP relay                |
| No daemon wanted         | msmtp                     |

---

## 4. How This Integrates with Scripts

All methods above support:

```bash
echo "message" | mail -s "subject" recipient@example.com
```

Which means **no script changes are required**.

Your monitoring scripts only need:

* `mail` binary
* A working MTA or relay

---

## 5. Troubleshooting

Check logs:

```bash
tail -f /var/log/mail.log
```

Check sendmail path:

```bash
which sendmail
```

Check Postfix config:

```bash
postconf -n
```