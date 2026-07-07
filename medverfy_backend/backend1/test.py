import requests

try:
    r = requests.get("https://api.groq.com", timeout=10)
    print("Groq reachable:", r.status_code)
except Exception as e:
    print("Groq connection failed:", e)