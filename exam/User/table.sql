CREATE TABLE user
(
    user_id       BINARY(16)   NOT NULL,
    email         VARCHAR(255) NOT NULL,
    firstname     VARCHAR(255) DEFAULT NULL,
    lastname      VARCHAR(255) DEFAULT NULL,
    name          VARCHAR(255) DEFAULT NULL,
    date_of_birth TIMESTAMP    DEFAULT NULL,
    custom_fields JSON         DEFAULT NULL,
    deleted_at    TIMESTAMP    DEFAULT NULL,
    PRIMARY KEY (user_id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE theme
(
    theme_id    INT UNSIGNED AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    description TEXT         NOT NULL,
    PRIMARY KEY (theme_id),
    UNIQUE KEY (name)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE themed_group
(
    group_id    BINARY(16) NOT NULL,
    name        VARCHAR(100) DEFAULT NULL,
    description TEXT         DEFAULT NULL,
    theme_id    INT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (group_id),
    CONSTRAINT group_theme_fk FOREIGN KEY (theme_id) REFERENCES theme (theme_id) ON DELETE SET NULL
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE subscription
(
    user_id  BINARY(16) NOT NULL,
    group_id BINARY(16) NOT NULL,
    PRIMARY KEY (user_id, group_id),
    CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE news
(
    news_id                 BINARY(16)   NOT NULL,
    group_id                BINARY(16)   NOT NULL,
    title                   VARCHAR(100) NOT NULL,
    is_draft                TINYINT      NOT NULL DEFAULT 1,
    block_id_with_paragraph INT UNSIGNED NOT NULL,
    PRIMARY KEY (news_id),
    CONSTRAINT group_id_fk FOREIGN KEY (group_id) REFERENCES themed_group (group_id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE news_block
(
    block_id     INT UNSIGNED AUTO_INCREMENT,
    order_number INT UNSIGNED NOT NULL,
    news_id      BINARY(16)   NOT NULL,
    PRIMARY KEY (block_id),
    CONSTRAINT news_id_fk FOREIGN KEY (news_id) REFERENCES news (news_id) ON DELETE CASCADE,
    UNIQUE KEY (news_id, order_number)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE paragraph_block
(
    block_id  INT UNSIGNED,
    paragraph TEXT NOT NULL,
    PRIMARY KEY (block_id),
    CONSTRAINT paragraph_block_id_fk FOREIGN KEY (block_id) REFERENCES news_block (block_id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE image_block
(
    block_id  INT UNSIGNED,
    image_src VARCHAR(255) NOT NULL,
    PRIMARY KEY (block_id),
    CONSTRAINT image_block_id_fk FOREIGN KEY (block_id) REFERENCES news_block (block_id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE comment
(
    comment_id INT UNSIGNED AUTO_INCREMENT,
    text       TEXT       NOT NULL,
    news_id    BINARY(16) NOT NULL,
    user_id    BINARY(16) NOT NULL,
    thread_id  INT UNSIGNED DEFAULT NULL,
    deleted_at TIMESTAMP    DEFAULT NULL,
    PRIMARY KEY (comment_id),
    CONSTRAINT news_id_comment_fk FOREIGN KEY (news_id) REFERENCES news (news_id) ON DELETE CASCADE,
    CONSTRAINT user_comment_fk FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE,
    CONSTRAINT thread_comment_fk FOREIGN KEY (thread_id) REFERENCES comment (comment_id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;