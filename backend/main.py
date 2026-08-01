
# backend/main.py
#
# FastAPI backend for the /news endpoint.
# Fetches election-related headlines from NewsAPI.org, restricted to
# genuinely election-relevant articles via a proper quoted/grouped query
# PLUS a keyword allowlist filter applied after the fact (NewsAPI's OR
# query without quotes/parentheses is unreliable and can return unrelated
# results, as you saw with the GitHub/tariffs/medical-college articles).
#
# Setup:
#   1. pip install fastapi uvicorn httpx
#   2. Get a free key at https://newsapi.org/register
#   3. Paste it into NEWS_API_KEY below (or set it as an env var)
#   4. Run:  uvicorn main:app --reload --host 0.0.0.0 --port 8000
#   5. Test in browser: http://localhost:8000/news

import os
from datetime import date, datetime, timedelta

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Election Intel API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
NEWS_API_KEY = "9c6ad422d78d47c18eec2b47edb928e6"

NEWS_API_URL = "https://newsapi.org/v2/everything"

# Proper NewsAPI query syntax: quoted phrases + explicit grouping with
# parentheses. Bare "A OR B OR C" without quotes/parens is what caused
# the unrelated results before.
QUERY = (
    '("Lok Sabha" OR "assembly election" OR "Election Commission" OR '
    '"Vidhan Sabha" OR "by-election" OR "EVM" OR election) AND India'
)

# Safety-net allowlist: even if NewsAPI's search returns something
# tangential, we only keep articles whose title/description actually
# contain one of these terms. Case-insensitive substring match.
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


async def _fetch(params: dict) -> list:
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            res = await client.get(NEWS_API_URL, params=params)
            res.raise_for_status()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=502, detail=f"NewsAPI error: {e}")
        except httpx.RequestError as e:
            raise HTTPException(status_code=502, detail=f"Could not reach NewsAPI: {e}")
    return res.json().get("articles", [])


@app.get("/news")
async def get_news():
    if NEWS_API_KEY == "PASTE_YOUR_NEWSAPI_KEY_HERE":
        raise HTTPException(
            status_code=500,
            detail="NEWS_API_KEY is not set. Get a free key at newsapi.org "
            "and set it as an environment variable or paste it into main.py.",
        )

    params = {
        "q": QUERY,
        "from": date.today().isoformat(),
        "sortBy": "publishedAt",
        "language": "en",
        "pageSize": 40,  # fetch generously since we filter afterward
        "apiKey": NEWS_API_KEY,
    }

    articles = await _fetch(params)

    # Free tier can be sparse on very recent dates -- widen to the last
    # 3 days if today alone comes up short, so the carousel isn't empty.
    if len(articles) < 5:
        params["from"] = (datetime.utcnow() - timedelta(days=3)).date().isoformat()
        articles = await _fetch(params)

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


@app.get("/")
async def root():
    return {"status": "ok", "endpoints": ["/news"]}