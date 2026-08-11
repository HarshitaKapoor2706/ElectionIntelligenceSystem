import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report


df = pd.read_csv('IFND.csv')
df = df[["Statement","Label"]]

df.dropna(inplace =True)
x= df["Statement"]
y= df["Label"]

x_train,x_test,y_train,y_test =train_test_split(
    x   ,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y
     )
df['Label'].value_counts()

model = Pipeline([
    (
    "tfidf",
    TfidfVectorizer(
        stop_words="english",
        max_features=20000,
        ngram_range=(1,2)
    )),
    (
    "classifier",
    LogisticRegression(
        max_iter=3000
    )
    

    )
])
model.fit(x_train,y_train)
predictions = model.predict(x_test)
accuracy =accuracy_score(y_test,predictions)
print(f"Accuracy : {accuracy:.4f}")
print(classification_report(y_test,predictions))

joblib.dump(model, "fake_news_model.pkl")