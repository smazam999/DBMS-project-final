// Form and elements
const planType = document.getElementById("plan-type");
const paymentSection = document.getElementById("payment-section");

// Show/Hide Payment Section based on Plan Type
planType.addEventListener("change", () => {
    if (planType.value === "premium") {
        paymentSection.classList.remove("hidden");
    } else {
        paymentSection.classList.add("hidden");
    }
});
