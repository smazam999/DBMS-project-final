# SQL Database Procedures, Views, and Triggers

This repository contains SQL scripts for procedures, views, and triggers used in a database system. Below is the detailed description of each component.

## 1. Procedure to Register a New User
```sql
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `register_user`(
    IN name VARCHAR(100),
    IN email VARCHAR(100),
    IN password VARCHAR(255),
    IN location VARCHAR(100),
    IN profile_picture VARCHAR(255),
    IN bio TEXT,
    IN verified_status TINYINT(1),
    IN tokens INT,
    IN event_count INT,
    IN status VARCHAR(20)
)
BEGIN
    INSERT INTO `user` (
        `name`, `email`, `password`, `location`, `profile_picture`, 
        `bio`, `verified_status`, `tokens`, `event_count`, `status`
    )
    VALUES (
        name, email, password, location, profile_picture, 
        bio, verified_status, tokens, event_count, status
    );
END; //
DELIMITER ;

CALL register_user(
    'Sara', 
    'sara@example.com', 
    'hashedpassword456', 
    NULL, 
    NULL, 
    NULL, 
    0, 
    0, 
    NULL, 
    'Inactive'
);
```

## 2. Procedure to Deactivate Inactive Users
```sql
DELIMITER //
CREATE PROCEDURE deactivate_inactive_users()
BEGIN
    UPDATE user
    SET status = 'Inactive'
    WHERE last_login < DATE_SUB(NOW(), INTERVAL 1 YEAR);
END;//
DELIMITER ;
```

## 3. View for Active Users
```sql
CREATE VIEW active_users AS SELECT user_id, name, email FROM users WHERE status = 'Active';
```

## 4. Query to Get All Active Users
```sql
SELECT * FROM active_users;
```

## 5. Procedure to Get Attendance Report
```sql
DELIMITER //
CREATE PROCEDURE get_attendance_report(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    SELECT a.attendance_id, a.event_id, a.user_id, a.status, e.title
    FROM attendance a
    JOIN event e ON a.event_id = e.event_id
    WHERE e.start_time BETWEEN start_date AND end_date;
END;//
DELIMITER ;

CALL get_attendance_report('2024-12-01', '2024-12-04');
```

## 6. View for Events with Attendee Count
```sql
CREATE VIEW event_attendee_count AS
SELECT e.event_id, e.title, COUNT(a.attendance_id) AS attendee_count
FROM event e
LEFT JOIN attendance a ON e.event_id = a.event_id
GROUP BY e.event_id, e.title;
```

## 7. Trigger for Token Purchase
```sql
DELIMITER //
CREATE TRIGGER after_token_purchase
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'Purchase' THEN
        UPDATE `user`
        SET tokens = tokens + NEW.tokens
        WHERE user_id = NEW.user_id;
    END IF;
END;//
DELIMITER ;

INSERT INTO transactions (user_id, transaction_type, tokens, amount)
VALUES (1, 'Purchase', 50, 500.00);
```

## 8. Trigger to Log Token Deductions
```sql
DELIMITER //
CREATE TRIGGER after_course_purchase
AFTER INSERT ON course_purchases
FOR EACH ROW
BEGIN
    IF (SELECT tokens FROM `user` WHERE user_id = NEW.user_id) >= NEW.tokens_required THEN
        UPDATE `user`
        SET tokens = tokens - NEW.tokens_required
        WHERE user_id = NEW.user_id;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient tokens for course purchase.';
    END IF;
END;//
DELIMITER ;

INSERT INTO course_purchases (user_id, course_id, tokens_required)
VALUES (1, 5, 30);
```

## 9. User Token Balance View
```sql
CREATE VIEW user_token_balance AS
SELECT u.user_id, u.name, u.tokens, t.transaction_type, t.tokens AS token_change, t.amount, t.transaction_date
FROM user u
LEFT JOIN transactions t ON u.user_id = t.user_id
ORDER BY t.transaction_date DESC;
```

