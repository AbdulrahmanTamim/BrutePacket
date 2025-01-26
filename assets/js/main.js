// Initialize all charts
function initializeCharts() {
    // Protocol Distribution Chart
    const protocolCtx = document.getElementById('protocolChart').getContext('2d');
    window.protocolChart = new Chart(protocolCtx, {
        type: 'doughnut',
        data: {
            labels: ['TCP', 'UDP', 'ICMP'],
            datasets: [{
                data: [0, 0, 0],
                backgroundColor: ['#00d1b2', '#ff6384', '#ffcd56']
            }]
        }
    });

    // Packet Size Chart
    const sizeCtx = document.getElementById('packetSizeChart').getContext('2d');
    window.packetSizeChart = new Chart(sizeCtx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Packet Size (bytes)',
                data: [],
                borderColor: '#4bc0c0'
            }]
        }
    });
}

// Update all charts
async function updateCharts() {
    try {
        // Update protocol chart
        const metricsResponse = await fetch('http://localhost:5000/advanced-metrics');
        const metrics = await metricsResponse.json();
        
        window.protocolChart.data.datasets[0].data = [
            metrics.protocol_dist.tcp || 0,
            metrics.protocol_dist.udp || 0,
            metrics.protocol_dist.icmp || 0
        ];
        window.protocolChart.update();

        // Update packet size chart
        const time = new Date().toLocaleTimeString();
        window.packetSizeChart.data.labels.push(time);
        window.packetSizeChart.data.datasets[0].data.push(metrics.avg_packet_size);
        
        if (window.packetSizeChart.data.labels.length > 15) {
            window.packetSizeChart.data.labels.shift();
            window.packetSizeChart.data.datasets[0].data.shift();
        }
        window.packetSizeChart.update();

    } catch (error) {
        console.error('Error updating charts:', error);
    }
}

// Initialize charts on page load
document.addEventListener('DOMContentLoaded', () => {
    initializeCharts();
    setInterval(updateCharts, 2000);
});

function inspectPacket(packetId) {
    stratoshark.renderPacketInspector('#packetInspector', {
        protocolColors: {
            tcp: '#00d1b2',
            udp: '#ff6384',
            http: '#4bc0c0'
        },
        zoom: true,
        decode: true
    });
}

document.querySelectorAll('.packet-row').forEach(row => {
    row.addEventListener('click', () => {
        inspectPacket(row.dataset.packetId);
    });
});