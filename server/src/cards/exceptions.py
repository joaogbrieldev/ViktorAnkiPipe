from src.exceptions import NotFoundException


class CardNotFoundException(NotFoundException):
    def __init__(self) -> None:
        super().__init__("Card not found")
