from fastapi import FastAPI
import uvicorn

app = FastAPI(title="User Service", version="1.0.0")

@app.get("/")
async def health_check():
    return {"status": "healthy", "service": "user-service"}

@app.get("/health")
async def health():
    return {"status": "OK", "service": "user-service"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
