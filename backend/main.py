from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.requests import Request
from pydantic import BaseModel
from datetime import date
from jose import jwt
import psycopg2
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db_connection():
    """Create a new database connection"""
    return psycopg2.connect(
        dbname='attendance_db',
        user='user',
        password='pass',
        host='db'
    )

class AttendanceEntry(BaseModel):
    date: date
    status: str

@app.post("/attendance")
async def submit_attendance(entry: AttendanceEntry, request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    
    token = auth_header.split(" ")[1]
    try:
        # Use proper JWT verification with secret key
        jwt_secret = os.getenv("JWT_SECRET", "your-secret-key")
        decoded = jwt.decode(token, jwt_secret, algorithms=["HS256"])
        username = decoded.get("preferred_username")
        if not username:
            raise HTTPException(status_code=401, detail="Invalid token: missing username")
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Use proper database connection management
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("INSERT INTO attendance (username, date, status) VALUES (%s, %s, %s)", (username, entry.date, entry.status))
        conn.commit()
        return {"message": "Attendance submitted."}
    finally:
        cur.close()
        conn.close()

@app.get("/attendance")
async def get_attendance(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    
    token = auth_header.split(" ")[1]
    try:
        # Use proper JWT verification with secret key
        jwt_secret = os.getenv("JWT_SECRET", "your-secret-key")
        decoded = jwt.decode(token, jwt_secret, algorithms=["HS256"])
        username = decoded.get("preferred_username")
        if not username:
            raise HTTPException(status_code=401, detail="Invalid token: missing username")
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Use proper database connection management
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT date, status FROM attendance WHERE username = %s", (username,))
        rows = cur.fetchall()
        return [{"date": str(row[0]), "status": row[1]} for row in rows]
    finally:
        cur.close()
        conn.close()