## 10. View for Course Earnings
```sql
CREATE VIEW course_earnings AS
SELECT c.course_name, c.tokens_earned, u.name AS uploader, c.upload_date
FROM courses c
JOIN user u ON c.user_id = u.user_id;
```

## 11. Procedure to Buy Tokens
```sql
DELIMITER //
CREATE PROCEDURE buy_tokens(IN userId INT, IN tokenCount INT, IN amountPaid DECIMAL(10, 2))
BEGIN
    UPDATE user
    SET tokens = tokens + tokenCount
    WHERE user_id = userId;

    INSERT INTO transactions (user_id, transaction_type, tokens, amount)
    VALUES (userId, 'Purchase', tokenCount, amountPaid);
END//
DELIMITER ;

CALL buy_tokens(1, 50, 500.00);
```

## 12. Procedure to Upload a Course
```sql
DELIMITER //
CREATE PROCEDURE upload_course(IN userId INT, IN courseName VARCHAR(255), IN courseDesc TEXT, IN tokenReward INT)
BEGIN
    INSERT INTO courses (user_id, course_name, course_description, tokens_earned)
    VALUES (userId, courseName, courseDesc, tokenReward);

    UPDATE users
    SET tokens = tokens + tokenReward
    WHERE user_id = userId;

    INSERT INTO transactions (user_id, transaction_type, tokens)
    VALUES (userId, 'Earned', tokenReward);
END //
DELIMITER ;
```

## 13. Procedure to Access a Course
```sql
DELIMITER //
CREATE PROCEDURE access_course(IN userId INT, IN tokensRequired INT)
BEGIN
    UPDATE users
    SET tokens = tokens - tokensRequired
    WHERE user_id = userId;

    INSERT INTO transactions (user_id, transaction_type, tokens)
    VALUES (userId, 'Deducted', -tokensRequired);
END //
DELIMITER ;
```

## 14. Procedure to Find Courses by Title
```sql
DELIMITER //
CREATE PROCEDURE find_courses_by_title(
    IN search_title VARCHAR(255)
)
BEGIN
    SELECT course_id, course_name, course_description, tokens_earned, upload_date, user_id
    FROM courses
    WHERE course_name LIKE CONCAT('%', search_title, '%')
    ORDER BY course_name;
END;//
DELIMITER ;

CALL find_courses_by_title('Python');
```

## 15. Procedure to Send Messages
```sql
DELIMITER //
CREATE PROCEDURE send_message(
    IN sender INT,
    IN receiver INT,
    IN message TEXT
)
BEGIN
    INSERT INTO messages (sender_id, receiver_id, message_text)
    VALUES (sender, receiver, message);
END;//
DELIMITER ;

CALL send_message(1, 2, 'Hello, how are you?');
CALL send_message(3, 5, 'Don’t forget to check the new course!');
```

## 16. Message View
```sql
CREATE VIEW message_view AS
SELECT 
    m.message_id,
    m.sender_id,
    s.name AS sender_name,
    m.receiver_id,
    r.name AS receiver_name,
    m.message_text,
    m.sent_at,
    m.is_read
FROM 
    messages m
JOIN 
    user s ON m.sender_id = s.user_id
JOIN 
    user r ON m.receiver_id = r.user_id
ORDER BY 
    m.sent_at DESC;
```

## 17. Procedure to Read Messages
```sql
DELIMITER //
CREATE PROCEDURE read_messages(
    IN receiver_id INT
)
BEGIN
    UPDATE messages
    SET is_read = 1
    WHERE receiver_id = receiver_id AND is_read = 0;

    SELECT message_id, sender_id, receiver_id, message_text, sent_at, is_read
    FROM messages
    WHERE receiver_id = receiver_id
    ORDER BY sent_at DESC;
END;//
DELIMITER ;

CALL read_messages(2);
```
