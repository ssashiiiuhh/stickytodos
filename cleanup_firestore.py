import json, urllib.request, urllib.error

PROJECT = "stickytodos-sync"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"

# Get all notes
with urllib.request.urlopen(f"{BASE}/notes?pageSize=20") as r:
    docs = json.load(r).get("documents", [])

# Delete only the sample/fake notes, keep the real "To-do List"
KEEP_TITLES = {"To-do List"}

for doc in docs:
    fields = doc.get("fields", {})
    title = fields.get("title", {}).get("stringValue", "")
    doc_name = doc["name"]
    note_id = doc_name.split("/")[-1]

    if title not in KEEP_TITLES:
        url = f"{BASE}/notes/{note_id}"
        req = urllib.request.Request(url, method="DELETE")
        try:
            urllib.request.urlopen(req)
            print(f"Deleted '{title}'")
        except urllib.error.HTTPError as e:
            print(f"Could not delete '{title}': {e.read().decode()}")
    else:
        print(f"Kept '{title}'")

print("Done.")
