import os
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

class SPAHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="build/web", **kwargs)

    def do_GET(self):
        # strip query parameters
        clean_path = self.path.split('?')[0]
        full_path = os.path.join(self.directory, clean_path.lstrip('/'))
        if not os.path.exists(full_path) or os.path.isdir(full_path):
            self.path = '/index.html'
        return super().do_GET()

server = HTTPServer(('127.0.0.1', 5555), SPAHandler)
print("SPA Server running on http://127.0.0.1:5555")
server.serve_forever()
