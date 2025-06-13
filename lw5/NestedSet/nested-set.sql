show databases;
use files_ns;

CREATE TABLE directory
(
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    lft        INT          NOT NULL,
    rgt        INT          NOT NULL,
    depth      INT          NOT NULL DEFAULT 0,
    created_at TIMESTAMP             DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP             DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

# 0. Создание первой директории
INSERT INTO directory (name, lft, rgt, depth)
VALUES ('New Folder 1', 1, 2, 0);

# 1. Поддерева целиком
SELECT child.name,
       child.lft,
       child.rgt,
       child.depth
FROM directory parent
         JOIN directory child ON child.lft BETWEEN parent.lft AND parent.rgt
WHERE parent.id = 1
ORDER BY child.lft;

# 2. Поиска конкретного листа
SET GLOBAL log_bin_trust_function_creators = 1;

CREATE FUNCTION subtree_size(dir_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci)
    RETURNS INT
    DETERMINISTIC
BEGIN
    DECLARE l INT;
    DECLARE r INT;

    SELECT lft, rgt
    INTO l, r
    FROM directory
    WHERE name = dir_name;

    RETURN r - l - 1;
END;

DROP FUNCTION subtree_size;

SELECT name,
       lft,
       rgt,
       depth
FROM directory
WHERE subtree_size(name) = 0;

# 3. Вывода списка родителей
SELECT parent.name,
       parent.lft,
       parent.rgt,
       parent.depth
FROM directory child
         JOIN directory parent ON child.lft BETWEEN parent.lft AND parent.rgt
WHERE child.id = 5
  AND parent.id != child.id
ORDER BY parent.lft;

# 4. Вывода списка всех соседних директорий (у которых общий родитель)
SELECT child.name,
       child.lft,
       child.rgt,
       child.depth
FROM directory parent
         JOIN directory child ON child.lft BETWEEN parent.lft AND parent.rgt
WHERE parent.id = 1
  AND child.depth = parent.depth + 1
ORDER BY child.lft;

# 5. Удаление поддерева
BEGIN;
DELETE
FROM directory
WHERE lft >= (SELECT lft
              FROM (SELECT lft FROM directory WHERE id = 2) t)
  AND rgt <= (SELECT rgt
              FROM (SELECT rgt FROM directory WHERE id = 2) t);
COMMIT;
ROLLBACK;

# 6. Вставку 3 элементов в одного родителя
CREATE PROCEDURE AddDirectory(
    IN parent_id INT,
    IN dir_name VARCHAR(255)
)
BEGIN
    DECLARE parent_rgt INT;
    DECLARE parent_depth INT;

    START TRANSACTION;

    SELECT rgt, depth
    INTO parent_rgt, parent_depth
    FROM directory
    WHERE id = parent_id
        FOR
    UPDATE;

    UPDATE directory
    SET rgt = rgt + 2
    WHERE rgt >= parent_rgt
    ORDER BY rgt DESC;

    UPDATE directory
    SET lft = lft + 2
    WHERE lft > parent_rgt
    ORDER BY lft DESC;

    INSERT INTO directory (name, lft, rgt, depth)
    VALUES (dir_name, parent_rgt, parent_rgt + 1, parent_depth + 1);
    COMMIT;
END;

DROP PROCEDURE IF EXISTS AddDirectory;


CALL AddDirectory(1, 'New Folder 2');
CALL AddDirectory(1, 'New Folder 3');
CALL AddDirectory(2, 'New Folder 4');
CALL AddDirectory(2, 'New Folder 5');
CALL AddDirectory(3, 'New Folder 6');

# 7. Удаление 2 элементов

CREATE PROCEDURE DeleteDirectory(
    IN dir_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
    DECLARE dir_rgt INT;
    DECLARE dir_lft INT;

    START TRANSACTION;

    SELECT rgt, lft
    INTO dir_rgt, dir_lft
    FROM directory
    WHERE name = dir_name
        FOR
    UPDATE;

    UPDATE directory
    SET rgt   = rgt - 1,
        lft   = lft - 1,
        depth = depth - 1
    WHERE lft > dir_lft
      AND rgt < dir_rgt;

    UPDATE directory
    SET lft = lft - 2
    WHERE lft > dir_rgt;

    UPDATE directory
    SET rgt = rgt - 2
    WHERE rgt > dir_rgt;

    DELETE FROM directory WHERE name = dir_name;
    COMMIT;
END;

DROP PROCEDURE IF EXISTS DeleteDirectory;

BEGIN;

CALL DeleteDirectory('New Folder 3');

ROLLBACK;

# 8. Перемещение элемента в другое поддерево

# Скопировать данные, удалить, вставить на новое место с теми же данными
# Или нужно перемещать поддерево?