from fastapi import FastAPI, HTTPException, BackgroundTasks, Path
import secrets
import asyncio
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from fastapi.middleware.cors import CORSMiddleware
import MySQLdb
from pydantic import BaseModel
import bcrypt
import uvicorn

db_config = {
    'host': 'localhost',
    'user': 'root',
    'passwd': '',
    'db': 'umslab',
}
class User(BaseModel):
    username: str
    password: str
    email: str
    role: str
    otp: int

conn = MySQLdb.connect(**db_config)
app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# OTP related...
async def remove_otp(email: str):
    await asyncio.sleep(300)  # Remove OTP after 5 minutes
    if email in otp_map:
        del otp_map[email]

otp_map = {}

def send_email(subject, message, to_email):
    try:
        # Set up the email server
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()

        # Replace 'YOUR_EMAIL_USERNAME' and 'YOUR_EMAIL_PASSWORD' with your actual email credentials
        email_username = '1901030@iot.bdu.ac.bd'
        email_password = ''

        server.login(email_username, email_password)

        # Create message
        msg = MIMEMultipart()
        msg['From'] = email_username
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(message, 'plain'))

        # Send the email
        server.sendmail(email_username, to_email, msg.as_string())
        print("Email sent successfully!")
    except smtplib.SMTPException as e:
        print(f"Failed to send email: {e}")
    finally:
        server.quit()

@app.post("/generate_otp/")
async def generate_otp(email: str):
    print(f"Received email: {email}")
    if '@' not in email or '.' not in email:
        raise HTTPException(status_code=400, detail="Invalid email format")

    otp = str(secrets.randbelow(900000) + 100000)  # Generate a 6-digit OTP
    otp_map[email] = otp
    asyncio.create_task(remove_otp(email))
    send_email("User Verification", f"Your OTP is: {otp}", email)
    print(f"OTP for {email} is: {otp}")

    cursor = conn.cursor()
    query = "UPDATE otp SET otp=%s, createAt=CURRENT_TIMESTAMP WHERE email=%s"
    cursor.execute(query, (otp, email))
    affectedRows = cursor.rowcount
    if affectedRows == 0:
        query = "INSERT INTO otp(email, otp) VALUES (%s, %s)"
        cursor.execute(query, (email, otp))
    conn.commit()
    cursor.close()

    return {"message": "OTP generated successfully."}
# ...OTP related

# User related...
@app.options("/users/")
async def options_users():
    return {"allow": "GET, POST, PUT, DELETE, OPTIONS"}

@app.post("/users/")
def create_user(user: User):
    hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())
    cursor = conn.cursor()

    print(user)
    query = "SELECT otp FROM otp WHERE email=%s"
    cursor.execute(query, (user.email,))
    row = cursor.fetchone()
    prevOtp = row[0]
    print(f'prevOtp: {prevOtp}')

    msg = ''
    status = ''
    if prevOtp == user.otp:
        print("OTP matched")
        query = "INSERT INTO users (username, password, email, role) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (user.username, hashed_password, user.email, user.role))
        status = 200
        msg = "User created successfully"
    else:
        print("OTP not matched")
        status = 403
        msg = "Otp not matched"

    print(f'msg: {msg}')
    print(f'status: {status}')

    conn.commit()
    cursor.close()
    return {
        'status': status,
        'msg': msg
    }
# ...User related

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
