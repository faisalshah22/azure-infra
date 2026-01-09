from fastapi import FastAPI
import pyodbc
import os

app = FastAPI()

@app.get("/")
async def get_quote():
    try:
        server = os.environ.get("SQL_SERVER")
        database = os.environ.get("SQL_DATABASE")
        username = os.environ.get("SQL_USER")
        password = os.environ.get("SQL_PASSWORD")
        
        conn_str = f"Driver={{ODBC Driver 18 for SQL Server}};Server=tcp:{server},1433;Database={database};Uid={username};Pwd={password};Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;"
        
        conn = pyodbc.connect(conn_str)
        query = conn.execute("SELECT TOP 1 quote FROM quotes ORDER BY NEWID()")
        row = query.fetchone()
        
        conn.close()
        
        if row:
            return {"quote": row[0]}
        else:
            return {"quote": "No quotes available"}
    except Exception as e:
        return {"error": str(e)}

