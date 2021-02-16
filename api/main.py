from fastapi import FastAPI


app = FastAPI(
    docs_url='/docs',
    openapi_url='/openapi.json',
)


@app.get('/')
async def index():
    return {'message': 'Hello, detox-proxy!'}
