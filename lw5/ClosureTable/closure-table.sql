SHOW DATABASES;
USE files_ct;

CREATE TABLE directory
(
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE directory_closure
(
    id       BIGINT NOT NULL,
    child_id BIGINT NOT NULL,
    depth    INT    NOT NULL,

    PRIMARY KEY (id, child_id),
    FOREIGN KEY (id) REFERENCES directory (id) ON DELETE CASCADE,
    FOREIGN KEY (child_id) REFERENCES directory (id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

# 0. Создание первой директории
INSERT INTO directory(name)
VALUES ('New Folder 1');
SET @last_id = LAST_INSERT_ID();

INSERT INTO directory_closure (id, child_id, depth)
VALUES (@last_id, @last_id, 0);

# 1. Поддерева целиком
CREATE VIEW directory_subtree AS
SELECT d.name,
       dc.depth,
       dc.id
FROM directory d
         JOIN directory_closure dc ON d.id = dc.child_id;

DROP VIEW directory_subtree;

SELECT name, depth FROM directory_subtree WHERE id = 3;

# 2. Поиска конкретного листа

# 3. Вывода списка родителей
SELECT d.name,
       dc.depth
FROM directory d
         JOIN directory_closure dc ON d.id = dc.id
WHERE dc.child_id = 5
  AND dc.child_id != d.id;

# 4. Вывода списка всех соседних директорий (у которых общий родитель)

# 5. Удаление поддерева

# 6. Вставку 3 элементов в одного родителя
CREATE PROCEDURE AddDirectory(
    IN parent_id BIGINT,
    IN dir_name VARCHAR(255)
)
BEGIN
INSERT INTO directory(name) VALUES (dir_name);
SET @new_dir_id = LAST_INSERT_ID();

INSERT INTO directory_closure (id, child_id, depth)
SELECT id,
       @new_dir_id,
       depth + 1
FROM directory_closure
WHERE child_id = parent_id

UNION ALL

SELECT @new_dir_id, @new_dir_id, 0;
END;

DROP PROCEDURE AddDirectory;

CALL AddDirectory(1, 'New Folder 2');
CALL AddDirectory(1, 'New Folder 3');
CALL AddDirectory(2, 'New Folder 4');
CALL AddDirectory(2, 'New Folder 5');
CALL AddDirectory(3, 'New Folder 6');

# 7. Удаление 2 элементов

# 8. Перемещение элемента в другое поддерево
