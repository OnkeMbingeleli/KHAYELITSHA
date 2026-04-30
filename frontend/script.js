// Taxi Management System - Frontend JavaScript

const API_BASE = 'http://127.0.0.1:5000'; // Backend URL
let currentUser = null;
let currentRoute = null;

// Login function
async function login() {
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    
    try {
        const response = await fetch(`${API_BASE}/api/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ username, password })
        });
        
        const data = await response.json();
        if (response.ok) {
            currentUser = username;
            // Fetch user details to get route
            const summaryResponse = await fetch(`${API_BASE}/api/summary`, {
                credentials: 'include'
            });
            const summaryData = await summaryResponse.json();
            currentRoute = summaryData.route;
            
            document.getElementById('login-section').style.display = 'none';
            document.getElementById('main-section').style.display = 'block';
            document.getElementById('user-name').textContent = username;
            document.getElementById('user-route').textContent = currentRoute;
            document.getElementById('login-message').textContent = '';
        } else {
            document.getElementById('login-message').textContent = data.error || 'Login failed';
        }
    } catch (error) {
        console.error('Login error:', error);
        document.getElementById('login-message').textContent = 'Network error';
    }
}

// Tab switching
function showTab(tabName) {
    // Hide all tabs
    const tabs = document.querySelectorAll('.tab-content');
    tabs.forEach(tab => tab.style.display = 'none');
    
    // Remove active class from buttons
    const buttons = document.querySelectorAll('.tab-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    
    // Show selected tab
    document.getElementById(tabName).style.display = 'block';
    event.target.classList.add('active');
    
    // Load data if needed
    if (tabName === 'summary') {
        loadSummary();
    } else if (tabName === 'report') {
        loadDailyReport();
    }
}

// Record pickup
async function recordPickup() {
    const plate = document.getElementById('plate').value;
    const rank = document.getElementById('rank').value;
    
    if (!plate || !rank) {
        document.getElementById('record-message').textContent = 'Please fill in all fields';
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/api/record`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ number_plate: plate, rank })
        });
        
        const data = await response.json();
        if (response.ok) {
            document.getElementById('record-message').textContent = '✓ Pickup recorded successfully!';
            document.getElementById('plate').value = '';
            document.getElementById('rank').value = '';
            // Clear message after 3 seconds
            setTimeout(() => {
                document.getElementById('record-message').textContent = '';
            }, 3000);
        } else {
            document.getElementById('record-message').textContent = data.error || 'Failed to record pickup';
        }
    } catch (error) {
        console.error('Record error:', error);
        document.getElementById('record-message').textContent = 'Network error';
    }
}

// Load summary
async function loadSummary() {
    try {
        const response = await fetch(`${API_BASE}/api/summary`, {
            credentials: 'include'
        });
        
        const data = await response.json();
        
        // Update stats
        document.getElementById('total-loads').textContent = data.total_loads;
        document.getElementById('rank-count').textContent = Object.keys(data.rank_summary).length;
        
        // Display rank summary
        const rankList = document.getElementById('rank-summary');
        rankList.innerHTML = '';
        for (const [rank, count] of Object.entries(data.rank_summary)) {
            const div = document.createElement('div');
            div.className = 'list-item';
            div.textContent = `${rank}: ${count} pickup(s)`;
            rankList.appendChild(div);
        }
        
        // Display all pickups
        const list = document.getElementById('pickups-list');
        list.innerHTML = '';
        data.pickups.forEach(pickup => {
            const div = document.createElement('div');
            div.className = 'list-item';
            const time = new Date(pickup.timestamp).toLocaleTimeString();
            div.innerHTML = `<strong>${pickup.number_plate}</strong> at ${pickup.rank} (${time}) - Owner: ${pickup.owner_name}`;
            list.appendChild(div);
        });
    } catch (error) {
        console.error('Summary error:', error);
    }
}

// Load daily report
async function loadDailyReport() {
    try {
        const response = await fetch(`${API_BASE}/api/daily-report`, {
            credentials: 'include'
        });
        
        const data = await response.json();
        
        const report = document.getElementById('vehicle-report');
        report.innerHTML = `<p><strong>Date:</strong> ${new Date(data.date).toLocaleDateString()}</p>
                           <p><strong>Route:</strong> ${data.route}</p>
                           <p><strong>Total System Loads:</strong> ${data.total_system_loads}</p>
                           <hr>`;
        
        for (const [vehicle, details] of Object.entries(data.vehicles)) {
            const vehicleDiv = document.createElement('div');
            vehicleDiv.className = 'vehicle-report';
            vehicleDiv.innerHTML = `
                <h4>${vehicle}</h4>
                <p><strong>Owner:</strong> ${details.owner}</p>
                <p><strong>Total Loads:</strong> ${details.total_loads}</p>
                <p><strong>Ranks:</strong></p>
                <ul>
            `;
            
            for (const [rank, count] of Object.entries(details.ranks)) {
                vehicleDiv.innerHTML += `<li>${rank}: ${count} load(s)</li>`;
            }
            
            vehicleDiv.innerHTML += '</ul>';
            report.appendChild(vehicleDiv);
        }
    } catch (error) {
        console.error('Report error:', error);
    }
}

// Logout
function logout() {
    document.getElementById('main-section').style.display = 'none';
    document.getElementById('login-section').style.display = 'block';
    document.getElementById('username').value = '';
    document.getElementById('password').value = '';
    currentUser = null;
    currentRoute = null;
}
