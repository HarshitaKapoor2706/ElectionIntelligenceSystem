# predict.py
#
# Loads the trained model and exposes a predict() function.
# Label mapping matches your own tested CLI version (1 = REAL, 0 = FAKE).
# If your results ever look backwards, flip the line marked below.

import joblib

model = joblib.load("fake_news_model.pkl")


def predict(text: str) -> dict:
    """
    Returns:
        {"label": "Real" or "Fake", "confidence": float between 0 and 1}
    """
    prediction = model.predict([text])[0]
    probability = model.predict_proba([text])[0]
    confidence = float(max(probability))

    # Matches your tested predict.py CLI script's mapping.
    label = "Real" if prediction == 1 else "Fake"

    return {"Label": Label, "confidence": confidence}


if __name__ == "__main__":
    while True:
        text = input("\nEnter news text (or 'exit'): ")
        if text.lower() == "exit":
            break
        result = predict(text)
        print(f"Verdict: {result['Label'].upper()}  |  Confidence: {result['confidence']*100:.2f}%")