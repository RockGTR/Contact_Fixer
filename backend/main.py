from fastapi import FastAPI
from backend.routers import auth, contacts

app = FastAPI(
    title="Contact Fixer API",
    description="API for fetching and fixing Google Contacts",
    version="0.1.0"
)

app.include_router(auth.router)
app.include_router(contacts.router)

@app.get("/")
async def read_root():
    return {"message": "Contact Fixer API is running!"}

@app.get("/health")
async def health_check():
    return {"status": "ok"}
