document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("report-form");
    const reportDisplay = document.getElementById("report-display");
  
    // Handle form submission
    form.addEventListener("submit", (event) => {
      event.preventDefault();
  
      // Capture user inputs
      const reportedUserId = document.getElementById("reported-user-id").value;
      const reportingUserId = document.getElementById("reporting-user-id").value;
      const reason = document.getElementById("reason").value;
      const status = document.getElementById("status").value;
      const date = document.getElementById("date").value;
  
      // Create a new report card
      const reportCard = document.createElement("div");
      reportCard.classList.add("report-card");
      reportCard.innerHTML = `
        <p><strong>Reported User ID:</strong> ${reportedUserId}</p>
        <p><strong>Reporting User ID:</strong> ${reportingUserId}</p>
        <p><strong>Reason:</strong> ${reason}</p>
        <p><strong>Status:</strong> ${status}</p>
        <p><strong>Date:</strong> ${date}</p>
      `;
  
      // Append to the display container
      reportDisplay.appendChild(reportCard);
  
      // Reset form
      form.reset();
    });
  });
  