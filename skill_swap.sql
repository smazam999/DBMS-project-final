-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 10, 2024 at 09:27 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `skill_swap`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `access_course` (IN `userId` INT, IN `tokensRequired` INT)   BEGIN
    UPDATE users
    SET tokens = tokens - tokensRequired
    WHERE user_id = userId;

    INSERT INTO transactions (user_id, transaction_type, tokens)
    VALUES (userId, 'Deducted', -tokensRequired);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `buy_tokens` (IN `userId` INT, IN `tokenCount` INT, IN `amountPaid` DECIMAL(10,2))   BEGIN
    UPDATE user
    SET tokens = tokens + tokenCount
    WHERE user_id = userId;

    INSERT INTO transactions (user_id, transaction_type, tokens, amount)
    VALUES (userId, 'Purchase', tokenCount, amountPaid);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deactivate_inactive_users` ()   BEGIN
    UPDATE user
    SET status = 'Inactive'
    WHERE last_login < DATE_SUB(NOW(), INTERVAL 1 YEAR);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `find_courses_by_title` (IN `search_title` VARCHAR(255))   BEGIN
    SELECT course_id, course_name, course_description, tokens_earned, upload_date, user_id
    FROM courses
    WHERE course_name LIKE CONCAT('%', search_title, '%')
    ORDER BY course_name;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_attendance_report` (IN `start_date` DATE, IN `end_date` DATE)   BEGIN
    SELECT a.attendance_id, a.event_id, a.user_id, a.status, e.title
    FROM attendance a
    JOIN event e ON a.event_id = e.event_id
    WHERE e.start_time BETWEEN start_time AND end_time;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `give_course_review` (IN `user_id` INT, IN `course_id` INT, IN `rating` INT, IN `review_text` TEXT)   BEGIN
    -- Check if the user is eligible to review (e.g., completed the course)
    IF EXISTS (
        SELECT 1
        FROM transactions
        WHERE user_id = user_id AND transaction_type = 'Earned' AND course_id = course_id
    ) THEN
        -- Insert the review into the reviews table
        INSERT INTO reviews (user_id, course_id, rating, review_text)
        VALUES (user_id, course_id, rating, review_text);
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User is not eligible to review this course';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `read_messages` (IN `receiver_id` INT)   BEGIN
    -- Update all unread messages for the receiver to is_read = 1
    UPDATE messages
    SET is_read = 1
    WHERE receiver_id = receiver_id AND is_read = 0;

    -- Retrieve the updated messages for the receiver
    SELECT message_id, sender_id, receiver_id, message_text, sent_at, is_read
    FROM messages
    WHERE receiver_id = receiver_id
    ORDER BY sent_at DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `register_user` (IN `name` VARCHAR(100), IN `email` VARCHAR(100), IN `password` VARCHAR(255), IN `location` VARCHAR(100), IN `profile_picture` VARCHAR(255), IN `bio` TEXT, IN `verified_status` TINYINT(1), IN `tokens` INT, IN `event_count` INT, IN `status` VARCHAR(20))   BEGIN
    INSERT INTO `user` (
        `name`, `email`, `password`, `location`, `profile_picture`, 
        `bio`, `verified_status`, `tokens`, `event_count`, `status`
    )
    VALUES (
        name, email, password, location, profile_picture, 
        bio, verified_status, tokens, event_count, status
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `send_message` (IN `sender` INT, IN `receiver` INT, IN `message` TEXT)   BEGIN
    -- Insert the message into the messages table
    INSERT INTO messages (sender_id, receiver_id, message_text)
    VALUES (sender, receiver, message);

    -- Optional: You could log or perform additional actions here if needed
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_user_ranking` ()   BEGIN
    -- Loop through all users to calculate ranking scores
    DECLARE done INT DEFAULT FALSE;
    DECLARE userId INT;
    DECLARE userCursor CURSOR FOR SELECT user_id FROM user;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN userCursor;

    userLoop: LOOP
        FETCH userCursor INTO userId;
        IF done THEN
            LEAVE userLoop;
        END IF;

        -- Calculate ranking score based on reviews
        SET @positive_score = (
            SELECT COALESCE(AVG(rating) * 10, 0) -- Average rating multiplied by 10
            FROM reviews
            WHERE user_id = userId
        );

        -- Calculate penalty based on reports
        SET @negative_score = (
            SELECT COUNT(*)
            FROM reports
            WHERE reported_user_id = userId
        );

        -- Update the ranking score
        SET @final_score = GREATEST(@positive_score - (@negative_score * 5), 0); -- Deduct 5 points per report, minimum score is 0

        -- Update the user's ranking score in the user table
        UPDATE user
        SET ranking_score = @final_score
        WHERE user_id = userId;

        -- Assign rank based on the ranking score
        UPDATE user
        SET rank = CASE
            WHEN ranking_score >= 300 THEN 'Expert'
            WHEN ranking_score >= 200 THEN 'Advanced'
            WHEN ranking_score >= 100 THEN 'Intermediate'
            ELSE 'Beginner'
        END
        WHERE user_id = userId;
    END LOOP;

    CLOSE userCursor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `upload_course` (IN `userId` INT, IN `courseName` VARCHAR(255), IN `courseDesc` TEXT, IN `tokenReward` INT)   BEGIN
    INSERT INTO courses (user_id, course_name, course_description, tokens_earned)
    VALUES (userId, courseName, courseDesc, tokenReward);

    UPDATE user
    SET tokens = tokens + tokenReward
    WHERE user_id = userId;

    INSERT INTO transactions (user_id, transaction_type, tokens)
    VALUES (userId, 'Earned', tokenReward);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `active_users`
-- (See below for the actual view)
--
CREATE TABLE `active_users` (
`user_id` int(11)
,`name` varchar(100)
,`email` varchar(100)
);

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE `attendance` (
  `attendance_id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `status` varchar(50) DEFAULT NULL CHECK (`status` in ('Registered','Cancelled'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`attendance_id`, `event_id`, `user_id`, `status`) VALUES
(1, 1, 3, 'Registered'),
(2, 2, 4, 'Registered'),
(3, 3, 5, 'Cancelled'),
(4, 4, 6, 'Registered'),
(5, 5, 7, 'Registered'),
(6, 6, 8, 'Cancelled'),
(7, 7, 9, 'Registered'),
(8, 8, 10, 'Registered'),
(9, 9, 1, 'Cancelled'),
(10, 10, 2, 'Registered');

--
-- Triggers `attendance`
--
DELIMITER $$
CREATE TRIGGER `after_attendance_update` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    INSERT INTO attendance_audit (attendance_id, old_status, new_status, changed_at)
    VALUES (OLD.attendance_id, OLD.status, NEW.status, NOW());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `attendance_audit`
--

CREATE TABLE `attendance_audit` (
  `audit_id` int(11) NOT NULL,
  `attendance_id` int(11) NOT NULL,
  `old_status` varchar(50) NOT NULL,
  `new_status` varchar(50) NOT NULL,
  `changed_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `badge`
--

CREATE TABLE `badge` (
  `badge_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `badge_type` varchar(100) NOT NULL,
  `date_awarded` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `badge`
--

INSERT INTO `badge` (`badge_id`, `user_id`, `badge_type`, `date_awarded`) VALUES
(1, 1, 'Top Contributor', '2024-11-12 17:14:24'),
(2, 2, 'Verified User', '2024-11-12 17:14:24'),
(3, 3, 'Mentor', '2024-11-12 17:14:24'),
(4, 4, 'Active Participant', '2024-11-12 17:14:24'),
(5, 5, 'Workshop Host', '2024-11-12 17:14:24'),
(6, 6, 'Top Learner', '2024-11-12 17:14:24'),
(7, 7, 'Skill Sharer', '2024-11-12 17:14:24'),
(8, 8, 'Community Builder', '2024-11-12 17:14:24'),
(9, 9, 'Rising Star', '2024-11-12 17:14:24'),
(10, 10, 'Skill Seeker', '2024-11-12 17:14:24');

-- --------------------------------------------------------

--
-- Table structure for table `certificate`
--

CREATE TABLE `certificate` (
  `certificate_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `event_id` int(11) DEFAULT NULL,
  `skill_id` int(11) NOT NULL,
  `issue_date` date DEFAULT curdate(),
  `certificate_type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `certificate`
--

INSERT INTO `certificate` (`certificate_id`, `user_id`, `event_id`, `skill_id`, `issue_date`, `certificate_type`) VALUES
(1, 1, 1, 2, '2024-02-05', 'Completion'),
(2, 2, 2, 3, '2024-03-10', 'Participation'),
(3, 3, 3, 4, '2024-04-15', 'Completion'),
(4, 4, 4, 5, '2024-05-20', 'Participation'),
(5, 5, 5, 6, '2024-06-25', 'Completion'),
(6, 6, 6, 7, '2024-07-30', 'Participation'),
(7, 7, 7, 8, '2024-08-05', 'Completion'),
(8, 8, 8, 9, '2024-09-10', 'Completion'),
(9, 9, 9, 10, '2024-10-15', 'Participation'),
(10, 10, 10, 1, '2024-11-20', 'Completion');

-- --------------------------------------------------------

--
-- Table structure for table `courses`
--

CREATE TABLE `courses` (
  `course_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `course_name` varchar(255) NOT NULL,
  `course_description` text DEFAULT NULL,
  `tokens_earned` int(11) DEFAULT 0,
  `upload_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `courses`
--

INSERT INTO `courses` (`course_id`, `user_id`, `course_name`, `course_description`, `tokens_earned`, `upload_date`) VALUES
(1, 1, 'Introduction to Python', 'Learn the basics of Python programming.', 10, '2024-12-03 23:46:23'),
(2, 2, 'Web Development Fundamentals', 'HTML, CSS, and JavaScript basics.', 15, '2024-12-03 23:46:23'),
(3, 3, 'Data Science with R', 'Explore data analysis and visualization in R.', 20, '2024-12-03 23:46:23'),
(4, 4, 'Advanced SQL Techniques', 'Deep dive into SQL optimizations.', 25, '2024-12-03 23:46:23'),
(5, 5, 'Machine Learning Basics', 'Get started with ML concepts.', 30, '2024-12-03 23:46:23'),
(6, 6, 'Blockchain Essentials', 'Understanding blockchain technology.', 15, '2024-12-03 23:46:23'),
(7, 7, 'Cybersecurity 101', 'Learn to secure your digital footprint.', 10, '2024-12-03 23:46:23'),
(8, 8, 'Cloud Computing Overview', 'An introduction to cloud systems.', 20, '2024-12-03 23:46:23'),
(9, 9, 'DevOps Practices', 'Streamlining development and operations.', 25, '2024-12-03 23:46:23'),
(10, 10, 'Artificial Intelligence Intro', 'Basics of AI and neural networks.', 30, '2024-12-03 23:46:23');

-- --------------------------------------------------------

--
-- Stand-in structure for view `course_earnings`
-- (See below for the actual view)
--
CREATE TABLE `course_earnings` (
`course_name` varchar(255)
,`tokens_earned` int(11)
,`uploader` varchar(100)
,`upload_date` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `course_purchases`
--

CREATE TABLE `course_purchases` (
  `purchase_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `tokens_required` int(11) NOT NULL,
  `purchase_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `course_purchases`
--

INSERT INTO `course_purchases` (`purchase_id`, `user_id`, `course_id`, `tokens_required`, `purchase_date`) VALUES
(1, 1, 1, 10, '2024-12-04 01:21:19'),
(2, 2, 2, 15, '2024-12-04 01:21:19'),
(3, 3, 3, 20, '2024-12-04 01:21:19'),
(4, 4, 4, 25, '2024-12-04 01:21:19'),
(5, 5, 5, 30, '2024-12-04 01:21:19'),
(6, 1, 5, 30, '2024-12-04 01:22:32');

--
-- Triggers `course_purchases`
--
DELIMITER $$
CREATE TRIGGER `after_course_purchase` AFTER INSERT ON `course_purchases` FOR EACH ROW BEGIN
    -- Check if the user has enough tokens to purchase the course
    IF (SELECT tokens FROM `user` WHERE user_id = NEW.user_id) >= NEW.tokens_required THEN
        -- Deduct the tokens from the user's account
        UPDATE `user`
        SET tokens = tokens - NEW.tokens_required
        WHERE user_id = NEW.user_id;
    ELSE
        -- Raise an error if the user does not have enough tokens
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient tokens for course purchase.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `event`
--

CREATE TABLE `event` (
  `event_id` int(11) NOT NULL,
  `organizer_id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `max_attendees` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `event`
--

INSERT INTO `event` (`event_id`, `organizer_id`, `title`, `description`, `location`, `start_time`, `end_time`, `max_attendees`, `created_at`) VALUES
(1, 1, 'Photography Workshop', 'Learn basic photography skills.', 'New York', '2024-10-10 10:00:00', '2024-10-10 12:00:00', 30, '2024-11-12 17:13:21'),
(2, 2, 'SEO Basics', 'Introduction to SEO.', 'Los Angeles', '2024-11-12 14:00:00', '2024-11-12 16:00:00', 25, '2024-11-12 17:13:21'),
(3, 3, 'Data Analysis Intro', 'Learn data analysis basics.', 'Chicago', '2024-12-15 09:00:00', '2024-12-15 11:00:00', 20, '2024-11-12 17:13:21'),
(4, 4, 'Public Speaking 101', 'Improve your public speaking.', 'Houston', '2024-09-20 15:00:00', '2024-09-20 17:00:00', 50, '2024-11-12 17:13:21'),
(5, 5, 'Python Programming', 'Introduction to Python.', 'Phoenix', '2024-08-01 13:00:00', '2024-08-01 15:00:00', 40, '2024-11-12 17:13:21'),
(6, 6, 'Content Writing', 'Write compelling content.', 'Philadelphia', '2024-10-25 10:00:00', '2024-10-25 12:00:00', 35, '2024-11-12 17:13:21'),
(7, 7, 'Social Media Marketing', 'Master social media.', 'San Antonio', '2024-11-05 11:00:00', '2024-11-05 13:00:00', 50, '2024-11-12 17:13:21'),
(8, 8, 'Project Management', 'Manage projects efficiently.', 'Dallas', '2024-07-15 09:00:00', '2024-07-15 11:00:00', 45, '2024-11-12 17:13:21'),
(9, 9, 'UX Research Basics', 'Introduction to UX research.', 'San Jose', '2024-09-23 16:00:00', '2024-09-23 18:00:00', 40, '2024-11-12 17:13:21'),
(10, 10, 'Advanced Web Dev', 'Take your web skills to the next level.', 'Austin', '2024-12-10 14:00:00', '2024-12-10 17:00:00', 60, '2024-11-12 17:13:21');

-- --------------------------------------------------------

--
-- Stand-in structure for view `event_attendee_count`
-- (See below for the actual view)
--
CREATE TABLE `event_attendee_count` (
`event_id` int(11)
,`title` varchar(100)
,`attendee_count` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `forum`
--

CREATE TABLE `forum` (
  `forum_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `content` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` varchar(50) DEFAULT 'Open'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `forum`
--

INSERT INTO `forum` (`forum_id`, `user_id`, `title`, `content`, `created_at`, `status`) VALUES
(1, 1, 'Web Development Basics', 'Let’s discuss the basics of web development.', '2024-11-13 08:31:11', 'Open'),
(2, 2, 'Digital Marketing Tips', 'Share your best practices for digital marketing.', '2024-11-13 08:31:11', 'Open'),
(3, 3, 'Photography Techniques', 'Discuss the best techniques in photography.', '2024-11-13 08:31:11', 'Closed'),
(4, 4, 'Data Science Resources', 'Resources and tips for learning data science.', '2024-11-13 08:31:11', 'Open'),
(5, 5, 'Social Media Strategy', 'How to build a strong social media presence.', '2024-11-13 08:31:11', 'Archived'),
(6, 6, 'Coding Challenges', 'Weekly coding challenges for beginners.', '2024-11-13 08:31:11', 'Open'),
(7, 7, 'Public Speaking Tips', 'How to improve your public speaking skills.', '2024-11-13 08:31:11', 'Open'),
(8, 8, 'SEO Optimization', 'Best SEO strategies for 2024.', '2024-11-13 08:31:11', 'Closed'),
(9, 9, 'Project Management', 'Tools and tips for effective project management.', '2024-11-13 08:31:11', 'Open'),
(10, 10, 'Content Writing Advice', 'Advice for aspiring content writers.', '2024-11-13 08:31:11', 'Archived');

-- --------------------------------------------------------

--
-- Table structure for table `friendship`
--

CREATE TABLE `friendship` (
  `friendship_id` int(11) NOT NULL,
  `user_id1` int(11) NOT NULL,
  `user_id2` int(11) NOT NULL,
  `status` varchar(50) DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `friendship`
--

INSERT INTO `friendship` (`friendship_id`, `user_id1`, `user_id2`, `status`, `created_at`) VALUES
(1, 1, 2, 'Accepted', '2024-11-13 08:31:11'),
(2, 1, 3, 'Pending', '2024-11-13 08:31:11'),
(3, 2, 4, 'Accepted', '2024-11-13 08:31:11'),
(4, 3, 5, 'Pending', '2024-11-13 08:31:11'),
(5, 4, 6, 'Accepted', '2024-11-13 08:31:11'),
(6, 5, 7, 'Rejected', '2024-11-13 08:31:11'),
(7, 6, 8, 'Accepted', '2024-11-13 08:31:11'),
(8, 7, 9, 'Pending', '2024-11-13 08:31:11'),
(9, 8, 10, 'Accepted', '2024-11-13 08:31:11'),
(10, 9, 1, 'Rejected', '2024-11-13 08:31:11');

-- --------------------------------------------------------

--
-- Table structure for table `goal`
--

CREATE TABLE `goal` (
  `goal_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `skill_id` int(11) NOT NULL,
  `goal_description` text DEFAULT NULL,
  `completion_status` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `goal`
--

INSERT INTO `goal` (`goal_id`, `user_id`, `skill_id`, `goal_description`, `completion_status`) VALUES
(1, 1, 2, 'Master basic web development.', 0),
(2, 2, 3, 'Become a proficient content writer.', 0),
(3, 3, 4, 'Develop data analysis skills.', 0),
(4, 4, 5, 'Learn SEO strategies.', 1),
(5, 5, 6, 'Understand social media marketing.', 0),
(6, 6, 7, 'Improve photography skills.', 1),
(7, 7, 8, 'Learn project management basics.', 0),
(8, 8, 9, 'Develop public speaking abilities.', 1),
(9, 9, 10, 'Gain proficiency in Python.', 0),
(10, 10, 1, 'Learn graphic design.', 1);

-- --------------------------------------------------------

--
-- Table structure for table `match`
--

CREATE TABLE `match` (
  `match_id` int(11) NOT NULL,
  `user1_id` int(11) NOT NULL,
  `user2_id` int(11) NOT NULL,
  `skill_id` int(11) NOT NULL,
  `status` varchar(50) DEFAULT NULL CHECK (`status` in ('Pending','Accepted','Completed')),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `match`
--

INSERT INTO `match` (`match_id`, `user1_id`, `user2_id`, `skill_id`, `status`, `created_at`) VALUES
(1, 1, 3, 1, 'Pending', '2024-11-12 17:12:08'),
(2, 2, 4, 2, 'Accepted', '2024-11-12 17:12:08'),
(3, 3, 5, 3, 'Completed', '2024-11-12 17:12:08'),
(4, 4, 6, 4, 'Pending', '2024-11-12 17:12:08'),
(5, 5, 7, 5, 'Accepted', '2024-11-12 17:12:08'),
(6, 6, 8, 6, 'Completed', '2024-11-12 17:12:08'),
(7, 7, 9, 7, 'Pending', '2024-11-12 17:12:08'),
(8, 8, 10, 8, 'Accepted', '2024-11-12 17:12:08'),
(9, 9, 1, 9, 'Completed', '2024-11-12 17:12:08'),
(10, 10, 2, 10, 'Pending', '2024-11-12 17:12:08');

-- --------------------------------------------------------

--
-- Table structure for table `match_audit`
--

CREATE TABLE `match_audit` (
  `audit_id` int(11) NOT NULL,
  `match_id` int(11) NOT NULL,
  `user1_id` int(11) NOT NULL,
  `user2_id` int(11) NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) DEFAULT NULL,
  `changed_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `message_id` int(11) NOT NULL,
  `sender_id` int(11) NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `message_text` text NOT NULL,
  `sent_at` datetime DEFAULT current_timestamp(),
  `is_read` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`message_id`, `sender_id`, `receiver_id`, `message_text`, `sent_at`, `is_read`) VALUES
(1, 1, 2, 'Hello, how are you?', '2024-12-04 02:17:05', 1),
(2, 3, 5, 'Don’t forget to check the new course!', '2024-12-04 02:18:02', 1);

-- --------------------------------------------------------

--
-- Stand-in structure for view `message_view`
-- (See below for the actual view)
--
CREATE TABLE `message_view` (
`message_id` int(11)
,`sender_id` int(11)
,`sender_name` varchar(100)
,`receiver_id` int(11)
,`receiver_name` varchar(100)
,`message_text` text
,`sent_at` datetime
,`is_read` tinyint(1)
);

-- --------------------------------------------------------

--
-- Table structure for table `notification`
--

CREATE TABLE `notification` (
  `notification_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `message` text NOT NULL,
  `status` varchar(50) DEFAULT 'Unread',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notification`
--

INSERT INTO `notification` (`notification_id`, `user_id`, `type`, `message`, `status`, `created_at`) VALUES
(1, 1, 'Match Request', 'You have a new match request.', 'Unread', '2024-11-13 08:28:09'),
(2, 2, 'Reminder', 'Complete your profile for better matches.', 'Unread', '2024-11-13 08:28:09'),
(3, 3, 'Update', 'New feature added to the platform.', 'Read', '2024-11-13 08:28:09'),
(4, 4, 'Match Request', 'Someone wants to learn your skill.', 'Unread', '2024-11-13 08:28:09'),
(5, 5, 'Reminder', 'Join the upcoming event for skill exchange.', 'Unread', '2024-11-13 08:28:09'),
(6, 6, 'Update', 'Your profile is now verified.', 'Read', '2024-11-13 08:28:09'),
(7, 7, 'Match Request', 'New skill request received.', 'Unread', '2024-11-13 08:28:09'),
(8, 8, 'Update', 'Check your new badge in your profile.', 'Read', '2024-11-13 08:28:09'),
(9, 9, 'Match Request', 'Someone is interested in your skill.', 'Unread', '2024-11-13 08:28:09'),
(10, 10, 'Reminder', 'Attend the event in Dhaka to connect.', 'Unread', '2024-11-13 08:28:09');

-- --------------------------------------------------------

--
-- Table structure for table `paymentmethod`
--

CREATE TABLE `paymentmethod` (
  `payment_method_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `method_type` varchar(50) NOT NULL,
  `details` varchar(255) DEFAULT NULL,
  `expiry_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `paymentmethod`
--

INSERT INTO `paymentmethod` (`payment_method_id`, `user_id`, `method_type`, `details`, `expiry_date`) VALUES
(1, 1, 'Credit Card', 'Visa ****1234', '2025-12-31'),
(2, 2, 'Credit Card', 'MasterCard ****5678', '2024-11-30'),
(3, 3, 'PayPal', 'example1@paypal.com', NULL),
(4, 4, 'Credit Card', 'Visa ****4321', '2026-01-15'),
(5, 5, 'PayPal', 'example2@paypal.com', NULL),
(6, 6, 'Credit Card', 'MasterCard ****8765', '2023-12-31'),
(7, 7, 'Credit Card', 'Visa ****5678', '2024-06-30'),
(8, 8, 'PayPal', 'example3@paypal.com', NULL),
(9, 9, 'Credit Card', 'Visa ****7890', '2025-09-30'),
(10, 10, 'Credit Card', 'MasterCard ****3456', '2025-03-15');

-- --------------------------------------------------------

--
-- Table structure for table `post`
--

CREATE TABLE `post` (
  `post_id` int(11) NOT NULL,
  `forum_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `content` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` varchar(50) DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `post`
--

INSERT INTO `post` (`post_id`, `forum_id`, `user_id`, `content`, `created_at`, `status`) VALUES
(1, 1, 1, 'Web development requires strong HTML skills.', '2024-11-13 08:31:11', 'Active'),
(2, 1, 2, 'JavaScript is also essential for web development.', '2024-11-13 08:31:11', 'Active'),
(3, 2, 3, 'Content creation is key for digital marketing.', '2024-11-13 08:31:11', 'Active'),
(4, 3, 4, 'Focus on lighting for better photography.', '2024-11-13 08:31:11', 'Active'),
(5, 4, 5, 'Python is popular for data science tasks.', '2024-11-13 08:31:11', 'Active'),
(6, 5, 6, 'Define your brand for effective marketing.', '2024-11-13 08:31:11', 'Deleted'),
(7, 6, 7, 'Challenge: Build a calculator app in JavaScript.', '2024-11-13 08:31:11', 'Active'),
(8, 7, 8, 'Practice by speaking in front of a mirror.', '2024-11-13 08:31:11', 'Active'),
(9, 8, 9, 'Use keywords effectively in SEO.', '2024-11-13 08:31:11', 'Deleted'),
(10, 9, 10, 'Agile methodologies work well for projects.', '2024-11-13 08:31:11', 'Active');

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `report_id` int(11) NOT NULL,
  `reported_user_id` int(11) NOT NULL,
  `reason` text NOT NULL,
  `report_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `review_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` between 1 and 5),
  `review_text` text DEFAULT NULL,
  `review_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`review_id`, `user_id`, `course_id`, `rating`, `review_text`, `review_date`) VALUES
(1, 1, 3, 5, 'Excellent course! Very informative.', '2024-12-04 02:34:46'),
(2, 2, 5, 4, 'Good course, but could be improved.', '2024-12-04 02:35:00'),
(4, 5, 5, 3, 'very beautiful !!!!!', '2024-12-04 02:36:09');

-- --------------------------------------------------------

--
-- Table structure for table `skill`
--

CREATE TABLE `skill` (
  `skill_id` int(11) NOT NULL,
  `skill_name` varchar(100) NOT NULL,
  `skill_description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `skill`
--

INSERT INTO `skill` (`skill_id`, `skill_name`, `skill_description`) VALUES
(1, 'Graphic Design', 'Creating visual content using software.'),
(2, 'Web Development', 'Building and maintaining websites.'),
(3, 'Content Writing', 'Creating written content for various platforms.'),
(4, 'Data Analysis', 'Analyzing data to extract insights.'),
(5, 'SEO', 'Optimizing content for search engines.'),
(6, 'Social Media Marketing', 'Promoting brands on social media.'),
(7, 'Photography', 'Taking and editing photos.'),
(8, 'Project Management', 'Planning and overseeing projects.'),
(9, 'Public Speaking', 'Delivering speeches and presentations.'),
(10, 'Python Programming', 'Programming in Python.');

-- --------------------------------------------------------

--
-- Table structure for table `subscription`
--

CREATE TABLE `subscription` (
  `subscription_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `plan_type` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `status` varchar(50) DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subscription`
--

INSERT INTO `subscription` (`subscription_id`, `user_id`, `plan_type`, `start_date`, `end_date`, `status`) VALUES
(1, 1, 'Premium', '2024-01-01', '2024-12-31', 'Active'),
(2, 2, 'Free', '2024-01-15', NULL, 'Active'),
(3, 3, 'Premium', '2024-02-01', '2025-01-31', 'Active'),
(4, 4, 'Free', '2024-03-10', NULL, 'Active'),
(5, 5, 'Premium', '2024-04-01', '2024-12-31', 'Expired'),
(6, 6, 'Premium', '2024-05-01', '2025-04-30', 'Active'),
(7, 7, 'Free', '2024-06-15', NULL, 'Active'),
(8, 8, 'Premium', '2024-07-01', '2025-06-30', 'Active'),
(9, 9, 'Free', '2024-08-05', NULL, 'Active'),
(10, 10, 'Premium', '2024-09-01', '2025-08-31', 'Active');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `transaction_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `transaction_type` enum('Purchase','Earned') DEFAULT NULL,
  `tokens` int(11) NOT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `transaction_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`transaction_id`, `user_id`, `transaction_type`, `tokens`, `amount`, `transaction_date`) VALUES
(1, 1, 'Purchase', 50, 500.00, '2024-12-03 23:44:12'),
(2, 1, 'Purchase', 50, 500.00, '2024-12-03 23:46:23'),
(3, 2, 'Purchase', 30, 300.00, '2024-12-03 23:46:23'),
(4, 3, 'Earned', 20, NULL, '2024-12-03 23:46:23'),
(5, 4, 'Earned', 15, NULL, '2024-12-03 23:46:23'),
(6, 5, 'Purchase', 40, 400.00, '2024-12-03 23:46:23'),
(7, 6, 'Earned', 25, NULL, '2024-12-03 23:46:23'),
(8, 7, 'Purchase', 60, 600.00, '2024-12-03 23:46:23'),
(9, 8, 'Earned', 10, NULL, '2024-12-03 23:46:23'),
(10, 9, 'Purchase', 20, 200.00, '2024-12-03 23:46:23'),
(11, 10, 'Earned', 5, NULL, '2024-12-03 23:46:23'),
(12, 1, 'Purchase', 50, 500.00, '2024-12-04 01:14:33'),
(13, 1, 'Purchase', 50, 500.00, '2024-12-04 01:41:12');

--
-- Triggers `transactions`
--
DELIMITER $$
CREATE TRIGGER `after_token_purchase` AFTER INSERT ON `transactions` FOR EACH ROW BEGIN
    -- Check if the transaction type is 'Purchase'
    IF NEW.transaction_type = 'Purchase' THEN
        -- Update the user's tokens in the `user` table
        UPDATE `user`
        SET tokens = tokens + NEW.tokens
        WHERE user_id = NEW.user_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `user_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `location` varchar(100) DEFAULT NULL,
  `profile_picture` varchar(255) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `verified_status` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `tokens` int(11) DEFAULT 0,
  `event_count` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `ranking_score` int(11) DEFAULT 0,
  `rank` varchar(20) DEFAULT 'Beginner'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`user_id`, `name`, `email`, `password`, `location`, `profile_picture`, `bio`, `verified_status`, `created_at`, `tokens`, `event_count`, `status`, `ranking_score`, `rank`) VALUES
(1, 'Anika', 'anika@example.com', 'password123', 'Dhaka', 'anika.jpg', 'Graphic designer.', 1, '2024-11-12 17:09:44', 170, NULL, 'Active', 50, 'Beginner'),
(2, 'Rakib', 'rahim@example.com', 'password456', 'Chittagong', 'rahim.jpg', 'Software developer.', 1, '2024-11-12 17:09:44', 0, NULL, 'Active', 40, 'Beginner'),
(3, 'Farhana', 'farhana@example.com', 'password789', 'Sylhet', 'farhana.jpg', 'Digital marketer.', 0, '2024-11-12 17:09:44', 0, NULL, 'Active', 0, 'Beginner'),
(4, 'Javed', 'javed@example.com', 'password101', 'Khulna', 'javed.jpg', 'Web designer.', 1, '2024-11-12 17:09:44', 0, NULL, 'Active', 0, 'Beginner'),
(5, 'Shirin', 'shirin@example.com', 'password202', 'Rajshahi', 'shirin.jpg', 'Content writer.', 1, '2024-11-12 17:09:44', 0, NULL, 'Active', 30, 'Beginner'),
(6, 'Kamal', 'kamal@example.com', 'password303', 'Barisal', 'kamal.jpg', 'Data analyst.', 0, '2024-11-12 17:09:44', 0, NULL, 'Active', 0, 'Beginner'),
(7, 'Shabnam', 'shabnam@example.com', 'password404', 'Mymensingh', 'shabnam.jpg', 'SEO expert.', 1, '2024-11-12 17:09:44', 0, NULL, 'Active', 0, 'Beginner'),
(8, 'Tania', 'tania@example.com', 'password505', 'Rangpur', 'tania.jpg', 'Graphic designer.', 0, '2024-11-12 17:09:44', 0, NULL, 'Active', 0, 'Beginner'),
(9, 'Nila', 'nila@example.com', 'password606', 'Comilla', 'nila.jpg', 'UX researcher.', 1, '2024-11-12 17:09:44', 0, NULL, 'Active', 0, 'Beginner'),
(10, 'Omar', 'omar@example.com', 'password707', 'Bogura', 'omar.jpg', 'Backend developer.', 1, '2024-11-12 17:09:44', 0, NULL, 'Active', 0, 'Beginner');

-- --------------------------------------------------------

--
-- Table structure for table `usermatch`
--

CREATE TABLE `usermatch` (
  `match_id` int(11) NOT NULL,
  `user1_id` int(11) NOT NULL,
  `user2_id` int(11) NOT NULL,
  `skill_id` int(11) NOT NULL,
  `status` varchar(50) DEFAULT NULL CHECK (`status` in ('Pending','Accepted','Completed')),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `usermatch`
--
DELIMITER $$
CREATE TRIGGER `after_match_status_update` AFTER UPDATE ON `usermatch` FOR EACH ROW BEGIN
    -- Check if the status has changed
    IF OLD.status <> NEW.status THEN
        INSERT INTO match_audit (match_id, user1_id, user2_id, old_status, new_status, changed_at)
        VALUES (OLD.match_id, OLD.user1_id, OLD.user2_id, OLD.status, NEW.status, NOW());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `userskill`
--

CREATE TABLE `userskill` (
  `user_skill_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `skill_id` int(11) NOT NULL,
  `proficiency_level` varchar(50) DEFAULT NULL,
  `role` varchar(50) DEFAULT NULL CHECK (`role` in ('Offering','Seeking')),
  `verification_status` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `userskill`
--

INSERT INTO `userskill` (`user_skill_id`, `user_id`, `skill_id`, `proficiency_level`, `role`, `verification_status`) VALUES
(1, 1, 1, 'Intermediate', 'Offering', 1),
(2, 2, 2, 'Advanced', 'Offering', 1),
(3, 3, 3, 'Beginner', 'Seeking', 0),
(4, 4, 4, 'Advanced', 'Offering', 1),
(5, 5, 5, 'Intermediate', 'Seeking', 1),
(6, 6, 6, 'Beginner', 'Offering', 0),
(7, 7, 7, 'Advanced', 'Seeking', 1),
(8, 8, 8, 'Intermediate', 'Offering', 0),
(9, 9, 9, 'Advanced', 'Seeking', 1),
(10, 10, 10, 'Intermediate', 'Offering', 1);

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_ranking_view`
-- (See below for the actual view)
--
CREATE TABLE `user_ranking_view` (
`user_id` int(11)
,`name` varchar(100)
,`email` varchar(100)
,`location` varchar(100)
,`ranking_score` int(11)
,`rank` varchar(20)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_token_balance`
-- (See below for the actual view)
--
CREATE TABLE `user_token_balance` (
`user_id` int(11)
,`name` varchar(100)
,`tokens` int(11)
,`transaction_type` enum('Purchase','Earned')
,`token_change` int(11)
,`amount` decimal(10,2)
,`transaction_date` datetime
);

-- --------------------------------------------------------

--
-- Structure for view `active_users`
--
DROP TABLE IF EXISTS `active_users`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `active_users`  AS SELECT `user`.`user_id` AS `user_id`, `user`.`name` AS `name`, `user`.`email` AS `email` FROM `user` WHERE `user`.`status` = 'Active' ;

-- --------------------------------------------------------

--
-- Structure for view `course_earnings`
--
DROP TABLE IF EXISTS `course_earnings`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `course_earnings`  AS SELECT `c`.`course_name` AS `course_name`, `c`.`tokens_earned` AS `tokens_earned`, `u`.`name` AS `uploader`, `c`.`upload_date` AS `upload_date` FROM (`courses` `c` join `user` `u` on(`c`.`user_id` = `u`.`user_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `event_attendee_count`
--
DROP TABLE IF EXISTS `event_attendee_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `event_attendee_count`  AS SELECT `e`.`event_id` AS `event_id`, `e`.`title` AS `title`, count(`a`.`attendance_id`) AS `attendee_count` FROM (`event` `e` left join `attendance` `a` on(`e`.`event_id` = `a`.`event_id`)) GROUP BY `e`.`event_id`, `e`.`title` ;

-- --------------------------------------------------------

--
-- Structure for view `message_view`
--
DROP TABLE IF EXISTS `message_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `message_view`  AS SELECT `m`.`message_id` AS `message_id`, `m`.`sender_id` AS `sender_id`, `s`.`name` AS `sender_name`, `m`.`receiver_id` AS `receiver_id`, `r`.`name` AS `receiver_name`, `m`.`message_text` AS `message_text`, `m`.`sent_at` AS `sent_at`, `m`.`is_read` AS `is_read` FROM ((`messages` `m` join `user` `s` on(`m`.`sender_id` = `s`.`user_id`)) join `user` `r` on(`m`.`receiver_id` = `r`.`user_id`)) ORDER BY `m`.`sent_at` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `user_ranking_view`
--
DROP TABLE IF EXISTS `user_ranking_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_ranking_view`  AS SELECT `user`.`user_id` AS `user_id`, `user`.`name` AS `name`, `user`.`email` AS `email`, `user`.`location` AS `location`, `user`.`ranking_score` AS `ranking_score`, `user`.`rank` AS `rank` FROM `user` ORDER BY `user`.`ranking_score` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `user_token_balance`
--
DROP TABLE IF EXISTS `user_token_balance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_token_balance`  AS SELECT `u`.`user_id` AS `user_id`, `u`.`name` AS `name`, `u`.`tokens` AS `tokens`, `t`.`transaction_type` AS `transaction_type`, `t`.`tokens` AS `token_change`, `t`.`amount` AS `amount`, `t`.`transaction_date` AS `transaction_date` FROM (`user` `u` left join `transactions` `t` on(`u`.`user_id` = `t`.`user_id`)) ORDER BY `t`.`transaction_date` DESC ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`attendance_id`),
  ADD KEY `event_id` (`event_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `attendance_audit`
--
ALTER TABLE `attendance_audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `attendance_id` (`attendance_id`);

--
-- Indexes for table `badge`
--
ALTER TABLE `badge`
  ADD PRIMARY KEY (`badge_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `certificate`
--
ALTER TABLE `certificate`
  ADD PRIMARY KEY (`certificate_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `event_id` (`event_id`),
  ADD KEY `skill_id` (`skill_id`);

--
-- Indexes for table `courses`
--
ALTER TABLE `courses`
  ADD PRIMARY KEY (`course_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `course_purchases`
--
ALTER TABLE `course_purchases`
  ADD PRIMARY KEY (`purchase_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `course_id` (`course_id`);

--
-- Indexes for table `event`
--
ALTER TABLE `event`
  ADD PRIMARY KEY (`event_id`),
  ADD KEY `organizer_id` (`organizer_id`);

--
-- Indexes for table `forum`
--
ALTER TABLE `forum`
  ADD PRIMARY KEY (`forum_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `friendship`
--
ALTER TABLE `friendship`
  ADD PRIMARY KEY (`friendship_id`),
  ADD KEY `user_id1` (`user_id1`),
  ADD KEY `user_id2` (`user_id2`);

--
-- Indexes for table `goal`
--
ALTER TABLE `goal`
  ADD PRIMARY KEY (`goal_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `skill_id` (`skill_id`);

--
-- Indexes for table `match`
--
ALTER TABLE `match`
  ADD PRIMARY KEY (`match_id`),
  ADD KEY `user1_id` (`user1_id`),
  ADD KEY `user2_id` (`user2_id`),
  ADD KEY `skill_id` (`skill_id`);

--
-- Indexes for table `match_audit`
--
ALTER TABLE `match_audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `match_id` (`match_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `sender_id` (`sender_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `notification`
--
ALTER TABLE `notification`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `paymentmethod`
--
ALTER TABLE `paymentmethod`
  ADD PRIMARY KEY (`payment_method_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `post`
--
ALTER TABLE `post`
  ADD PRIMARY KEY (`post_id`),
  ADD KEY `forum_id` (`forum_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `reported_user_id` (`reported_user_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `course_id` (`course_id`);

--
-- Indexes for table `skill`
--
ALTER TABLE `skill`
  ADD PRIMARY KEY (`skill_id`);

--
-- Indexes for table `subscription`
--
ALTER TABLE `subscription`
  ADD PRIMARY KEY (`subscription_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `usermatch`
--
ALTER TABLE `usermatch`
  ADD PRIMARY KEY (`match_id`),
  ADD KEY `user1_id` (`user1_id`),
  ADD KEY `user2_id` (`user2_id`),
  ADD KEY `skill_id` (`skill_id`);

--
-- Indexes for table `userskill`
--
ALTER TABLE `userskill`
  ADD PRIMARY KEY (`user_skill_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `skill_id` (`skill_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `attendance_audit`
--
ALTER TABLE `attendance_audit`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `certificate`
--
ALTER TABLE `certificate`
  MODIFY `certificate_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `courses`
--
ALTER TABLE `courses`
  MODIFY `course_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `course_purchases`
--
ALTER TABLE `course_purchases`
  MODIFY `purchase_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `forum`
--
ALTER TABLE `forum`
  MODIFY `forum_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `friendship`
--
ALTER TABLE `friendship`
  MODIFY `friendship_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `match_audit`
--
ALTER TABLE `match_audit`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `notification`
--
ALTER TABLE `notification`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `paymentmethod`
--
ALTER TABLE `paymentmethod`
  MODIFY `payment_method_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `post`
--
ALTER TABLE `post`
  MODIFY `post_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `subscription`
--
ALTER TABLE `subscription`
  MODIFY `subscription_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `usermatch`
--
ALTER TABLE `usermatch`
  MODIFY `match_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `event` (`event_id`),
  ADD CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `attendance_audit`
--
ALTER TABLE `attendance_audit`
  ADD CONSTRAINT `attendance_audit_ibfk_1` FOREIGN KEY (`attendance_id`) REFERENCES `attendance` (`attendance_id`);

--
-- Constraints for table `badge`
--
ALTER TABLE `badge`
  ADD CONSTRAINT `badge_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `certificate`
--
ALTER TABLE `certificate`
  ADD CONSTRAINT `certificate_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `certificate_ibfk_2` FOREIGN KEY (`event_id`) REFERENCES `event` (`event_id`),
  ADD CONSTRAINT `certificate_ibfk_3` FOREIGN KEY (`skill_id`) REFERENCES `skill` (`skill_id`);

--
-- Constraints for table `courses`
--
ALTER TABLE `courses`
  ADD CONSTRAINT `courses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `course_purchases`
--
ALTER TABLE `course_purchases`
  ADD CONSTRAINT `course_purchases_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `course_purchases_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`);

--
-- Constraints for table `event`
--
ALTER TABLE `event`
  ADD CONSTRAINT `event_ibfk_1` FOREIGN KEY (`organizer_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `forum`
--
ALTER TABLE `forum`
  ADD CONSTRAINT `forum_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `friendship`
--
ALTER TABLE `friendship`
  ADD CONSTRAINT `friendship_ibfk_1` FOREIGN KEY (`user_id1`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `friendship_ibfk_2` FOREIGN KEY (`user_id2`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `goal`
--
ALTER TABLE `goal`
  ADD CONSTRAINT `goal_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `goal_ibfk_2` FOREIGN KEY (`skill_id`) REFERENCES `skill` (`skill_id`);

--
-- Constraints for table `match`
--
ALTER TABLE `match`
  ADD CONSTRAINT `match_ibfk_1` FOREIGN KEY (`user1_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `match_ibfk_2` FOREIGN KEY (`user2_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `match_ibfk_3` FOREIGN KEY (`skill_id`) REFERENCES `skill` (`skill_id`);

--
-- Constraints for table `match_audit`
--
ALTER TABLE `match_audit`
  ADD CONSTRAINT `match_audit_ibfk_1` FOREIGN KEY (`match_id`) REFERENCES `usermatch` (`match_id`);

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `notification`
--
ALTER TABLE `notification`
  ADD CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `paymentmethod`
--
ALTER TABLE `paymentmethod`
  ADD CONSTRAINT `paymentmethod_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `post`
--
ALTER TABLE `post`
  ADD CONSTRAINT `post_ibfk_1` FOREIGN KEY (`forum_id`) REFERENCES `forum` (`forum_id`),
  ADD CONSTRAINT `post_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`reported_user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`);

--
-- Constraints for table `subscription`
--
ALTER TABLE `subscription`
  ADD CONSTRAINT `subscription_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `usermatch`
--
ALTER TABLE `usermatch`
  ADD CONSTRAINT `usermatch_ibfk_1` FOREIGN KEY (`user1_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `usermatch_ibfk_2` FOREIGN KEY (`user2_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `usermatch_ibfk_3` FOREIGN KEY (`skill_id`) REFERENCES `skill` (`skill_id`);

--
-- Constraints for table `userskill`
--
ALTER TABLE `userskill`
  ADD CONSTRAINT `userskill_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `userskill_ibfk_2` FOREIGN KEY (`skill_id`) REFERENCES `skill` (`skill_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
