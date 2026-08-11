# backend/main.py
#
# FastAPI backend: /news, /chat, and /fake-news-check (hybrid: your
# trained ML model for a fast pattern-based signal, PLUS a Gemini
# cross-check against live election headlines for actual verification).
#
# Setup:
#   1. pip install -r requirements.txt
#   2. Copy fake_news_model.pkl into this same backend/ folder
#   3. Get a free NewsAPI key: https://newsapi.org/register
#   4. Get a free Gemini API key: https://aistudio.google.com/apikey
#   5. Paste both keys below (or set as env vars)
#   6. Run:  uvicorn main:app --reload --host 0.0.0.0 --port 8000

import json
import os
from datetime import date, datetime, timedelta

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google import genai

from predict import predict as predict_fake_news

app = FastAPI(title="Election Intel API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------
NEWS_API_KEY = os.environ.get("NEWS_API_KEY", " news")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "gemini")

NEWS_API_URL = "https://newsapi.org/v2/everything"

gemini_client = None
if GEMINI_API_KEY != "PASTE_YOUR_GEMINI_API_KEY_HERE":
    gemini_client = genai.Client(api_key=GEMINI_API_KEY)


# ---------------------------------------------------------------------
# /news  (also reused as context for /chat and /fake-news-check)
# ---------------------------------------------------------------------
QUERY = (
    '("Lok Sabha" OR "assembly election" OR "Election Commission" OR '
    '"Vidhan Sabha" OR "by-election" OR "EVM" OR election) AND India'
)

ELECTION_KEYWORDS = [
    "election", "lok sabha", "vidhan sabha", "assembly poll",
    "assembly election", "by-election", "evm", "election commission",
    "eci", "voter", "polling", "candidate", "manifesto", "constituency",
    "campaign rally", "chief minister", "cm ", "mla", "mp ", "bjp",
    "congress", "aap ", "political party", "opposition alliance",
]


def _is_election_related(title: str, description: str) -> bool:
    text = f"{title} {description}".lower()
    return any(keyword in text for keyword in ELECTION_KEYWORDS)


async def _fetch_news_raw(params: dict) -> list:
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            res = await client.get(NEWS_API_URL, params=params)
            res.raise_for_status()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=502, detail=f"NewsAPI error: {e}")
        except httpx.RequestError as e:
            raise HTTPException(status_code=502, detail=f"Could not reach NewsAPI: {e}")
    return res.json().get("articles", [])


async def _get_election_news() -> list:
    if NEWS_API_KEY == "PASTE_YOUR_NEWSAPI_KEY_HERE":
        return []

    params = {
        "q": QUERY,
        "from": date.today().isoformat(),
        "sortBy": "publishedAt",
        "language": "en",
        "pageSize": 40,
        "apiKey": NEWS_API_KEY,
    }
    articles = await _fetch_news_raw(params)

    if len(articles) < 5:
        params["from"] = (datetime.utcnow() - timedelta(days=3)).date().isoformat()
        articles = await _fetch_news_raw(params)

    cards = []
    for a in articles:
        title = a.get("title") or ""
        description = a.get("description") or ""
        if not title or title == "[Removed]":
            continue
        if not _is_election_related(title, description):
            continue
        cards.append(
            {
                "title": title,
                "subtitle": (a.get("source") or {}).get("name", "News"),
                "imageUrl": a.get("urlToImage"),
                "url": a.get("url"),
                "publishedAt": a.get("publishedAt"),
            }
        )
    return cards[:15]


@app.get("/news")
async def get_news():
    if NEWS_API_KEY == "PASTE_YOUR_NEWSAPI_KEY_HERE":
        raise HTTPException(
            status_code=500,
            detail="NEWS_API_KEY is not set. Get a free key at newsapi.org.",
        )
    return await _get_election_news()


# ---------------------------------------------------------------------
# /chat
# ---------------------------------------------------------------------
class ChatRequest(BaseModel):
    question: str


