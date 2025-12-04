from django.core.mail import send_mail
from django.conf import settings

def send_otp_email(email, code):
    subject = "CreativeBook Email Verification"
    message = f"Your verification code is: {code}"
    send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [email])
