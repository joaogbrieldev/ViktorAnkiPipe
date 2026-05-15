from google import genai

GEMINI_MODEL = "gemini-2.5-flash"


class GeminiService:
    def __init__(self, api_key: str) -> None:
        self._client = genai.Client(api_key=api_key)

    async def generate_example(
        self,
        source_text: str,
        translated_text: str,
        context: str | None,
    ) -> str:
        prompt = _build_prompt(source_text, translated_text, context)
        response = await self._client.aio.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
        )
        return response.text.strip()


def _build_prompt(source_text: str, translated_text: str, context: str | None) -> str:
    lines = [
        "You are an English vocabulary tutor.",
        f'Word: "{source_text}" (means "{translated_text}" in Portuguese).',
    ]
    if context:
        lines.append(f'The reader encountered it in this sentence: "{context}".')
    lines.append(
        "Write one short, natural English example sentence that uses this word correctly."
    )
    lines.append("Return only the sentence, nothing else.")
    return "\n".join(lines)