@app.post("/chat")
async def chat(payload: ChatRequest):
    if gemini_client is None:
        raise HTTPException(
            status_code=500,
            detail="GEMINI_API_KEY is not set. Get a free key at "
            "https://aistudio.google.com/apikey and paste it into main.py.",
        )

    question = payload.question.strip()
    if not question:
        raise HTTPException(status_code=400, detail="Question cannot be empty.")

    try:
        articles = await _get_election_news()
        headlines = "\n".join(f"- {a['title']} ({a['subtitle']})" for a in articles[:8])
        if not headlines:
            headlines = "No live news context available right now."
    except Exception:
        headlines = "No live news context available right now."

    prompt = f"""You are "Election AI", a helpful assistant inside an India \
election information app. Answer the user's question clearly and \
concisely (a few sentences, not an essay). Use the recent headlines \
below as context where relevant, but you can also use your general \
knowledge. If you're genuinely unsure about something, say so instead \
of guessing.

Recent headlines:
{headlines}

User question: {question}
"""

    try:
        interaction = gemini_client.interactions.create(
            model="gemini-3.5-flash",
            input=prompt,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Gemini error: {e}")

    return {"answer": interaction.output_text}


# ---------------------------------------------------------------------
# /fake-news-check -- HYBRID: ML model (fast, local) + Gemini cross-check
# against live election headlines (real verification, not just style).
# ---------------------------------------------------------------------
class FakeNewsRequest(BaseModel):
    claim: str


def _parse_gemini_json(raw_text: str) -> dict:
    """Gemini sometimes wraps JSON in markdown code fences -- strip those
    defensively before parsing."""
    text = raw_text.strip()
    if text.startswith("```"):
        text = text.strip("`")
        if text.lower().startswith("json"):
            text = text[4:]
        text = text.strip()
    return json.loads(text)


async def _gemini_verify(claim: str, headlines_text: str) -> dict:
    """
    Returns {"status": "SUPPORTED" | "CONTRADICTED" | "NO_INFO", "reasoning": str}
    """
    prompt = f"""You are a fact-checking assistant for an India election \
news app. Given a claim and a list of recent real news headlines, \
determine whether the claim is:
- SUPPORTED: the headlines confirm this claim is true
- CONTRADICTED: the headlines contradict this claim, or it matches a \
known false/misleading pattern
- NO_INFO: there isn't enough recent news information to confirm or \
deny this specific claim

Respond with ONLY valid JSON, no markdown formatting, no code fences, \
exactly in this shape:
{{"status": "SUPPORTED" or "CONTRADICTED" or "NO_INFO", "reasoning": \
"one or two sentence explanation"}}

Recent headlines:
{headlines_text}

Claim: "{claim}"
"""
    interaction = gemini_client.interactions.create(
        model="gemini-3.5-flash",
        input=prompt,
    )
    try:
        return _parse_gemini_json(interaction.output_text)
    except (json.JSONDecodeError, AttributeError):
        return {"status": "NO_INFO", "reasoning": "Could not parse verification response."}


def _combine_verdict(ml_label: str, ml_confidence: float, gemini_status: str, gemini_reasoning: str) -> dict:
    """
    Live news verification takes priority over pattern-matching when it
    has an actual answer. The ML model is the fallback signal when there's
    no relevant recent news to check against.
    """
    if gemini_status == "CONTRADICTED":
        return {
            "verdict": "Likely False",
            "explanation": gemini_reasoning,
            "source": "news_verified",
        }
    if gemini_status == "SUPPORTED":
        return {
            "verdict": "Likely True",
            "explanation": gemini_reasoning,
            "source": "news_verified",
        }

    confidence_pct = round(ml_confidence * 100, 1)
    verdict = "Possibly False" if ml_label == "Fake" else "Possibly True"
    return {
        "verdict": verdict,
        "explanation": (
            f"No recent news directly confirms or denies this claim. Based on "
            f"writing-pattern analysis, our model is {confidence_pct}% confident "
            f"this resembles {ml_label.lower()} news. Treat this as a signal, "
            f"not a fact-check."
        ),
        "source": "pattern_only",
    }


@app.post("/fake-news-check")
async def fake_news_check(payload: FakeNewsRequest):
    claim = payload.claim.strip()
    if not claim:
        raise HTTPException(status_code=400, detail="Claim cannot be empty.")

    try:
        ml_result = predict_fake_news(claim)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Model prediction failed: {e}")

    gemini_status = "NO_INFO"
    gemini_reasoning = "Live verification is not configured."
    if gemini_client is not None:
        try:
            articles = await _get_election_news()
            headlines_text = "\n".join(f"- {a['title']} ({a['subtitle']})" for a in articles[:10])
            if not headlines_text:
                headlines_text = "No recent election headlines available."
            gemini_result = await _gemini_verify(claim, headlines_text)
            gemini_status = gemini_result.get("status", "NO_INFO")
            gemini_reasoning = gemini_result.get("reasoning", "")
        except Exception:
            pass

    combined = _combine_verdict(ml_result["label"], ml_result["confidence"], gemini_status, gemini_reasoning)

    return {
        "verdict": combined["verdict"],
        "explanation": combined["explanation"],
        "source": combined["source"],
        "ml_label": ml_result["label"],
        "ml_confidence": ml_result["confidence"],
    }


@app.get("/")
async def root():
    return {"status": "ok", "endpoints": ["/news", "/chat", "/fake-news-check"]}