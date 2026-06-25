"""Outgoing email via Gmail SMTP (implicit SSL on port 465).

Fails loudly: if SMTP credentials are not configured, attempting to send
raises rather than silently swallowing the message.
"""

import smtplib
from email.message import EmailMessage

from app.config import get_settings

settings = get_settings()


def send_email(to: str, subject: str, body: str) -> None:
    if not settings.smtp_user or not settings.smtp_password:
        raise RuntimeError(
            "SMTP is not configured. Set SMTP_USER and SMTP_PASSWORD "
            "(a Gmail App Password) in backend/.env before sending email."
        )

    message = EmailMessage()
    message["From"] = f"{settings.email_from_name} <{settings.email_from}>"
    message["To"] = to
    message["Subject"] = subject
    message.set_content(body)

    with smtplib.SMTP_SSL(settings.smtp_host, settings.smtp_port) as server:
        server.login(settings.smtp_user, settings.smtp_password)
        server.send_message(message)


def send_otp_email(to: str, name: str, code: str) -> None:
    subject = "Your SiteLedger verification code"
    body = (
        f"Hi {name},\n\n"
        f"Your SiteLedger verification code is: {code}\n\n"
        f"It expires in {settings.otp_expiry_minutes} minutes. "
        "Enter it on the sign-in screen to verify your email.\n\n"
        "If you did not request this, you can ignore this message.\n\n"
        "— SiteLedger"
    )
    send_email(to, subject, body)
