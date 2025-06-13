CREATE DATABASE course;
USE course;

#1.1
CREATE TABLE course
(
    course_id   BINARY(16)                      NOT NULL,
    name        VARCHAR(255)                    NOT NULL,
    course_type ENUM ('VIDEO', 'AUDIO', 'QUIZ') NOT NULL DEFAULT 'QUIZ',
    description TEXT                                     DEFAULT NULL,
    deleted_at  TIMESTAMP                                DEFAULT NULL,
    PRIMARY KEY (course_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE video
(
    video_id   BINARY(16)                 NOT NULL,
    source_url VARCHAR(255)               NOT NULL,
    duration   INT                        NOT NULL DEFAULT 0,
    format     ENUM ('MP4', 'MOV', 'MKV') NOT NULL DEFAULT 'MP4',
    size       INT                        NOT NULL DEFAULT 0,
    course_id  BINARY(16)                 NOT NULL,
    CONSTRAINT video_course_fk FOREIGN KEY (course_id) REFERENCES course (course_id) ON DELETE CASCADE,
    PRIMARY KEY (video_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE audio
(
    audio_id   BINARY(16)                 NOT NULL,
    source_url VARCHAR(255)               NOT NULL,
    duration   INT                        NOT NULL DEFAULT 0,
    format     ENUM ('MP3', 'WAV', 'AAC') NOT NULL DEFAULT 'MP3',
    size       INT                        NOT NULL DEFAULT 0,
    course_id  BINARY(16)                 NOT NULL,
    CONSTRAINT audio_course_fk FOREIGN KEY (course_id) REFERENCES course (course_id) ON DELETE CASCADE,
    PRIMARY KEY (audio_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE quiz
(
    quiz_id            BINARY(16)                              NOT NULL,
    source_url         VARCHAR(255)                            NOT NULL,
    size               VARCHAR(100)                            NOT NULL,
    available_duration INT                                     NOT NULL DEFAULT 0,
    state              ENUM ('UPLOADED', 'PROCESSED', 'READY') NOT NULL DEFAULT 'PROCESSED',
    CONSTRAINT quiz_course_fk FOREIGN KEY (quiz_id) REFERENCES course (course_id) ON DELETE CASCADE,
    PRIMARY KEY (quiz_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE user
(
    user_id    BINARY(16)                           NOT NULL,
    name       VARCHAR(100)                                  DEFAULT NULL,
    email      VARCHAR(255)                         NOT NULL,
    state      ENUM ('ACTIVE', 'INACTIVE', 'FIRED') NOT NULL DEFAULT 'INACTIVE',
    deleted_at TIMESTAMP                                     DEFAULT NULL,
    PRIMARY KEY (user_id),
    UNIQUE KEY (email)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE quiz_mark
(
    quiz_id   BINARY(16) NOT NULL,
    mark      INT        NOT NULL DEFAULT 0,
    min_score INT        NOT NULL DEFAULT 0,
    max_score INT        NOT NULL DEFAULT 0,
    CONSTRAINT quiz_mark_fk FOREIGN KEY (quiz_id) REFERENCES quiz (quiz_id) ON DELETE CASCADE,
    PRIMARY KEY (quiz_id, mark)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE quiz_question
(
    question_id   BINARY(16)             NOT NULL,
    text          TEXT                   NOT NULL,
    question_type ENUM ('MCQAV', 'SQAV') NOT NULL DEFAULT 'MCQAV',
    picture_url   VARCHAR(255)                    DEFAULT NULL,
    quiz_id       BINARY(16)             NOT NULL,
    CONSTRAINT quiz_question_fk FOREIGN KEY (quiz_id) REFERENCES quiz (quiz_id) ON DELETE CASCADE,
    PRIMARY KEY (question_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE multiple_choice_question_available_values
(
    question_id          BINARY(16)   NOT NULL,
    answer_option_number INT UNSIGNED NOT NULL DEFAULT 1,
    value                VARCHAR(100) NOT NULL DEFAULT '',
    is_correct           TINYINT(1)            DEFAULT 0,
    CONSTRAINT question_fk FOREIGN KEY (question_id) REFERENCES quiz_question (question_id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, answer_option_number)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE sequence_question_available_values
(
    question_id BINARY(16)   NOT NULL,
    value       VARCHAR(100) NOT NULL DEFAULT '',
    value_order INT UNSIGNED          DEFAULT 1,
    CONSTRAINT sequence_question_fk FOREIGN KEY (question_id) REFERENCES quiz_question (question_id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, value_order)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE enrollment
(
    enrollment_id BINARY(16) NOT NULL,
    user_id       BINARY(16) NOT NULL,
    course_id     BINARY(16) NOT NULL,
    start_date    TIMESTAMP DEFAULT NULL,
    end_date      TIMESTAMP DEFAULT NULL,
    CONSTRAINT user_fk FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE,
    CONSTRAINT course_fk FOREIGN KEY (course_id) REFERENCES course (course_id) ON DELETE CASCADE,
    PRIMARY KEY (enrollment_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE attempt
(
    attempt_id    BINARY(16) NOT NULL,
    start_date    TIMESTAMP  NOT NULL,
    duration      INT DEFAULT NULL,
    enrollment_id BINARY(16) NOT NULL,
    CONSTRAINT enrollment_attempt_fk FOREIGN KEY (enrollment_id) REFERENCES enrollment (enrollment_id) ON DELETE CASCADE,
    PRIMARY KEY (attempt_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE quiz_attempt_answer
(
    attempt_id         BINARY(16)   NOT NULL,
    question_id        BINARY(16)   NOT NULL,
    answer_value       VARCHAR(100)          DEFAULT NULL,
    answer_value_order INT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT attempt_fk FOREIGN KEY (attempt_id) REFERENCES attempt (attempt_id) ON DELETE CASCADE,
    CONSTRAINT question_id_fk FOREIGN KEY (question_id) REFERENCES quiz_question (question_id) ON DELETE CASCADE,
    PRIMARY KEY (attempt_id, question_id, answer_value_order)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;