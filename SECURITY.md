# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in `vigiar`, please
**do not open a public issue**.

Instead, send an email to the maintainer at the address listed in
the [DESCRIPTION](DESCRIPTION) file.

Please include:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge your report within 48 hours and work on a fix
as quickly as possible. We will credit you in the release notes
(unless you prefer to remain anonymous).

## Security Considerations

- `vigiar` interacts with the public Power BI "Publish to Web"
  endpoint. No authentication credentials are required or stored.
- Session cookies (`WFESessionId`, `ARRAffinity`) are held in
  memory only and are discarded when the R session ends or
  `vigiar_desconectar()` is called.
- No personal or identifiable data is collected by the package.
- Temporary files (gzip decompression) are cleaned up immediately
  after use via `on.exit()`.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.0   | :white_check_mark: |
