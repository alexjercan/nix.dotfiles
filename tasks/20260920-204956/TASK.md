# Deploy standalone local AI services

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: agents

Replace services.ai-tools-api with standalone Home Manager llama.cpp and whisper server modules under home/modules/agents. Remove the aggregated API deployment and expose each upstream server on its normal port.

Add a small Piper HTTP API for Seed Zero voice generation. Keep speech synthesis compatible with the existing request shape while Seed Zero uses the direct whisper.cpp endpoint for transcription.
