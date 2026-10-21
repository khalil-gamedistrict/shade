"""Web build ko local pe chalata hai, WebAssembly (skwasm) ke zaroori headers ke saath.

Pehle build:  flutter build web --wasm
Phir chalao:  python3 tools/serve_web.py      → http://localhost:8080
"""
import functools
import http.server
import os
import sys


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Inke baghair browser WebAssembly ko multithreading nahi deta aur game dheemi chalti hai
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")
    print(f"http://localhost:{port}")
    http.server.ThreadingHTTPServer(("0.0.0.0", port), functools.partial(Handler, directory=root)).serve_forever()
