from orion_voice_system import OrionVoiceSystem
import time
import sys

def verify():
    print("🔹 Initializing ORION Pure NeMo Voice System...")
    try:
        voice = OrionVoiceSystem()
    except Exception as e:
        print(f"❌ Initialization Failed: {e}")
        return

    print(f"\n✅ System Status:")
    print(f"  - NeMo Parakeet (Wake & STT): {'🟢 ONLINE' if voice.stt_ok else '🔴 OFFLINE'}")
    print(f"  - NeMo (TTS):                 {'🟢 ONLINE' if voice.tts_ok else '🔴 OFFLINE'}")

    if not voice.stt_ok:
        print("\n⚠️ STT model missing or failed. Cannot test voice.")
        return

    print("\n🔊 Testing TTS...")
    voice.speak("Voice verification sequence initiated.")

    # PTT Test
    input("\n🎙️ [PRESS ENTER] to test recording (3 seconds)...")

    audio = voice.record_command(seconds=3)

    print("📝 Transcribing...")
    text = voice.transcribe(audio)
    print(f"✅ Transcription: '{text}'")

    voice.speak(f"I heard you say: {text}")

if __name__ == "__main__":
    verify()
