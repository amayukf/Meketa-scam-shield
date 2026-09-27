from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import urllib.request
import urllib.error
import json
import os

PORT = 8090
WEB_DIR = r"d:\ethio scam sheilder\build\web"

class DevProxyHandler(SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Content-Length', '0')
        self.end_headers()

    def do_POST(self):
        if self.path.startswith('/api/verify'):
            try:
                content_len = int(self.headers.get('content-length', 0))
                body = self.rfile.read(content_len) if content_len > 0 else b'{}'
                
                api_key = self.headers.get('x-api-key', 'demo-odit-key')
                
                req = urllib.request.Request(
                    'https://v.odit.et/api/verify',
                    data=body,
                    headers={
                        'x-api-key': api_key,
                        'Content-Type': 'application/json',
                        'User-Agent': 'Mozilla/5.0'
                    },
                    method='POST'
                )

                try:
                    with urllib.request.urlopen(req, timeout=30) as resp:
                        resp_bytes = resp.read()
                        status_code = resp.status
                except urllib.error.HTTPError as e:
                    resp_bytes = e.read()
                    status_code = 200 # Return 200 to web client with real Odit JSON payload
                except Exception as e:
                    resp_bytes = json.dumps({'ok': False, 'error': str(e)}).encode('utf-8')
                    status_code = 200

                self.send_response(status_code)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', '*')
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Content-Length', str(len(resp_bytes)))
                self.send_header('Connection', 'close')
                self.end_headers()
                self.wfile.write(resp_bytes)
                self.wfile.flush()
            except Exception as outer_e:
                print("Outer POST error:", outer_e)
        else:
            self.send_error(404, "Not Found")

if __name__ == '__main__':
    ThreadingHTTPServer.allow_reuse_address = True
    server = ThreadingHTTPServer(('127.0.0.1', PORT), DevProxyHandler)
    print(f"Dev server running on http://localhost:{PORT}")
    server.serve_forever()
