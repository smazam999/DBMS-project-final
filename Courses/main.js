document.addEventListener("DOMContentLoaded", () => {
  const fallbackCourses = [
    { name: "Web Development", subCourses: ["HTML", "CSS", "JavaScript", "React", "Node.js", "Next.js"] },
    { name: "Graphics Design", subCourses: ["Logo Design", "Web Design", "Motion Graphics", "Game Design", "Illustrator", "Photoshop"] },
    { name: "Cyber Security", subCourses: ["Application Security", "Cloud Security", "Data Security", "Network Security", "Penetration Testing"] },
    { name: "AI", subCourses: ["AI Productivity Tools", "AI Assistants", "AI Video Tools", "Machine Learning", "Deep Learning", "Natural Language Processing"] },
    { name: "Programming", subCourses: ["Java", "C", "C++", "Python", "JavaScript", "Rust", "Go"] },
    { name: "Operating System", subCourses: ["Batch", "Multi-Programming", "Multi-Tasking", "Linux", "Windows", "MacOS"] },
    { name: "Data Science", subCourses: ["Data Analysis", "Data Visualization", "Big Data", "SQL", "R Programming", "Pandas"] },
    { name: "Mobile App Development", subCourses: ["Android Development", "iOS Development", "Flutter", "React Native", "Swift", "Kotlin"] },
    { name: "Game Development", subCourses: ["Unity", "Unreal Engine", "Game Physics", "Game AI", "Mobile Game Development"] },
    { name: "Cloud Computing", subCourses: ["AWS", "Azure", "Google Cloud Platform", "Cloud Security", "Serverless Architecture"] },
    { name: "DevOps", subCourses: ["CI/CD Pipelines", "Docker", "Kubernetes", "Terraform", "Ansible", "Monitoring Tools"] },
    { name: "Blockchain", subCourses: ["Blockchain Basics", "Smart Contracts", "Ethereum", "Bitcoin Development", "NFTs", "DeFi"] },
    { name: "Digital Marketing", subCourses: ["SEO", "Content Marketing", "Social Media Marketing", "Email Marketing", "PPC Advertising"] },
    { name: "UI/UX Design", subCourses: ["User Research", "Wireframing", "Prototyping", "Interaction Design", "Figma", "Adobe XD"] },
    { name: "Robotics", subCourses: ["Mechanical Design", "Electronics", "Control Systems", "Robot Programming", "ROS (Robot Operating System)"] },
    { name: "Finance and Investing", subCourses: ["Personal Finance", "Stock Market", "Cryptocurrency Investing", "Financial Analysis", "Investment Banking"] }
  ];

  const courseList = document.getElementById("course-list");
  const searchInput = document.getElementById("search-input");
  const filterSelect = document.getElementById("filter-select");
  const filterSubmitBtn = document.getElementById("filter-submit-btn");

  const renderCourses = (courses) => {
    courseList.innerHTML = ""; // Clear the list before rendering
    courses.forEach((course) => {
      const courseDiv = document.createElement("div");
      courseDiv.classList.add("course-item");

      const courseName = document.createElement("h3");
      courseName.textContent = course.name;

      const subCourseList = document.createElement("ul");
      course.subCourses.forEach((sub) => {
        const listItem = document.createElement("li");
        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.value = sub;
        checkbox.name = course.name;

        listItem.appendChild(checkbox);
        listItem.appendChild(document.createTextNode(sub));
        subCourseList.appendChild(listItem);
      });

      courseDiv.appendChild(courseName);
      courseDiv.appendChild(subCourseList);
      courseList.appendChild(courseDiv);
    });
  };

  // Fetch and render courses from the backend, with fallback
  fetch("/api/courses")
    .then((response) => response.json())
    .then((data) => renderCourses(data))
    .catch((error) => {
      console.error("Error fetching courses, loading fallback data:", error);
      renderCourses(fallbackCourses);
    });

  // Filter and search
  filterSubmitBtn.addEventListener("click", () => {
    const selectedCategory = filterSelect.value;
    const query = searchInput.value;

    fetch(`/api/courses/search?query=${query}&category=${selectedCategory}`)
      .then((response) => response.json())
      .then((data) => renderCourses(data))
      .catch((error) => console.error("Error fetching filtered courses:", error));
  });

  // Real-time search
  searchInput.addEventListener("input", () => {
    const searchTerm = searchInput.value.toLowerCase();
    fetch(`/api/courses/search?query=${searchTerm}&category=all`)
      .then((response) => response.json())
      .then((data) => renderCourses(data))
      .catch((error) => console.error("Error searching courses:", error));
  });

  // Handle course selection and checkout
  document.getElementById("checkout-btn").addEventListener("click", () => {
    const selectedCourses = [];
    document.querySelectorAll("input[type='checkbox']:checked").forEach((input) => {
      selectedCourses.push(input.value); // Store sub-course values
    });

    if (selectedCourses.length > 0) {
      fetch("/api/purchase", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId: 1, courses: selectedCourses }), // Replace `1` with actual user ID
      })
        .then((response) => response.json())
        .then((data) => alert(data.message))
        .catch((error) => console.error("Error purchasing courses:", error));
    } else {
      alert("Please select at least one course!");
    }
  });
});
