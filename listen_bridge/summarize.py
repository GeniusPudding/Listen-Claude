"""Local heuristic summarization — no LLM, no network."""

import re

_SENTENCE_END = re.compile(r"(?<=[。！？.!?])\s+|(?<=[。！？.!?])$")


def split_paragraphs(text: str) -> list[str]:
    return [p.strip() for p in text.split("\n\n") if p.strip()]


def split_sentences(paragraph: str) -> list[str]:
    sents = _SENTENCE_END.split(paragraph)
    return [s.strip() for s in sents if s.strip()]


def first_paragraph(text: str) -> str:
    paras = split_paragraphs(text)
    return paras[0] if paras else ""


def heuristic_summary(text: str) -> str:
    """Pick headings (lines starting with #) and the first sentence of each
    paragraph; skip code blocks entirely."""
    out = []
    in_code = False
    for raw in text.split("\n"):
        stripped = raw.strip()
        if stripped.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if stripped.startswith("#"):
            out.append(stripped.lstrip("#").strip())
            continue
    paras = split_paragraphs(text)
    for p in paras:
        if p.startswith("#") or p.startswith("```"):
            continue
        sents = split_sentences(p)
        if sents:
            out.append(sents[0])
    return " ".join(out)


def prepare_text(text: str, mode: str, max_chars: int) -> str:
    """Apply the configured summarization mode and truncate to max_chars."""
    text = strip_markdown_noise(text)
    if mode == "full":
        result = text
    elif mode == "first":
        result = first_paragraph(text)
    elif mode == "summary":
        result = heuristic_summary(text)
    else:
        result = text
    if len(result) > max_chars:
        result = result[: max_chars - 1].rstrip() + "…"
    return result


def strip_markdown_noise(text: str) -> str:
    """Drop fenced code blocks, inline backticks, and Markdown link syntax —
    they don't read well in speech."""
    out_lines = []
    in_code = False
    for line in text.split("\n"):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        out_lines.append(line)
    text = "\n".join(out_lines)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return text
