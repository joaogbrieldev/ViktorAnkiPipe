from src.exceptions import NotFoundException


class SessionNotFoundException(NotFoundException):
    def __init__(self) -> None:
        super().__init__("Session not found")
