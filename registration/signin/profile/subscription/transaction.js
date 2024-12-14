// Populate transaction page dynamically from subscription form data
const urlParams = new URLSearchParams(window.location.search);

document.getElementById("user-id").value = urlParams.get("user_id") || "";
const planType = urlParams.get("plan_type");

// Set amount dynamically based on plan type
const amount = planType === "premium" ? 99.99 : 0; // Example: Premium costs $99.99
document.getElementById("amount").value = amount;

// Set transaction date to today's date
const today = new Date().toISOString().split("T")[0];
document.getElementById("transaction-date").value = today;
