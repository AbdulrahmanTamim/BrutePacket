from flask import Flask, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO
from scapy.all import sniff, IP, TCP
import threading
from collections import defaultdict

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Global state for network stats
network_stats = {
    'total_packets': 0,
    'active_devices': set(),
    'protocols': defaultdict(int),
    'throughput': {'upload': 0, 'download': 0},
    'topology': {'nodes': set(), 'connections': []}
}

capture_running = False

def packet_handler(packet):
    """Process each network packet and update stats."""
    if IP in packet:
        src = packet[IP].src
        dst = packet[IP].dst
        
        # Update topology
        network_stats['topology']['nodes'].update([src, dst])
        network_stats['topology']['connections'].append(f"{src} -> {dst}")
        
        # Track devices
        network_stats['active_devices'].update([src, dst])
        
        # Calculate throughput
        size = len(packet)
        if src.startswith('192.168'):  # Local network
            network_stats['throughput']['upload'] += size
        else:  # External traffic
            network_stats['throughput']['download'] += size

        # Protocol detection
        if TCP in packet:
            network_stats['protocols']['TCP'] += 1
        elif UDP in packet:
            network_stats['protocols']['UDP'] += 1
        elif ICMP in packet:
            network_stats['protocols']['ICMP'] += 1

    network_stats['total_packets'] += 1

def start_sniffing():
    """Start packet capture in a separate thread."""
    global capture_running
    capture_running = True
    sniff(prn=packet_handler, store=False, stop_filter=lambda x: not capture_running)

# ================= API Endpoints =================

@app.route('/api/stats')
def get_stats():
    """Return basic network statistics."""
    return jsonify({
        'total_packets': network_stats['total_packets'],
        'active_devices': len(network_stats['active_devices']),
        'throughput': network_stats['throughput']
    })

@app.route('/api/topology')
def get_topology():
    """Return network topology data."""
    return jsonify({
        'nodes': list(network_stats['topology']['nodes']),
        'connections': network_stats['topology']['connections'][-10:]  # Last 10 connections
    })

@app.route('/api/protocols')
def get_protocols():
    """Return protocol distribution."""
    return jsonify(network_stats['protocols'])

@app.route('/api/start')
def start_capture():
    """Start packet capture."""
    global capture_running
    if not capture_running:
        threading.Thread(target=start_sniffing).start()
    return jsonify({'status': 'started'})

@app.route('/api/stop')
def stop_capture():
    """Stop packet capture."""
    global capture_running
    capture_running = False
    return jsonify({'status': 'stopped'})

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)