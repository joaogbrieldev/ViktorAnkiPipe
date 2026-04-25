from fastapi import FastAPI

from src.exceptions import register_exception_handlers

app = FastAPI()

register_exception_handlers(app)


@app.get("/")
def read_root():
    return {"Hello": "World"}
