from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppException(Exception):
    status_code: int = 500
    error: str = "internal_server_error"

    def __init__(self, detail: str) -> None:
        self.detail = detail
        super().__init__(detail)


class NotFoundException(AppException):
    status_code = 404
    error = "not_found"


class BadRequestException(AppException):
    status_code = 400
    error = "bad_request"


class ConflictException(AppException):
    status_code = 409
    error = "conflict"


class ServiceUnavailableException(AppException):
    status_code = 503
    error = "service_unavailable"


def register_exception_handlers(app: FastAPI) -> None:

    @app.exception_handler(AppException)
    async def app_exception_handler(
        request: Request, exc: AppException
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": exc.error, "detail": exc.detail},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(
        request: Request, exc: Exception
    ) -> JSONResponse:
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_server_error",
                "detail": "Erro inesperado no servidor.",
            },
        )
