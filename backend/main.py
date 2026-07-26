# backend/main.py
#
# Minimal FastAPI backend for the /news endpoint.
# Fetches TODAY's election-related headlines from NewsAPI.org (free tier
# is enough for a hackathon demo — 100 requests/day, no card needed).
#
# Setup:
#   1. pip install fastapi uvicorn httpx
#   2. Get a free key at https://newsapi.org/register
#   3. Paste it into NEWS_API_KEY below (or set it as an env var — see note)
#   4. Run:  uvicorn main:app --reload --port 8000
#   5. Test in browser: http://localhost:8000/news

import os
from datetime import date, datetime, timedelta

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Election Intel API")

# Allow the Flutter app (running on emulator/device/web) to call this API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prefer an environment variable in real deployments; falling back to a
# placeholder string here so the file is runnable out of the box once you
# paste your key in.
NEWS_API_KEY = os.environ.get("NEWS_API_KEY", "9c6ad422d78d47c18eec2b47edb928e6")
NEWS_API_URL = "https://newsapi.org/v2/everything"


@app.get("/news")
async def get_news():
    """
    Returns today's India-election-related news as a list of cards for
    the trending news carousel.
    """
    if NEWS_API_KEY == "PASTE_YOUR_NEWSAPI_KEY_HERE":
        raise HTTPException(
            status_code=500,
            detail="NEWS_API_KEY is not set. Get a free key at newsapi.org "
            "and set it as an environment variable or paste it into main.py.",
        )

    today = date.today().isoformat()

    params = {
        "q": "India election OR Lok Sabha OR assembly election OR Election Commission",
        "from": today,
        "sortBy": "publishedAt",
        "language": "en",
        "pageSize": 20,
        "apiKey": NEWS_API_KEY,
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            res = await client.get(NEWS_API_URL, params=params)
            res.raise_for_status()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=502, detail=f"NewsAPI error: {e}")
        except httpx.RequestError as e:
            raise HTTPException(status_code=502, detail=f"Could not reach NewsAPI: {e}")

    data = res.json()
    articles = data.get("articles", [])

    # NewsAPI's free tier sometimes returns nothing for very recent "from"
    # dates depending on source indexing lag — fall back to last 24h if
    # today's slice is empty, so the carousel isn't blank on slow days.
    if not articles:
        params["from"] = (datetime.utcnow() - timedelta(days=1)).date().isoformat()
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.get(NEWS_API_URL, params=params)
            data = res.json()
            articles = data.get("articles", [])

    cards = []
    for a in articles:
        if not a.get("title") or a["title"] == "[Removed]":
            continue
        cards.append(
            {
                "title": a["title"],
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