import httpx

from src.exceptions import ServiceUnavailableException


class LibreTranslateClient:
    def __init__(self, base_url: str) -> None:
        self._base_url = base_url.rstrip("/")

    async def translate_batch(
        self,
        texts: list[str],
        source_lang: str,
        target_lang: str,
    ) -> list[str]:
        payload = {
            "q": texts,
            "source": source_lang,
            "target": target_lang,
            "format": "text",
        }
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    f"{self._base_url}/translate",
                    json=payload,
                    timeout=30.0,
                )
                resp.raise_for_status()
                data = resp.json()
                return data["translatedText"]
        except (httpx.HTTPError, KeyError) as exc:
            raise ServiceUnavailableException("LibreTranslate unavailable") from exc
