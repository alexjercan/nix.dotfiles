#!/usr/bin/env python3
"""Small HTTP API for an owned Piper process."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any


class SpeechServer(HTTPServer):
    piper: str
    model: str
    config: str
    max_text_bytes: int
    timeout: int


class Handler(BaseHTTPRequestHandler):
    server: SpeechServer

    def send_json(self, status: HTTPStatus, value: dict[str, Any]) -> None:
        body = json.dumps(value, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def error(self, status: HTTPStatus, code: str) -> None:
        self.send_json(status, {"error": {"code": code}})

    def do_GET(self) -> None:
        if self.path in ("/", "/health"):
            self.send_json(HTTPStatus.OK, {"service": "piper-tts", "status": "ok"})
        else:
            self.error(HTTPStatus.NOT_FOUND, "not_found")

    def do_POST(self) -> None:
        if self.path != "/v1/audio/speech":
            self.error(HTTPStatus.NOT_FOUND, "not_found")
            return
        if self.headers.get_content_type() != "application/json":
            self.error(HTTPStatus.UNSUPPORTED_MEDIA_TYPE, "invalid_content_type")
            return
        try:
            size = int(self.headers.get("Content-Length", "-1"))
        except ValueError:
            size = -1
        if size < 0 or size > self.server.max_text_bytes + 4096:
            self.error(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, "input_too_large")
            return
        try:
            request = json.loads(self.rfile.read(size))
        except (UnicodeDecodeError, json.JSONDecodeError):
            self.error(HTTPStatus.BAD_REQUEST, "invalid_request")
            return
        if not isinstance(request, dict) or set(request) != {
            "model",
            "voice",
            "input",
            "response_format",
        }:
            self.error(HTTPStatus.BAD_REQUEST, "invalid_request")
            return
        if request["model"] != "piper-1":
            self.error(HTTPStatus.BAD_REQUEST, "unsupported_model")
            return
        if request["voice"] != "en_US-lessac-medium":
            self.error(HTTPStatus.BAD_REQUEST, "unsupported_voice")
            return
        if request["response_format"] != "wav":
            self.error(HTTPStatus.BAD_REQUEST, "unsupported_format")
            return
        text = request["input"]
        if not isinstance(text, str) or not text.strip() or any(ord(c) < 32 for c in text):
            self.error(HTTPStatus.BAD_REQUEST, "empty_input")
            return
        if len(text.encode("utf-8")) > self.server.max_text_bytes:
            self.error(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, "input_too_large")
            return

        path = ""
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as output:
                path = output.name
            result = subprocess.run(
                [
                    self.server.piper,
                    "--model",
                    self.server.model,
                    "--config",
                    self.server.config,
                    "--output_file",
                    path,
                ],
                input=(text + "\n").encode(),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                timeout=self.server.timeout,
                check=False,
            )
            with open(path, "rb") as generated:
                audio = generated.read()
        except subprocess.TimeoutExpired:
            self.error(HTTPStatus.GATEWAY_TIMEOUT, "timeout")
            return
        except OSError:
            self.error(HTTPStatus.SERVICE_UNAVAILABLE, "backend_unavailable")
            return
        finally:
            if path:
                try:
                    os.unlink(path)
                except FileNotFoundError:
                    pass
        if result.returncode != 0 or len(audio) < 12 or audio[:4] != b"RIFF" or audio[8:12] != b"WAVE":
            self.error(HTTPStatus.BAD_GATEWAY, "backend_failure")
            return
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "audio/wav")
        self.send_header("Content-Length", str(len(audio)))
        self.end_headers()
        self.wfile.write(audio)

    def log_message(self, format: str, *args: object) -> None:
        print(f"{self.address_string()} - {format % args}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=10303)
    parser.add_argument("--piper", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--config", required=True)
    parser.add_argument("--max-text-bytes", type=int, default=4096)
    parser.add_argument("--timeout", type=int, default=60)
    args = parser.parse_args()

    server = SpeechServer((args.host, args.port), Handler)
    server.piper = args.piper
    server.model = args.model
    server.config = args.config
    server.max_text_bytes = args.max_text_bytes
    server.timeout = args.timeout
    server.serve_forever()


if __name__ == "__main__":
    main()
