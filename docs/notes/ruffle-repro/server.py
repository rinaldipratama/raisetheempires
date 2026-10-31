"""Tiny Flash Remoting server for the Ruffle repro (needs Py3AMF: pip install py3amf).

Build the SWF (Haxe 4): haxe -main Repro -swf repro.swf -swf-version 10 -D swf-header=760:560:30:FFFFFF
python server.py [port]   then open http://127.0.0.1:<port>/?gateway=gateway  (relative URL)
                                  or http://127.0.0.1:<port>/?gateway=http://127.0.0.1:<port>/gateway
Optional &ruffle=<npm version or dist-tag>, default 0.7.1.
"""
import http.server
import pathlib
import sys

import pyamf
from pyamf import remoting

HERE = pathlib.Path(__file__).parent
PAGE = '''<!doctype html><meta charset="utf-8"><title>Ruffle AMF repro</title>
<script>
  const params = new URLSearchParams(location.search);
  document.write('<script src="https://unpkg.com/@ruffle-rs/ruffle@' + (params.get("ruffle") || "0.7.1") + '/ruffle.js"><\\/script>');
  function reproLog(line) { const p = document.createElement("pre"); p.textContent = line; document.getElementById("log").append(p); }
</script>
<div id="player"></div><div id="log"></div>
<script>
  const player = RufflePlayer.newest().createPlayer();
  document.getElementById("player").append(player);
  player.load({url: "repro.swf", allowScriptAccess: true, logLevel: "info", autoplay: "on", unmuteOverlay: "hidden",
               parameters: {gateway: params.get("gateway") || "gateway"}});
</script>
'''


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/repro.swf'):
            self.reply(200, 'application/x-shockwave-flash', (HERE / 'repro.swf').read_bytes())
        else:
            self.reply(200, 'text/html; charset=utf-8', PAGE.encode())

    def do_POST(self):
        request = remoting.decode(self.rfile.read(int(self.headers['Content-Length'])))
        shared = {'name': 'shared'}
        envelope = remoting.Envelope(request.amfVersion)
        for target, _ in request:
            envelope[target] = remoting.Response({'first': shared, 'second': shared})
        self.reply(200, remoting.CONTENT_TYPE, remoting.encode(envelope).getvalue())

    def reply(self, status, content_type, body):
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    print(f'http://127.0.0.1:{port}/')
    http.server.ThreadingHTTPServer(('127.0.0.1', port), Handler).serve_forever()
