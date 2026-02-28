import os
import urllib.request
import zipfile
import ssl

def download_and_extract():
    url = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
    zip_path = "models/vosk-model-small-en-us-0.15.zip"
    extract_to = "models/"

    # Ensure models dir exists
    if not os.path.exists("models"):
        os.makedirs("models")

    # Bypass SSL verification if needed (quick hack for some envs)
    ssl._create_default_https_context = ssl._create_unverified_context

    print(f"⬇️ Downloading {url}...")
    try:
        urllib.request.urlretrieve(url, zip_path)
        print("✅ Download Complete.")
    except Exception as e:
        print(f"❌ Download Failed: {e}")
        return

    print(f"📦 Extracting to {extract_to}...")
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)
        print("✅ Extraction Complete.")
    except Exception as e:
        print(f"❌ Extraction Failed: {e}")
        return

    # Cleanup
    if os.path.exists(zip_path):
        os.remove(zip_path)
        print("🧹 Cleaned up zip file.")

if __name__ == "__main__":
    download_and_extract()
