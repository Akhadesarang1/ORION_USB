import time
import os
from brain import OrionBrain
from document_engine import DocumentEngine

def test_generation():
    print("--- STARTING DOCUMENT GENERATION TEST ---")

    # 1. Load Context (Self-Documentation)
    target_file = "document_engine.py"
    with open(target_file, "r", encoding="utf-8") as f:
        code_content = f.read()

    # 2. Initialize Engine
    print("🧠 Loading Brain (optimized)...")
    try:
        brain = OrionBrain()
        engine = DocumentEngine(brain)
    except Exception as e:
        print(f"❌ Brain Init Failed: {e}")
        return

    # 3. Start Job
    topic = "Orion Document Engine Architecture"
    print(f"📄 Starting Job: {topic}")
    start_time = time.time()

    job = engine.start_job(topic, context=code_content)

    # 4. Process Job
    print("⚙️  Processing sections...")
    result = engine.process_job()

    end_time = time.time()
    duration = end_time - start_time

    # 5. Report
    print(f"\n✅ GENERATION COMPLETE")
    print(f"⏱️  Duration: {duration:.1f} seconds")
    print(f"📁 Output: {result}")

    # 6. Verify Structure
    print("\n--- CHECKING STRUCTURE ---")
    required = [
        "1. Overview", "2. Purpose", "3. Architecture",
        "4. Core Components", "5. Workflow", "6. Data Handling",
        "7. Security", "8. Error Handling"
    ]

    with open(job.output_path, "r", encoding="utf-8") as f:
        content = f.read()

    missing = [req for req in required if req.split(".")[1].strip() not in content]

    if not missing:
        print("✅ STRUCTURE VERIFIED: All 8 points present.")
    else:
        print(f"⚠️  MISSING SECTIONS: {missing}")
        print("Current Sections found in file:")
        for line in content.splitlines():
            if line.startswith("## "):
                print(line)

if __name__ == "__main__":
    test_generation()
