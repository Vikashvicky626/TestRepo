from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.requests import Request
from pydantic import BaseModel
from datetime import date
from jose import jwt
import psycopg2
import logging
import time

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connection with retry logic
def get_db_connection():
    max_retries = 5
    retry_delay = 2
    
    for attempt in range(max_retries):
        try:
            conn = psycopg2.connect(
                dbname='attendance_db',
                user='user',
                password='pass',
                host='db'
            )
            logger.info("Database connection established successfully")
            return conn
        except psycopg2.Error as e:
            logger.warning(f"Database connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
            else:
                raise HTTPException(status_code=500, detail="Unable to connect to database")

# Initialize database connection
conn = get_db_connection()
cur = conn.cursor()

# Create tables if they don't exist
def create_tables():
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS attendance (
                id SERIAL PRIMARY KEY,
                username VARCHAR(255) NOT NULL,
                date DATE NOT NULL,
                status VARCHAR(50) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(username, date)
            )
        """)
        
        # Create indexes for better performance
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_attendance_username ON attendance(username)
        """)
        
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date)
        """)
        
        conn.commit()
        logger.info("Database tables created successfully")
    except psycopg2.Error as e:
        logger.error(f"Error creating tables: {e}")
        raise HTTPException(status_code=500, detail="Database initialization failed")

# Initialize tables on startup
create_tables()

class AttendanceEntry(BaseModel):
    date: date
    status: str

def extract_token_from_request(request: Request) -> str:
    """Extract and validate JWT token from request headers"""
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    try:
        token = auth_header.split(" ")[1]
        return token
    except IndexError:
        raise HTTPException(status_code=401, detail="Invalid authorization header format")

def decode_token(token: str) -> dict:
    """Decode JWT token and extract user information"""
    try:
        decoded = jwt.decode(token, "", options={"verify_signature": False})
        username = decoded.get("preferred_username")
        if not username:
            raise HTTPException(status_code=401, detail="Username not found in token")
        return {"username": username}
    except Exception as e:
        logger.error(f"Token decoding error: {e}")
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/attendance")
async def submit_attendance(entry: AttendanceEntry, request: Request):
    """Submit attendance for a user"""
    try:
        # Extract and validate token
        token = extract_token_from_request(request)
        user_info = decode_token(token)
        username = user_info["username"]
        
        # Validate attendance status
        valid_statuses = ["Present", "Absent", "Late"]
        if entry.status not in valid_statuses:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
            )
        
        # Insert attendance record with conflict handling
        cur.execute("""
            INSERT INTO attendance (username, date, status) 
            VALUES (%s, %s, %s)
            ON CONFLICT (username, date) 
            DO UPDATE SET status = EXCLUDED.status, created_at = CURRENT_TIMESTAMP
        """, (username, entry.date, entry.status))
        
        conn.commit()
        logger.info(f"Attendance submitted for user: {username}, date: {entry.date}, status: {entry.status}")
        
        return {"message": "Attendance submitted successfully", "username": username, "date": str(entry.date), "status": entry.status}
        
    except HTTPException:
        raise
    except psycopg2.Error as e:
        logger.error(f"Database error during attendance submission: {e}")
        conn.rollback()
        raise HTTPException(status_code=500, detail="Failed to submit attendance")
    except Exception as e:
        logger.error(f"Unexpected error during attendance submission: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/attendance")
async def get_attendance(request: Request):
    """Get attendance records for a user"""
    try:
        # Extract and validate token
        token = extract_token_from_request(request)
        user_info = decode_token(token)
        username = user_info["username"]
        
        # Retrieve attendance records
        cur.execute("""
            SELECT date, status, created_at 
            FROM attendance 
            WHERE username = %s 
            ORDER BY date DESC
        """, (username,))
        
        rows = cur.fetchall()
        
        attendance_records = [
            {
                "date": str(row[0]), 
                "status": row[1],
                "created_at": row[2].isoformat() if row[2] else None
            } 
            for row in rows
        ]
        
        logger.info(f"Retrieved {len(attendance_records)} attendance records for user: {username}")
        return attendance_records
        
    except HTTPException:
        raise
    except psycopg2.Error as e:
        logger.error(f"Database error during attendance retrieval: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve attendance records")
    except Exception as e:
        logger.error(f"Unexpected error during attendance retrieval: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        cur.execute("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {"status": "unhealthy", "database": "disconnected"}

# Graceful shutdown
@app.on_event("shutdown")
async def shutdown_event():
    """Close database connection on shutdown"""
    try:
        cur.close()
        conn.close()
        logger.info("Database connection closed")
    except Exception as e:
        logger.error(f"Error closing database connection: {e}")
