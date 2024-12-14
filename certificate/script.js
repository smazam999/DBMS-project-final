function openEmail() {
    const recipient = "smazam999@gmail.com";
    const subject = "Subscription Application";
    const body = "This email is sent when the 'Apply Now' button is clicked.";
  
    // Construct the email URL
    const mailtoUrl = `mailto:${recipient}?subject=${subject}&body=${body}`;
  
    // Open the user's default email client with the pre-populated fields
    window.location.href = mailtoUrl;
  }