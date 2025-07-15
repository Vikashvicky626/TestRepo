from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.requests import Request
from pydantic import BaseModel
from datetime import date
from jose import jwt
import psycopg2

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

conn = psycopg2.connect(
    dbname='attendance_db',
    user='user',
    password='pass',
    host='db'
)
cur = conn.cursor()

class AttendanceEntry(BaseModel):
    date: date
    status: str

@app.post("/attendance")
async def submit_attendance(entry: AttendanceEntry, request: Request):
    token = request.headers.get("Authorization").split(" ")[1]
    try:
        decoded = jwt.decode(token, "", options={"verify_signature": False})
        username = decoded.get("preferred_username")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    cur.execute("INSERT INTO attendance (username, date, status) VALUES (%s, %s, %s)", (username, entry.date, entry.status))
    conn.commit()
    return {"message": "Attendance submitted."}

@app.get("/attendance")
async def get_attendance(request: Request):
    token = request.headers.get("Authorization").split(" ")[1]
    try:
        decoded = jwt.decode(token, "", options={"verify_signature": False})
        username = decoded.get("preferred_username")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    cur.execute("SELECT date, status FROM attendance WHERE username = %s", (username,))
    rows = cur.fetchall()
    return [{"date": str(row[0]), "status": row[1]} for row in rows]
