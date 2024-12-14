function showTab(tabId) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
    // Remove active class from all tabs
    document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
    // Show the selected tab
    document.getElementById(tabId).classList.add('active');
    document.querySelector(`.tab[onclick="showTab('${tabId}')"]`).classList.add('active');
    document.querySelector('.exchange-btn').addEventListener('click', function () {
        alert('Exchange Coins functionality coming soon!');
        // Or redirect to another page
        // window.location.href = 'exchange-coins.html';
    });
    
}
