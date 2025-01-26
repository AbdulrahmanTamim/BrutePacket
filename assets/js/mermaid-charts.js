function updateCharts() {
    // Protocol Distribution
    fetch('/protocol-breakdown')
        .then(res => res.json())
        .then(data => {
            const chartCode = `
                pie title Protocols
                    "TCP": ${data.tcp}
                    "UDP": ${data.udp}
                    "HTTP": ${data.http}
                    "DNS": ${data.dns}
            `;
            mermaid.render('protocolChart', chartCode);
        });

    // Bandwidth Usage
    fetch('/bandwidth-usage')
        .then(res => res.json())
        .then(data => {
            const chartCode = `
                gantt
                    title Live Bandwidth
                    section Upload
                    Active : done, 0, ${data.upload}MB
                    section Download
                    Active : done, 0, ${data.download}MB
            `;
            mermaid.render('bandwidthChart', chartCode);
        });
}

setInterval(updateCharts, 2000);