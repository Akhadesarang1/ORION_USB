import shutil
import os

source = "vosk-model-small-en-us-0.15"
destination = "models/vosk-model-small-en-us-0.15"

if os.path.exists(source):
    print(f"📦 Moving '{source}' to 'models/'...")
    try:
        # Check if destination already exists
        if os.path.exists(destination):
            print(f"⚠️ Destination '{destination}' already exists. Removing it first.")
            shutil.rmtree(destination)

        shutil.move(source, destination)
        print("✅ Move Complete.")
    except Exception as e:
        print(f"❌ Move Failed: {e}")
else:
    print(f"⚠️ Source '{source}' not found. Check if it's already in 'models/'?")

if os.path.exists(destination):
    print("✅ Verified: Model is in the correct location.")
else:
    print("❌ Verification Failed: Model is NOT in 'models/' directory.")
