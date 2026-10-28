"""Servidor falso da API do app, só para tirar capturas de tela no CI.

Responde no formato que o app espera (ver Networking/Models.swift) com dados de
exemplo. Não representa o backend real nem horários reais de ônibus.
"""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse

PREFIX = "/api/v1/"
RTDB = "/rtdb/localizacao/"

HORARIOS = ["07:00", "08:30", "10:00", "12:00", "14:00", "17:30", "18:30", "21:30"]

ITINERARIOS = [
    {
        "id": "Campus - Metro Cinelandia",
        "nome": "Campus - Metro Cinelandia",
        "rotas": ["Ibmec Centro", "Metro Cinelandia"],
        "horarios": HORARIOS,
        "endereco": "Av. Presidente Wilson, Centro",
        "emRota": True,
        "suspensa": False,
        "localizacaoAtual": {
            "local": {"latitude": -22.9133, "longitude": -43.1758},
            "endereco": "Av. Rio Branco, Centro",
        },
    },
    {
        "id": "Campus - Central do Brasil",
        "nome": "Campus - Central do Brasil",
        "rotas": ["Ibmec Centro", "Central do Brasil"],
        "horarios": HORARIOS,
        "endereco": "Av. Presidente Wilson, Centro",
        "emRota": False,
        "suspensa": False,
        "localizacaoAtual": {
            "local": {"latitude": -22.9035, "longitude": -43.1912},
            "endereco": "Central do Brasil",
        },
    },
    {
        "id": "Campus - Praca Maua",
        "nome": "Campus - Praca Maua",
        "rotas": ["Ibmec Centro", "Praca Maua"],
        "horarios": HORARIOS,
        "endereco": "Av. Presidente Wilson, Centro",
        "emRota": True,
        "suspensa": False,
        "localizacaoAtual": {
            "local": {"latitude": -22.8962, "longitude": -43.1815},
            "endereco": "Praca Maua",
        },
    },
    {
        "id": "Campus - Gloria",
        "nome": "Campus - Gloria",
        "rotas": ["Ibmec Centro", "Gloria"],
        "horarios": HORARIOS,
        "endereco": "Av. Presidente Wilson, Centro",
        "emRota": False,
        "suspensa": True,
        "localizacaoAtual": None,
    },
]

LIVE = {
    "Campus - Metro Cinelandia": {
        "lat": -22.9133, "lng": -43.1758, "endereco": "Av. Rio Branco, Centro",
        "em_rota": True, "horario": "17:30", "motorista_nome": "Motorista de exemplo",
    },
    "Campus - Praca Maua": {
        "lat": -22.8962, "lng": -43.1815, "endereco": "Praca Maua",
        "em_rota": True, "horario": "18:30", "motorista_nome": "Motorista de exemplo",
    },
}

ME = {
    "matricula": "2024000000",
    "nome": "Breno Chaves",
    "email": "aluno@exemplo.com",
    "tipo": "aluno",
    "tipoDocumento": "CPF",
    "emailVerificado": True,
}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("%s %s" % (self.command, self.path), flush=True)

    def send(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def read_body(self):
        length = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(length) if length else b""

    def do_GET(self):
        path = unquote(urlparse(self.path).path)

        if path.startswith(RTDB) and path.endswith("/atual.json"):
            rid = path[len(RTDB):-len("/atual.json")]
            return self.send(200, LIVE.get(rid))

        if not path.startswith(PREFIX):
            return self.send(404, {"detail": "nao encontrado"})
        route = path[len(PREFIX):]

        if route == "users/me":
            return self.send(200, ME)
        if route == "itinerarios":
            return self.send(200, [i for i in ITINERARIOS if not i["suspensa"]])
        if route == "itinerarios/todas":
            return self.send(200, ITINERARIOS)
        if route.startswith("itinerarios/"):
            rid = route[len("itinerarios/"):]
            for item in ITINERARIOS:
                if item["id"] == rid:
                    return self.send(200, item)
        return self.send(404, {"detail": {"error": "not_found", "detail": "Nao encontrado"}})

    def do_POST(self):
        path = unquote(urlparse(self.path).path)
        self.read_body()
        route = path[len(PREFIX):] if path.startswith(PREFIX) else path
        if route == "auth/login":
            return self.send(200, {
                "idToken": "demo-token", "refreshToken": "demo-refresh",
                "tipoUsuario": "aluno", "nome": ME["nome"], "uid": "demo-uid",
                "emailVerificado": True,
            })
        if route == "auth/refresh":
            return self.send(200, {"idToken": "demo-token"})
        return self.send(200, {"message": "ok"})


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
