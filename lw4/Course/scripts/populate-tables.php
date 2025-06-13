<?php

$dbHost = '127.0.0.1';
$dbName = 'course';
$dbUser = 'root';
$dbPass = 'rootpass';
$dbCharset = 'utf8mb4';

$dsn = "mysql:host=$dbHost;dbname=$dbName;charset=$dbCharset";

$pdoOptions =
    [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

$courseTypes = ['VIDEO', 'AUDIO', 'QUIZ'];
$userStates = ['ACTIVE', 'INACTIVE', 'FIRED'];
$videoFormats = ['MP4', 'MOV', 'MKV'];
$audioFormats = ['MP3', 'WAV', 'AAC'];
$quizStates = ['UPLOADED', 'PROCESSED', 'READY'];
$questionTypes = ['MCQAV', 'SQAV'];

$totalCourses = 100;
$totalUsers = 1000;
$totalUserCourses = 10;
$questionsPerQuiz = 10;
$usersWithEnrollments = 100;
$maxVideosPerCourse = 2;
$maxAudiosPerCourse = 2;

$batchSize = 1000;

function binToUuid(string $bin): string
{
    $hex = bin2hex($bin);
    return substr($hex, 0, 8) . '-' .
        substr($hex, 8, 4) . '-' .
        substr($hex, 12, 4) . '-' .
        substr($hex, 16, 4) . '-' .
        substr($hex, 20);
}

function generateBinUuid(): string
{
    return random_bytes(16);
}

function resetBatchArrays(array &$rowsPlaceholders, array &$batchParams, int &$currentBatchCount): void
{
    $rowsPlaceholders = [];
    $batchParams = [];
    $currentBatchCount = 0;
}

function executeBatch(PDO $pdo, string $tableName, string $columns, array &$rowsPlaceholders, array &$batchParams, int &$currentBatchCount): void
{
    if ($currentBatchCount > 0)
    {
        $sql = "INSERT INTO $tableName ($columns) VALUES " . implode(",", $rowsPlaceholders);
        $stmt = $pdo->prepare($sql);
        try
        {
            $stmt->execute($batchParams);
        }
        catch (PDOException $e)
        {
            echo "Error inserting into $tableName: " . $e->getMessage() . "\n";
            throw $e;
        }
    }
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
}

try
{
    $pdo = new PDO($dsn, $dbUser, $dbPass, $pdoOptions);

    $pdo->beginTransaction();

    $userIds = [];
    $rowsPlaceholders = [];
    $batchParams = [];
    $currentBatchCount = 0;
    echo "Populating table user: ";
    $userColumns = "user_id, name, email, state";
    for ($i = 0; $i < $totalUsers; $i++)
    {
        $userId = generateBinUuid();
        $userIds[] = $userId;
        $userName = rand(0, 1) ? "User " . ($i + 1) : null;
        array_push(
            $batchParams,
            $userId,
            $userName,
            "user$i@example.com",
            $userStates[array_rand($userStates)]
        );
        $rowsPlaceholders[] = "(?, ?, ?, ?)";
        $currentBatchCount++;
        if ($currentBatchCount >= $batchSize)
        {
            executeBatch($pdo, 'user', $userColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
        }
    }
    executeBatch($pdo, 'user', $userColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($userIds) . "\n";

    $courseIds = [];
    $quizCourseIds = [];
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table course: ";
    $courseColumns = "course_id, name, course_type, description";
    for ($i = 0; $i < $totalCourses; $i++)
    {
        $courseId = generateBinUuid();
        $courseIds[] = $courseId;
        $chosenCourseType = $courseTypes[array_rand($courseTypes)];
        if ($chosenCourseType === 'QUIZ')
        {
            $quizCourseIds[] = $courseId;
        }
        array_push(
            $batchParams,
            $courseId,
            "Course " . ($i + 1),
            $chosenCourseType,
            "Description for Course " . ($i + 1)
        );
        $rowsPlaceholders[] = "(?, ?, ?, ?)";
        $currentBatchCount++;
        if ($currentBatchCount >= $batchSize)
        {
            executeBatch($pdo, 'course', $courseColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
        }
    }
    executeBatch($pdo, 'course', $courseColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($courseIds) . "\n";

    $videoIds = [];
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table video: ";
    $videoColumns = "video_id, source_url, duration, format, size, course_id";
    foreach (array_rand(array_flip($courseIds), min(count($courseIds), floor($totalCourses * 0.4))) as $courseId)
    {
        for ($i = 0; $i < rand(1, $maxVideosPerCourse); $i++)
        {
            $videoId = generateBinUuid();
            $videoIds[] = $videoId;
            $videoIdUuid = binToUuid($videoId);
            array_push(
                $batchParams,
                $videoId,
                "https://example.com/video/$videoIdUuid.mp4",
                rand(60, 600),
                $videoFormats[array_rand($videoFormats)],
                rand(100 * 1024, 1000 * 1024),
                $courseId
            );
            $rowsPlaceholders[] = "(?, ?, ?, ?, ?, ?)";
            $currentBatchCount++;
            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'video', $videoColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'video', $videoColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($videoIds) . "\n";

    $audioIds = [];
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table audio: ";
    $audioColumns = "audio_id, source_url, duration, format, size, course_id";
    foreach (array_rand(array_flip($courseIds), min(count($courseIds), floor($totalCourses * 0.3))) as $courseId)
    {
        for ($i = 0; $i < rand(1, $maxAudiosPerCourse); $i++)
        {
            $audioId = generateBinUuid();
            $audioIds[] = $audioId;
            $audioIdUuid = binToUuid($audioId);
            array_push(
                $batchParams,
                $audioId,
                "https://example.com/audio/$audioIdUuid.mp3",
                rand(60, 300),
                $audioFormats[array_rand($audioFormats)],
                rand(50 * 1024, 500 * 1024),
                $courseId
            );
            $rowsPlaceholders[] = "(?, ?, ?, ?, ?, ?)";
            $currentBatchCount++;
            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'audio', $audioColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'audio', $audioColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($audioIds) . "\n";

    $quizIds = [];
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table quiz: ";
    $quizColumns = "quiz_id, source_url, size, available_duration, state";

    foreach ($quizCourseIds as $quizId)
    {
        $quizIds[] = $quizId;
        $quizIdUuid = binToUuid($quizId);
        array_push(
            $batchParams,
            $quizId,
            "https://example.com/quiz/$quizIdUuid.json",
            (string)rand(10, 100),
            rand(1800, 3600),
            $quizStates[array_rand($quizStates)]
        );
        $rowsPlaceholders[] = "(?, ?, ?, ?, ?)";
        $currentBatchCount++;
        if ($currentBatchCount >= $batchSize)
        {
            executeBatch($pdo, 'quiz', $quizColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
        }
    }
    executeBatch($pdo, 'quiz', $quizColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($quizIds) . "\n";

    $enrollmentIds = [];
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table enrollment: ";
    $enrollmentColumns = "enrollment_id, user_id, course_id, start_date, end_date";
    $usersForEnrollment = array_slice($userIds, 0, $usersWithEnrollments);
    foreach ($usersForEnrollment as $userId)
    {
        $coursesToEnroll = array_rand(array_flip($courseIds), min($totalUserCourses, count($courseIds)));
        if (!is_array($coursesToEnroll))
        {
            $coursesToEnroll = [$coursesToEnroll];
        }

        foreach ($coursesToEnroll as $courseId)
        {
            $enrollmentId = generateBinUuid();
            $enrollmentIds[] = $enrollmentId;
            $startDate = date("Y-m-d H:i:s", strtotime("now - " . rand(1, 365) . " days"));
            $endDate = rand(0, 1) ? date("Y-m-d H:i:s", strtotime("$startDate + " . rand(30, 365) . " days")) : null;
            array_push($batchParams, $enrollmentId, $userId, $courseId, $startDate, $endDate);
            $rowsPlaceholders[] = "(?, ?, ?, ?, ?)";
            $currentBatchCount++;
            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'enrollment', $enrollmentColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'enrollment', $enrollmentColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($enrollmentIds) . "\n";

    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table quiz marks: ";
    $quizMarkColumns = "quiz_id, mark, min_score, max_score";

    foreach ($quizIds as $quizId)
    {
        $score = [0, 20, 40, 60, 80, 100];
        for ($i = 0; $i < 5; $i++)
        {
            array_push(
                $batchParams,
                $quizId,
                $i + 1,
                $score[$i],
                $score[$i + 1],
            );
            $rowsPlaceholders[] = "(?, ?, ?, ?)";
            $currentBatchCount++;
        }
        if ($currentBatchCount >= $batchSize)
        {
            executeBatch($pdo, 'quiz_mark', $quizMarkColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
        }
    }
    executeBatch($pdo, 'quiz_mark', $quizMarkColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($courseIds) . "\n";

    $questionIds = [];
    $mcqavQuestionIds = [];
    $sqavQuestionIds = [];
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table quiz_questions: ";
    $quizQuestionColumns = "question_id, text, question_type, picture_url, quiz_id";

    foreach ($quizIds as $quizId)
    {
        for ($i = 0; $i < $questionsPerQuiz; $i++)
        {
            $questionId = generateBinUuid();
            $questionIds[] = $questionId;
            $questionIdUuid = binToUuid($questionId);

            $currentQuestionType = $questionTypes[array_rand($questionTypes)];
            if ($currentQuestionType === 'MCQAV')
            {
                $mcqavQuestionIds[] = $questionId;
            }
            else
            {
                $sqavQuestionIds[] = $questionId;
            }

            array_push(
                $batchParams,
                $questionId,
                "Question " . ($i + 1) . " for Quiz " . binToUuid($quizId) . "?",
                $currentQuestionType,
                rand(0,1) ? "https://example.com/question_img/$questionIdUuid.jpg" : null,
                $quizId
            );
            $rowsPlaceholders[] = "(?, ?, ?, ?, ?)";
            $currentBatchCount++;
            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'quiz_question', $quizQuestionColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'quiz_question', $quizQuestionColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($questionIds) . "\n";

    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table multiple_choice_available_values: ";
    $mcqavColumns = "question_id, answer_option_number, value, is_correct";
    foreach ($mcqavQuestionIds as $questionId)
    {
        $correctAnswer = rand(1, 4);
        for ($i = 1; $i <= 4; $i++)
        {
            array_push(
                $batchParams,
                $questionId,
                $i,
                "Option " . $i,
                ($i === $correctAnswer) ? 1 : 0
            );
            $rowsPlaceholders[] = "(?, ?, ?, ?)";
            $currentBatchCount++;
            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'multiple_choice_question_available_values', $mcqavColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'multiple_choice_question_available_values', $mcqavColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($mcqavQuestionIds) . "\n";

    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table sequence_question_available_values: ";
    $sqavColumns = "question_id, value, value_order";
    foreach ($sqavQuestionIds as $questionId)
    {
        $possibleSequenceValues = ['Option 1', 'Option 2', 'Option 3', 'Option 4', 'Option 5'];
        shuffle($possibleSequenceValues);

        for ($i = 1; $i <= count($possibleSequenceValues); $i++)
        {
            array_push(
                $batchParams,
                $questionId,
                $possibleSequenceValues[$i - 1],
                $i
            );
            $rowsPlaceholders[] = "(?, ?, ?)";
            $currentBatchCount++;
            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'sequence_question_available_values', $sqavColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'sequence_question_available_values', $sqavColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($sqavQuestionIds) . "\n";

    $attemptIds = [];
    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table attempt: ";
    $attemptColumns = "attempt_id, start_date, duration, enrollment_id";

    $stmt = $pdo->query("SELECT enrollment_id FROM enrollment");
    $enrollmentIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

    foreach ($enrollmentIds as $enrollmentId)
    {
        for ($i = 0; $i < rand(1, 2); $i++)
        {
            $attemptId = generateBinUuid();
            $attemptIds[] = $attemptId;
            $startDate = date("Y-m-d H:i:s", strtotime("now - " . rand(1, 30) . " days"));
            $duration = rand(60, 600);
            array_push(
                $batchParams,
                $attemptId,
                $startDate,
                $duration,
                $enrollmentId
            );
            $rowsPlaceholders[] = "(?, ?, ?, ?)";
            $currentBatchCount++;
            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'attempt', $attemptColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'attempt', $attemptColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($attemptIds) . "\n";

    resetBatchArrays($rowsPlaceholders, $batchParams, $currentBatchCount);
    echo "Populating table quiz_attempt_answers: ";
    $qaaColumns = "attempt_id, question_id, answer_value, answer_value_order";

    $stmt = $pdo->query("SELECT question_id, question_type FROM quiz_question");
    $availableQuestionTypes = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);

    foreach ($attemptIds as $attemptId)
    {
        $stmt = $pdo->prepare("
            SELECT q.quiz_id
            FROM attempt a
            JOIN enrollment e ON a.enrollment_id = e.enrollment_id
            JOIN course c ON e.course_id = c.course_id
            JOIN quiz q ON c.course_id = q.quiz_id
            WHERE a.attempt_id = ?
        ");
        $stmt->execute([$attemptId]);
        $attemptQuizId = $stmt->fetchColumn();

        if (!$attemptQuizId)
        {
            continue;
        }

        $stmt = $pdo->prepare("SELECT question_id FROM quiz_question WHERE quiz_id = ?");
        $stmt->execute([$attemptQuizId]);
        $questionIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

        foreach ($questionIds as $questionId)
        {
            $questionType = $availableQuestionTypes[$questionId] ?? null;

            if ($questionType === null)
            {
                continue;
            }

            if ($questionType === 'SQAV')
            {
                $possibleAnswers = ['Option 1', 'Option 2', 'Option 3', 'Option 4', 'Option 5'];
                shuffle($possibleAnswers);

                for ($i = 1; $i < count($possibleAnswers) + 1; $i++)
                {
                    $rowsPlaceholders[] = "(?, ?, ?, ?)";
                    $answer = $possibleAnswers[$i - 1];
                    array_push(
                        $batchParams,
                        $attemptId,
                        $questionId,
                        $answer,
                        $i
                    );
                    $currentBatchCount++;
                }
            }
            else
            {
                $rowsPlaceholders[] = "(?, ?, ?, ?)";
                array_push(
                    $batchParams,
                    $attemptId,
                    $questionId,
                    'Option ' . rand(1, 500),
                    0
                );
                $currentBatchCount++;
            }

            if ($currentBatchCount >= $batchSize)
            {
                executeBatch($pdo, 'quiz_attempt_answer', $qaaColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
            }
        }
    }
    executeBatch($pdo, 'quiz_attempt_answer', $qaaColumns, $rowsPlaceholders, $batchParams, $currentBatchCount);
    echo count($questionIds) . "\n";

    $pdo->commit();

    echo "All tables populated successfully\n";

}
catch (PDOException $e)
{
    echo "\nDatabase Error: " . $e->getMessage() . "\n";
}